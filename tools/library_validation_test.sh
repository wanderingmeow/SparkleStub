#!/bin/sh
#
#  library_validation_test.sh -- measure what dyld/AMFI accepts.
#
#  Telegram is signed with the hardened runtime (flags=0x10000) and has no
#  com.apple.security.cs.disable-library-validation entitlement, so the question
#  is whether a replacement framework with a signature we can produce still
#  binds. Case 6 answers it with a host that carries a real Team ID; cases 1 to 5
#  cover ad-hoc hosts. Nothing here touches /Applications.
#
#  What dyld does on a machine with a different AMFI/SIP state can differ. The
#  result that matters is the one you measure on the machine you install on:
#  run the host with SPARKLE_STUB_LOG=1. If nothing is printed, dyld skipped the
#  image; because the Sparkle link is weak, the app still launches, and updates
#  are blocked by absence rather than by the stub.
#
#  usage: tools/library_validation_test.sh
#

set -u

ROOT=$(mktemp -d)
REPO=$(cd "$(dirname "$0")/.." && pwd)
STUB="$ROOT/stub"
APP="$ROOT/LVTest.app"
BIN="$APP/Contents/MacOS/LVTest"
ENT="$ROOT/lv.entitlements"
ARCH=$(uname -m)
KEEP=${KEEP:-}
trap 'if [ -z "$KEEP" ]; then rm -rf "$ROOT"; fi' EXIT

[ -z "$KEEP" ] || printf '  (keeping %s for inspection)\n' "$ROOT"

# --- build the stub with an Info.plist --------------------------------------
# Nested code without an Info.plist is "bundle format unrecognized" to codesign,
# which then refuses to sign the host app at all -- so a stub that must be
# re-signed inside an app bundle needs a bundle Info.plist.
printf '  building the stub (INFOPLIST=1) ... '
make -s -C "$REPO" BUILD="$STUB" INFOPLIST=1 >/dev/null || { echo "make failed"; exit 1; }
echo "$STUB/Sparkle.framework"
SRC_FW="$STUB/Sparkle.framework"
FW_PARENT="$STUB"

cat > "$ENT" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
	<key>com.apple.security.cs.disable-library-validation</key><true/>
</dict></plist>
EOF

mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks"
cat > "$ROOT/main.m" <<'EOF'
#import <Foundation/Foundation.h>
#import <objc/runtime.h>

// Declared weak_import, mirroring Telegram's LC_LOAD_WEAK_DYLIB.
__attribute__((weak_import)) @interface SUUpdater : NSObject
+ (id)sharedUpdater;
- (BOOL)automaticallyChecksForUpdates;
@end

int main(void)
{
	Class cls = objc_getClass("SUUpdater");
	if (cls == nil) {
		printf("    Sparkle NOT bound (class symbol is nil)\n");
		return 0;
	}
	SUUpdater *u = [SUUpdater performSelector:@selector(sharedUpdater)];
	printf("    Sparkle bound; automaticallyChecksForUpdates=%d\n",
		   (int)[u automaticallyChecksForUpdates]);
	return 0;
}
EOF

build_host() { # $1 = "-weak_framework" | "-framework"
	clang -arch "$ARCH" -fobjc-arc -framework Foundation \
		-F "$FW_PARENT" -Wl,-rpath,'@executable_path/../Frameworks' \
		"$1" Sparkle -o "$BIN" "$ROOT/main.m" || exit 1
}

sign_fw() {
	codesign --remove-signature "$DYL" 2>/dev/null
	codesign --force --sign - --identifier org.sparkle-project.Sparkle \
		--options runtime --timestamp=none "$DYL" || { echo "    (framework signing failed)"; return 1; }
}

sign_app() {
	codesign --force --timestamp=none "$@" "$APP" \
		|| { echo "    (app signing FAILED: see above)"; return 1; }
}

