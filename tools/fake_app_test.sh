#!/bin/sh
#
#  fake_app_test.sh -- exercise install / restore / the verification gate against
#                      a throw-away app bundle in place of /Applications.
#
#  Builds <_STRIP>/Fake.app containing a copy of the real Sparkle.framework and a
#  stub host binary whose undefined symbols are the same ones Telegram imports,
#  then drives make against it. Nothing outside the temp dir is modified.
#
#  usage: tools/fake_app_test.sh [path/to/Sparkle.framework[.orig]]
#         (default: the framework installed in /Applications/Telegram.app; pass
#          the .orig once the stub sits there)
#

set -u

SRC_FW=${1:-/Applications/Telegram.app/Contents/Frameworks/Sparkle.framework}
# the copy keeps this name in the fixture, so a reference given as .orig works
FW_NAME=$(basename "$SRC_FW" .orig)
ROOT=$(mktemp -d)
APP="$ROOT/Fake.app"
BIN="$APP/Contents/MacOS/Fake"
trap 'rm -rf "$ROOT"' EXIT
cd "$(dirname "$0")/.." || exit 1

[ -d "$SRC_FW" ] || { echo "error: $SRC_FW not found"; exit 2; }

# --- the fixture app -------------------------------------------------------
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Frameworks"
cp -a "$SRC_FW" "$APP/Contents/Frameworks/$FW_NAME" || exit 2
cat > "$APP/Contents/Info.plist" <<'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict><key>CFBundleExecutable</key><string>Fake</string></dict></plist>
EOF

# The same Sparkle symbols Telegram's main binary leaves undefined.
cat > "$ROOT/imports_pos.c" <<'EOF'
extern void *OBJC_CLASS_$_SPUDownloaderSession;
extern void *OBJC_CLASS_$_SPUURLRequest;
extern void *OBJC_CLASS_$_SUAppcast;
extern void *OBJC_CLASS_$_SUAppcastItem;
extern void *OBJC_CLASS_$_SUBasicUpdateDriver;
extern void *OBJC_CLASS_$_SUHost;
extern void *OBJC_CLASS_$_SUStandardVersionComparator;
extern void *OBJC_CLASS_$_SUUpdateDriver;
extern void *OBJC_METACLASS_$_SPUDownloaderSession;
extern void *OBJC_METACLASS_$_SUBasicUpdateDriver;
void *syms[] = {
	&OBJC_CLASS_$_SPUDownloaderSession, &OBJC_CLASS_$_SPUURLRequest,
	&OBJC_CLASS_$_SUAppcast, &OBJC_CLASS_$_SUAppcastItem,
	&OBJC_CLASS_$_SUBasicUpdateDriver, &OBJC_CLASS_$_SUHost,
	&OBJC_CLASS_$_SUStandardVersionComparator, &OBJC_CLASS_$_SUUpdateDriver,
	&OBJC_METACLASS_$_SPUDownloaderSession, &OBJC_METACLASS_$_SUBasicUpdateDriver, 0 };
int main(void) { return syms[0] != 0; }
EOF

# A host that needs one class the stub does not export: this is what a future
# Telegram build would look like, and the gate has to catch it.
sed 's/extern void \*OBJC_CLASS_\$_SUHost;/extern void *OBJC_CLASS_$_SUHost;\nextern void *OBJC_CLASS_$_SUCodeSigningVerifier;/' \
	"$ROOT/imports_pos.c" |
	sed 's/&OBJC_METACLASS_\$_SUBasicUpdateDriver, 0 };/\&OBJC_METACLASS_$_SUBasicUpdateDriver,\n\&OBJC_CLASS_$_SUCodeSigningVerifier, 0 };/' \
	> "$ROOT/imports_neg.c"

build_host() {
	clang -arch "$(uname -m)" -Wl,-undefined,dynamic_lookup \
		-o "$BIN" "$ROOT/imports_$1.c" || exit 2
	printf '    host imports %s Sparkle symbols\n' \
		"$(nm -u "$BIN" | grep -c '^_OBJC')"
}

pass=0; fail=0
check() { # check <description> <expect-pass:0|1> <rc>
	if [ "$2" = "$3" ]; then printf '    ok    %s\n' "$1"; pass=$((pass+1));
	else printf '    FAIL  %s (exit %s, expected %s)\n' "$1" "$3" "$2"; fail=$((fail+1)); fi
}

