#
#  Makefile -- an inert, API-compatible Sparkle.framework (universal by default)
#              for Telegram for macOS.
#
#  make              build build/Sparkle.framework
#  make test         runtime smoke test against the built framework
#  make apidiff      diff stub vs. the installed Sparkle (classes, selectors,
#                    type encodings, protocol conformances)
#  make check        verify every Sparkle symbol Telegram imports is exported
#  make test-install  exercise install/restore/the gate on a throw-away app copy
#  make status       what is installed in the host app right now (stub/original)
#  make install      put the stub in, moving the original to Sparkle.framework.orig
#  make restore      move Sparkle.framework.orig back
#  make tree         show the produced layout
#  make clean        remove build/ (leaves the .orig backup alone)
#
#  SIGNING IS NOT DONE HERE. Replacing nested code invalidates the host app's
#  signature, and how (or whether) to re-sign is a decision for the operator:
#  see README.md, "Signing", and tools/library_validation_test.sh, which measures
#  what dyld accepts.
#
#  Knobs
#    ARCH        target architecture(s)         (default: x86_64 arm64 = universal)
#    NATIVE_ARCH arch the helper tools/tests are built for (default: uname -m)
#    MIN_MACOS   deployment target              (default: 11.0, as the original)
#    TG          host app to work against       (default: /Applications/Telegram.app)
#    HEADERS     1 = ship Sources/*.h in Versions/A/Headers      (default: 0)
#    INFOPLIST   1 = ship Versions/A/Resources/Info.plist        (default: 0)
#    FORCE       1 = let install overwrite an existing .orig backup
#    SKIP_CHECK  1 = install without running the verification gate (see below)
#
#  The tree is the dylib and two symlinks. INFOPLIST=1 adds
#  Versions/A/Resources/Info.plist, which codesign requires if the host app is
#  re-signed; HEADERS=1 adds Versions/A/Headers:
#
#      Sparkle.framework/Sparkle            -> Versions/Current/Sparkle
#      Sparkle.framework/Versions/Current   -> A
#      Sparkle.framework/Versions/A/Sparkle    (the dylib)


FRAMEWORK        := Sparkle
VERSION_DIR      := A
FRAMEWORK_ID     := org.sparkle-project.Sparkle

# Mach-O versions must satisfy the LC_LOAD_DYLIB of the host binary:
#   @rpath/Sparkle.framework/Versions/A/Sparkle (compat 1.6.0, current 1.21.0, weak)
CURRENT_VERSION  := 1.21.0
COMPAT_VERSION   := 1.6.0

ARCH             ?= x86_64 arm64
NATIVE_ARCH      ?= $(shell uname -m)
MIN_MACOS        ?= 11.0
TG               ?= /Applications/Telegram.app
HEADERS          ?= 0
INFOPLIST        ?= 0
FORCE            ?= 0

BUILD            := build
FW               := $(BUILD)/$(FRAMEWORK).framework
VERS             := $(FW)/Versions/$(VERSION_DIR)
VERS_PARENT      := $(FW)/Versions
DYLIB            := $(VERS)/$(FRAMEWORK)
OBJDIR           := $(BUILD)/obj

INSTALL_NAME     := @rpath/$(FRAMEWORK).framework/Versions/$(VERSION_DIR)/$(FRAMEWORK)

