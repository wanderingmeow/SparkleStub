#!/bin/sh
#
#  check_symbols.sh -- does the stub export everything the host binary imports
#                      from Sparkle?
#
#  usage: check_symbols.sh <host binary> <real Sparkle dylib> <stub dylib>
#
#  1. undefined symbols of the host binary
#  2. ∩ symbols exported by the *real* Sparkle     = what the host needs from Sparkle
#  3. every one of those must be exported by the *stub*
#
#  If step 3 is clean, dyld can bind the host against the stub. It is stricter
#  than "the app launches": dyld binds Objective-C classes only for the classes
#  the host references.

set -eu

BIN=${1:?usage: check_symbols.sh <host binary> <real dylib> <stub dylib>}
REAL=${2:?missing real Sparkle dylib}
STUB=${3:?missing stub dylib}

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

nm -u "$BIN"                                    | sed 's/^ *//' | sort -u > "$TMP/undefined.txt"
nm -gU "$REAL" 2>/dev/null | awk '{print $NF}' | sort -u > "$TMP/real_exports.txt"
nm -gU "$STUB"             | awk '{print $NF}' | sort -u > "$TMP/stub_exports.txt"

comm -12 "$TMP/undefined.txt" "$TMP/real_exports.txt" > "$TMP/required.txt"

echo "  host binary      : $BIN"
echo "  imports from Sparkle: $(wc -l < "$TMP/required.txt" | tr -d ' ') symbols"
sed 's/^/    /' "$TMP/required.txt"

MISSING=$(comm -23 "$TMP/required.txt" "$TMP/stub_exports.txt")
echo
if [ -n "$MISSING" ]; then
	echo "  MISSING from the stub:"
	sed 's/^/    /' <<EOF
$MISSING
EOF
	exit 1
fi

echo "  OK: the stub exports every Sparkle symbol the host imports"
echo
echo "  classes exported by the stub:"
grep '_OBJC_CLASS_\$_' "$TMP/stub_exports.txt" | sed 's/_OBJC_CLASS_\$_/    /' | sort
