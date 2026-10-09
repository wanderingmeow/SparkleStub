#!/bin/sh
#
#  framework_status.sh -- report what is installed.
#
#  usage: framework_status.sh <framework path> <original (.orig) path> <reference path>
#
#  Read-only: it inspects the files and changes nothing.

set -u

FW=${1:?usage: framework_status.sh <framework> <orig> <reference>}
ORIG=${2:-}
REF=${3:-}

describe() {
	path=$1
	[ -d "$path" ] || { printf '    %s\n        (absent)\n' "$path"; return; }
	dylib="$path/Versions/A/Sparkle"
	[ -f "$dylib" ] || dylib=$(find "$path/Versions" -name Sparkle -type f 2>/dev/null | head -1)
	if [ -z "$dylib" ] || [ ! -f "$dylib" ]; then
		printf '    %s\n        (no Mach-O found)\n' "$path"
		return
	fi
	kind=$(nm -gU "$dylib" 2>/dev/null | grep -c 'SparkleStubMarker\|SparkleStubIsStub')
	classes=$(nm -gU "$dylib" 2>/dev/null | grep -c '_OBJC_CLASS_\$_')
	arch=$(lipo -info "$dylib" 2>/dev/null | sed 's/.*are: //;s/.*architecture: //;s/ *$//')
	size=$(stat -f '%z' "$dylib")
	sig=$(codesign -dvv "$dylib" 2>&1 | grep -E '^Authority=|^Signature=|^TeamIdentifier=' | tr '\n' ' ')
	if [ "${kind:-0}" -gt 0 ]; then label="STUB (inert)"; else label="real Sparkle"; fi
	printf '    %s\n        %s  %s bytes  %s  %s exported classes\n' \
		"$path" "$label" "$size" "$arch" "$classes"
	printf '        %s\n' "${sig:-unsigned}"
}

printf '\n  installed framework:\n'
describe "$FW"
[ -n "$ORIG" ] && { printf '\n  backup:\n'; describe "$ORIG"; }
if [ -n "$REF" ] && [ "$REF" != "$FW" ] && [ "$REF" != "$ORIG" ]; then
	printf '\n  verification reference:\n'; describe "$REF"
fi
printf '\n'