printf '\n=== install / restore against a copy (nothing in /Applications is touched) ===\n'
printf '  reference framework: %s\n\n' "$SRC_FW"

printf '  fixture\n'
build_host pos

printf '\n  [1] make install must pass the gate and swap the framework\n'
make install TG="$APP" > "$ROOT/1.log" 2>&1; rc=$?
check "install succeeded" 0 $rc
grep -q 'verification gate' "$ROOT/1.log" && check "gate ran" 0 0 || check "gate ran" 0 1
[ -e "$APP/Contents/Frameworks/Sparkle.framework.orig" ] && check "original kept as .orig" 0 0 || check "original kept as .orig" 0 1
nm -gU "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle" 2>/dev/null |
	grep -q SparkleStubMarker && check "installed framework is the stub" 0 0 || check "installed framework is the stub" 0 1
nm -gU "$APP/Contents/Frameworks/Sparkle.framework.orig/Versions/A/Sparkle" 2>/dev/null |
	grep -q SparkleStubMarker && check "backup is NOT a stub" 0 1 || check "backup is NOT a stub" 0 0
./tools/framework_status.sh "$APP/Contents/Frameworks/Sparkle.framework" 2>/dev/null |
	grep -q 'STUB (inert)' && check "make status calls it a stub" 0 0 || check "make status calls it a stub" 0 1

printf '\n  [2] a stale stub must be refused (host imports SUCodeSigningVerifier)\n'
build_host neg
before=$(md5 -q "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle")
make install TG="$APP" > "$ROOT/2.log" 2>&1; rc=$?
check "install refused" 2 $([ $rc -eq 0 ] && echo 0 || echo 2)
grep -q 'MISSING from the stub' "$ROOT/2.log" && check "gate named the missing symbol" 0 0 || check "gate named the missing symbol" 0 1
grep -q 'original ->' "$ROOT/2.log" && check "nothing was moved" 0 1 || check "nothing was moved" 0 0
after=$(md5 -q "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle")
[ "$before" = "$after" ] && check "installed framework unchanged" 0 0 || check "installed framework unchanged" 0 1

printf '\n  [3] make restore must put the original back, byte for byte\n'
make restore TG="$APP" > "$ROOT/3.log" 2>&1; rc=$?
check "restore succeeded" 0 $rc
cmp -s "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle" "$SRC_FW/Versions/A/Sparkle" &&
	check "restored binary is identical to the source" 0 0 ||
	check "restored binary is identical to the source" 0 1
[ -e "$APP/Contents/Frameworks/Sparkle.framework.orig" ] && check "backup consumed by restore" 0 1 || check "backup consumed by restore" 0 0
nm -gU "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle" 2>/dev/null |
	grep -q SparkleStubMarker && check "make status calls it real Sparkle" 0 1 ||
	check "make status calls it real Sparkle" 0 0

printf '\n  [4] SKIP_CHECK=1 must install without consulting the gate\n'
build_host neg
make install TG="$APP" SKIP_CHECK=1 > "$ROOT/4.log" 2>&1; rc=$?
check "install succeeded" 0 $rc
grep -q 'verification gate' "$ROOT/4.log" && check "gate was skipped" 0 1 || check "gate was skipped" 0 0
nm -gU "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle" 2>/dev/null |
	grep -q SparkleStubMarker && check "stub installed" 0 0 || check "stub installed" 0 1

printf '\n  [5] a second install must refuse to overwrite the only .orig\n'
build_host pos
make install TG="$APP" SKIP_CHECK=1 > "$ROOT/5.log" 2>&1; rc=$?
check "install refused (FORCE needed)" 2 $([ $rc -eq 0 ] && echo 0 || echo 2)
grep -q 'already exists' "$ROOT/5.log" && check "it said why" 0 0 || check "it said why" 0 1

printf '\n  [6] restore\n'
make restore TG="$APP" > "$ROOT/6.log" 2>&1; rc=$?
check "restore succeeded" 0 $rc
cmp -s "$APP/Contents/Frameworks/Sparkle.framework/Versions/A/Sparkle" "$SRC_FW/Versions/A/Sparkle" &&
	check "byte-identical" 0 0 || check "byte-identical" 0 1

printf '\n  %d checks, %d failures\n\n' "$pass" "$fail"
[ $fail -eq 0 ]