# codesign refuses to sign a host whose nested framework has no Info.plist, so
# the harness gives the test copy one. The stub ships without it; this exists so
# every case below can re-sign the host app.
make_signable() {
	mkdir -p "$1/Versions/A/Resources"
	cat > "$1/Versions/A/Resources/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleExecutable</key><string>Sparkle</string>
<key>CFBundleIdentifier</key><string>org.sparkle-project.Sparkle</string>
<key>CFBundlePackageType</key><string>FMWK</string>
<key>CFBundleShortVersionString</key><string>1.21.0</string>
<key>CFBundleVersion</key><string>1.21.0</string>
</dict></plist>
PLIST
	ln -sfn Versions/Current/Resources "$1/Resources" 2>/dev/null
}

run_case() {
	name=$1; shift
	printf '\n  [%s]\n' "$name"
	rm -rf "$APP/Contents/Frameworks/Sparkle.framework"
	cp -a "$SRC_FW" "$APP/Contents/Frameworks/"
	make_signable "$APP/Contents/Frameworks/Sparkle.framework"
	DYL="$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle"
	eval "$@"
	printf '    app signature: %s\n' \
		"$(codesign -dvv "$APP" 2>&1 | grep -E '^CodeDirectory' | sed 's/.*flags=//;s/ .*//')"
	out=$("$BIN" 2>&1); rc=$?
	if [ $rc -eq 0 ]; then printf '    -> launched\n'; else printf '    -> exit %d\n' $rc; fi
	printf '%s\n' "$out" | grep -vE '^\s*$' | sed 's/^/       /' | head -5
}

build_host -weak_framework

printf '\n=== dyld/AMFI acceptance matrix (host + framework signed ad-hoc) ===\n'

run_case "1. app NOT hardened (no LV), framework ad-hoc signed" \
	'sign_fw && sign_app --sign -'

run_case "2. app hardened (LV on), framework ad-hoc signed" \
	'sign_fw && sign_app --sign - --options runtime'

run_case "3. app hardened + disable-library-validation, framework ad-hoc signed" \
	'sign_fw && sign_app --sign - --options runtime --entitlements "$ENT"'

run_case "4. app hardened (LV on), framework UNSIGNED" \
	'sign_fw && sign_app --sign - --options runtime; codesign --remove-signature "$DYL" 2>/dev/null'

run_case "5. app hardened (LV on), framework ad-hoc, STRONG link" \
	'build_host -framework; sign_fw && sign_app --sign - --options runtime'

build_host -weak_framework

# The Telegram situation: a host with a real Team ID, hardened, framework signed
# by the linker only (adhoc,linker-signed, no Team ID). Needs a signing identity
# in the keychain; skipped otherwise.
IDENTITY=$(security find-identity -v -p codesigning 2>/dev/null \
	| awk '/Apple Development|Developer ID Application/ {print $2; exit}')
if [ -n "$IDENTITY" ]; then
	printf '  signing identity: %s\n' "$IDENTITY"
	run_case "6. app signed with a REAL identity (Team ID) + hardened, framework ad-hoc" \
		'sign_fw && sign_app --sign "$IDENTITY" --options runtime'
	printf '    host team id: %s\n' \
		"$(codesign -dvvv "$APP" 2>&1 | grep '^TeamIdentifier' | cut -d= -f2)"

	# This is what `make install` does: the host keeps the signature it was
	# shipped with, the framework underneath it is replaced and never signed.
	# The copy here has no Info.plist either, same as the installed stub.
	run_case "7. host signed + hardened, framework REPLACED afterwards, host not re-signed" \
		'sign_fw && sign_app --sign "$IDENTITY" --options runtime; rm -rf "$APP/Contents/Frameworks/Sparkle.framework"; cp -a "$SRC_FW" "$APP/Contents/Frameworks/"'
else
	printf '\n  [6] skipped: no signing identity in the keychain\n'
fi

printf '\n  Read the result against the machine you are on: SIP and AMFI state change\n'
printf '  what dyld enforces. The install-side check is SPARKLE_STUB_LOG=1 on the\n'
printf '  real host: log lines mean the stub runs, no log lines mean dyld skipped\n'
printf '  the image and the weak link kept the app alive.\n\n'