SRCS             := $(sort $(wildcard Sources/*.m) $(wildcard Sources/*.c))
OBJS             := $(addprefix $(OBJDIR)/,$(addsuffix .o,$(basename $(notdir $(SRCS)))))
PUBLIC_HEADERS   := $(sort $(filter-out Sources/SparkleStubInternal.h,$(wildcard Sources/*.h)))

REAL_FRAMEWORK   := $(TG)/Contents/Frameworks/$(FRAMEWORK).framework
# The pristine original lives next to the framework, as Sparkle.framework.orig.
ORIG             := $(REAL_FRAMEWORK).orig
# Verification uses the pristine original as its reference when one exists.
REF_FRAMEWORK    := $(if $(wildcard $(ORIG)),$(ORIG),$(REAL_FRAMEWORK))
REF_DYLIB        := $(REF_FRAMEWORK)/Versions/$(VERSION_DIR)/$(FRAMEWORK)
# The host's own executable, read from its Info.plist, so TG= works for any app.
EXE_NAME         := $(shell plutil -extract CFBundleExecutable raw -o - "$(TG)/Contents/Info.plist" 2>/dev/null)
REAL_BINARY      := $(TG)/Contents/MacOS/$(if $(EXE_NAME),$(EXE_NAME),$(FRAMEWORK))

CC               := xcrun clang
# One -arch per word: clang/lld emit a fat (universal) object and dylib.
ARCHFLAGS        := $(foreach a,$(ARCH),-arch $(a)) -mmacosx-version-min=$(MIN_MACOS)
# Host tools and the smoke test run locally, so they are built thin.
TOOLARCHFLAGS    := -arch $(NATIVE_ARCH) -mmacosx-version-min=$(MIN_MACOS)
CFLAGS           := $(ARCHFLAGS) -fobjc-arc -fobjc-arc-exceptions \
                    -O2 -g -Wall -Wextra -Wno-unused-parameter -I Sources
LDFLAGS          := $(ARCHFLAGS) -dynamiclib \
                    -install_name '$(INSTALL_NAME)' \
                    -compatibility_version $(COMPAT_VERSION) \
                    -current_version $(CURRENT_VERSION) \
                    -framework Foundation

.PHONY: all dylib bundle test test-install apidiff check status install restore tree clean help

all: bundle

help:
	@grep -E '^#  ' Makefile | sed 's/^#  //'

# ---------------------------------------------------------------------------
# compile + link
# ---------------------------------------------------------------------------

$(OBJDIR)/%.o: Sources/%.m $(wildcard Sources/*.h)
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR)/%.o: Sources/%.c $(wildcard Sources/*.h)
	@mkdir -p $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

dylib: $(BUILD)/$(FRAMEWORK)

$(BUILD)/$(FRAMEWORK): $(OBJS)
	@mkdir -p $(BUILD)
	$(CC) $(LDFLAGS) $(OBJS) -o $@
	@printf '\n  built %s\n  ' '$@'
	@lipo -info $@
	@otool -D $@ | grep -v ':$$' | sed 's/^/    /'
	@otool -l $@ | grep -A6 LC_ID_DYLIB | grep 'version' | sort -u | sed 's/^ */    /'
	@vtool -show-build $@ | grep minos | sort -u | sed 's/^ */    /'

# ---------------------------------------------------------------------------
# framework bundle: the dylib plus the version symlinks
# ---------------------------------------------------------------------------

EXTRA_BUNDLE     :=
ifeq ($(HEADERS),1)
EXTRA_BUNDLE     += $(VERS)/Headers $(FW)/Headers
$(VERS)/Headers: $(PUBLIC_HEADERS)
	@mkdir -p $@
	cp -f $(PUBLIC_HEADERS) $@/
$(FW)/Headers:
	@mkdir -p $(VERS_PARENT)
	ln -sfn Versions/Current/Headers $@
endif
ifeq ($(INFOPLIST),1)
EXTRA_BUNDLE     += $(VERS)/Resources/Info.plist $(FW)/Resources
$(VERS)/Resources/Info.plist: Info.plist
	@mkdir -p $(@D)
	cp -f Info.plist $@
	plutil -lint $@
$(FW)/Resources:
	@mkdir -p $(VERS_PARENT)
	ln -sfn Versions/Current/Resources $@
endif

bundle: $(DYLIB) $(FW)/Sparkle $(VERS_PARENT)/Current $(EXTRA_BUNDLE)
	@printf '\n  %s\n' '$(FW)'

$(DYLIB): $(BUILD)/$(FRAMEWORK)
	@mkdir -p $(VERS)
	cp -f $(BUILD)/$(FRAMEWORK) $@

$(FW)/Sparkle:
	@mkdir -p $(VERS_PARENT)
	ln -sfn Versions/Current/$(FRAMEWORK) $@

$(VERS_PARENT)/Current:
	@mkdir -p $(VERS_PARENT)
	ln -sfn $(VERSION_DIR) $@

tree: bundle
	@find $(FW) | sort | sed 's|$(BUILD)/||'

# ---------------------------------------------------------------------------
# verification
# ---------------------------------------------------------------------------

TESTBIN := $(BUILD)/smoke_test

# Links against the built framework through @rpath, so the bundle layout and the
# install name are exercised as well.
$(TESTBIN): tools/smoke_test.m $(wildcard Sources/*.h) bundle
	@mkdir -p $(BUILD)
	$(CC) $(TOOLARCHFLAGS) -fobjc-arc -Wall -Wextra -Wno-unused-parameter -I Sources \
		-F $(BUILD) -framework $(FRAMEWORK) -Wl,-rpath,$(CURDIR)/$(BUILD) $< -o $@

test: $(TESTBIN)
	@printf '\n'
	$(TESTBIN)

# install/restore/verification-gate, exercised against a copy of the installed
# framework in a temp dir, not against $(TG) itself. The reference is the .orig
# once the stub is installed in the app.
test-install: bundle
	@./tools/fake_app_test.sh "$(REF_FRAMEWORK)"

APIDIFF := $(BUILD)/apidiff

$(APIDIFF): tools/apidiff.m
	@mkdir -p $(BUILD)
	$(CC) $(TOOLARCHFLAGS) -fobjc-arc -Wall -framework Foundation $< -o $@

# Classes, selectors, type encodings and protocol conformances of the stub
# against the framework installed in the host app. A class the stub does not
# implement is a note; a missing selector, a wrong type encoding or a missing
# conformance on a stubbed class is an error.
apidiff: $(APIDIFF) bundle
	@if [ ! -f "$(REF_DYLIB)" ]; then \
	  echo "error: $(REF_DYLIB) not found (set TG=/path/to/Some.app)"; exit 2; \
	fi
	@printf '\n  reference: $(REF_FRAMEWORK)\n'
	$(APIDIFF) dump "$(REF_DYLIB)" > $(BUILD)/real.api.txt
	$(APIDIFF) dump "$(DYLIB)"      > $(BUILD)/stub.api.txt
	@printf '\n--- API: installed Sparkle -> stub ---\n'
	$(APIDIFF) diff $(BUILD)/real.api.txt $(BUILD)/stub.api.txt

# The stub must export every Sparkle symbol the host imports.
check: $(DYLIB)
	@printf '\n'
	@./tools/check_symbols.sh "$(REAL_BINARY)" "$(REF_DYLIB)" "$(DYLIB)"

# ---------------------------------------------------------------------------
# install into the host app / restore the original -- files only, no signing
# ---------------------------------------------------------------------------

# install moves the original aside, so there is one copy, kept next to the
# framework and out of reach of 'make clean'.
#
# The gate runs before the swap, against the framework that is installed. An
# unsigned install does not load the stub, so a mismatch produces no runtime
# symptom; the gate is where it shows up.
install: bundle
	@if [ ! -d "$(REAL_FRAMEWORK)" ]; then \
	  echo "error: $(REAL_FRAMEWORK) not found"; exit 2; \
	fi
	@if [ "$(SKIP_CHECK)" != "1" ]; then \
	  printf '\n  verification gate (make check apidiff)\n'; \
	  $(MAKE) --no-print-directory check apidiff || { \
	    printf '\nerror: verification failed -- refusing to install.\n'; \
	    printf '       The stub does not match the Sparkle that is installed here.\n'; \
	    printf '       (SKIP_CHECK=1 installs anyway, at your own risk.)\n'; exit 1; }; \
	fi
	@if pgrep -x $(notdir $(basename $(TG))) >/dev/null; then \
	  echo "error: $(notdir $(basename $(TG))) is running -- quit it first"; exit 1; \
	fi
	@if [ -e "$(ORIG)" ] && [ "$(FORCE)" != "1" ]; then \
	  echo "error: $(ORIG) already exists."; \
	  echo "       It is the only pristine copy. Move it somewhere safe, or use"; \
	  echo "       FORCE=1 to replace it (destroys it)."; exit 1; \
	fi
	@[ ! -e "$(ORIG)" ] || rm -rf "$(ORIG)"
	mv "$(REAL_FRAMEWORK)" "$(ORIG)"
	@printf '  original -> $(ORIG)\n'
	cp -a "$(FW)" "$(REAL_FRAMEWORK)"
	chmod -R go-w "$(REAL_FRAMEWORK)"
	@printf '  stub     -> $(REAL_FRAMEWORK)\n'
	@printf '\n  Files only: nothing was signed. The app signature is now invalid.\n'
	@printf '  Decide what to do about that yourself -- see README.md "Signing".\n'
	@$(MAKE) --no-print-directory status

restore:
	@if [ ! -d "$(ORIG)" ]; then \
	  echo "error: no original at $(ORIG)"; exit 2; \
	fi
	@if pgrep -x $(notdir $(basename $(TG))) >/dev/null; then \
	  echo "error: $(notdir $(basename $(TG))) is running -- quit it first"; exit 1; \
	fi
	rm -rf "$(REAL_FRAMEWORK)"
	mv "$(ORIG)" "$(REAL_FRAMEWORK)"
	@printf '  restored: $(REAL_FRAMEWORK)\n'
	@$(MAKE) --no-print-directory status

# Is the framework in the host app the stub or the real thing?
status:
	@./tools/framework_status.sh "$(REAL_FRAMEWORK)" "$(ORIG)" "$(REF_FRAMEWORK)" || true

clean:
	rm -rf $(BUILD)
