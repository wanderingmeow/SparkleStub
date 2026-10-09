#!/bin/sh
#
#  subclass_without_superclass_test.sh
#
#  The stub normally binds (see library_validation_test.sh), but a machine where
#  dyld rejects it would leave Telegram with two of its own classes whose
#  superclass is missing, because the Sparkle link is weak and dyld then skips
#  the image. This script asks whether a host survives that.
#
#  Shape: a framework owning FakeParent, a host binary defining
#  @interface Child : FakeParent, linked with -weak_framework. Each step runs in
#  its own process, so a crash is attributable to one step.
#
#  usage: tools/subclass_without_superclass_test.sh
#

set -u

ROOT=$(mktemp -d)
ARCH=$(uname -m)
FW="$ROOT/Fake.framework"
HOST="$ROOT/host"
trap 'rm -rf "$ROOT"' EXIT

# --- the "framework": one class, loaded weakly ------------------------------
mkdir -p "$FW/Versions/A"
cat > "$FW/Versions/A/FakeParent.h" <<'EOF'
#import <Foundation/Foundation.h>
@interface FakeParent : NSObject
- (NSString *)hello;
@end
EOF
cat > "$ROOT/Fake.m" <<'EOF'
#import "FakeParent.h"
@implementation FakeParent
- (NSString *)hello { return @"from the framework"; }
@end
EOF
clang -arch "$ARCH" -fobjc-arc -I "$FW/Versions/A" -dynamiclib -framework Foundation \
	-install_name '@rpath/Fake.framework/Versions/A/Fake' \
	-o "$FW/Versions/A/Fake" "$ROOT/Fake.m"
ln -sfn A "$FW/Versions/Current" 2>/dev/null
mkdir -p "$FW/Versions" && ln -sfn Versions/Current/Fake "$FW/Fake"

# --- the "host": subclasses it the way Telegram does ------------------------
cat > "$ROOT/host.m" <<'EOF'
#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import "FakeParent.h"

@interface Child : FakeParent      // lives in the host binary
@end
@implementation Child
- (NSString *)hello { return [@"child of " stringByAppendingString:[super hello]]; }
@end

@interface Unrelated : NSObject @end
@implementation Unrelated @end

int main(int argc, const char **argv)
{
	@autoreleasepool {
		const char *step = argc > 1 ? argv[1] : "0";
		switch (step[0]) {
		case '0':   /* launch only */                                   break;
		case '1':   printf("  parent class  = %p\n",
				 (__bridge void *)objc_getClass("FakeParent"));                   break;
		case '2':   printf("  child class   = %p\n", (__bridge void *)[Child class]);    break;
		case '3':   printf("  child super   = %s\n",
				 class_getName(class_getSuperclass([Child class])));      break;
		case '4': { Child *c = [[Child alloc] init];
				printf("  alloc/init    = %p\n", (__bridge void *)c);                 } break;
		case '5': { Child *c = [[Child alloc] init];
				printf("  [super hello] = %s\n",
				       [[c hello] UTF8String]);                            } break;
		case '6':   printf("  unrelated     = %p\n",
				 (__bridge void *)[[Unrelated new] description]);                  break;
		}
		return 0;
	}
}
EOF

clang -arch "$ARCH" -fobjc-arc -Wall -Wno-deprecated-declarations \
	-F "$ROOT" -Wl,-rpath,'@executable_path' -weak_framework Fake \
	-I "$FW/Versions/A" -framework Foundation -o "$HOST" "$ROOT/host.m" || exit 1

codesign --force --sign - --options runtime --timestamp=none "$FW/Versions/A/Fake" 2>/dev/null
codesign --force --sign - --options runtime --timestamp=none "$HOST" 2>/dev/null

run_all() {
	label=$1
	printf '\n  %s\n' "$label"
	for step in 0 1 2 3 4 5 6; do
		out=$("$HOST" "$step" 2>&1); rc=$?
		case $step in
			0) desc="launch only" ;;
			1) desc="objc_getClass(\"FakeParent\")" ;;
			2) desc="[Child class]" ;;
			3) desc="class_getSuperclass([Child class])" ;;
			4) desc="[[Child alloc] init]" ;;
			5) desc="[child hello]  (calls super)" ;;
			6) desc="control: unrelated class" ;;
		esac
		if [ $rc -eq 0 ]; then
			printf '    step %s  %-38s OK    %s\n' "$step" "$desc" \
				"$(printf '%s' "$out" | sed 's/^ *//')"
		else
			printf '    step %s  %-38s CRASH rc=%d %s\n' "$step" "$desc" $rc \
				"$(printf '%s' "$out" | grep -m1 -E 'Exception|Reason|Terminating|dyld' | cut -c1-90)"
		fi
	done
}

printf '\n=== a host class whose superclass lives in a weak-linked framework ===\n'

cp -a "$FW" "$ROOT/Fake.keep"
run_all "framework present and signed (normal case)"

rm -rf "$ROOT/Fake.framework"
run_all "framework GONE -> dyld skips the weak image"

cp -a "$ROOT/Fake.keep" "$FW"
codesign --remove-signature "$FW/Versions/A/Fake" 2>/dev/null
codesign --force --sign - --options runtime --timestamp=none "$HOST" 2>/dev/null
run_all "framework present but INVALID signature, host hardened (LV on)"

printf '\n  Every step OK with the framework gone means the host tolerates the\n'
printf '  missing superclass: the class resolves to nil, messages to nil do nothing.\n\n'
