//
//  SparkleStubInternal.h
//
//  Private helpers shared by all stub translation units. Not installed, not
//  part of the (documentation-only) public API.
//

#ifndef SPARKLE_STUB_INTERNAL_H
#define SPARKLE_STUB_INTERNAL_H

#import <Foundation/Foundation.h>

// ---------------------------------------------------------------------------
// Optional tracing. Run the host with SPARKLE_STUB_LOG=1 to see which Sparkle
// entry points it reaches, e.g.
//     SPARKLE_STUB_LOG=1 /Applications/Telegram.app/Contents/MacOS/Telegram
// ---------------------------------------------------------------------------

static inline BOOL SparkleStubTraceEnabled(void)
{
    static int cached = -1;
    if (cached < 0) {
        const char *env = getenv("SPARKLE_STUB_LOG");
        cached = (env != NULL && env[0] != '0' && env[0] != '\0') ? 1 : 0;
    }
    return cached == 1;
}

#define STUB_LOG(...)                                   \
    do {                                                \
        if (SparkleStubTraceEnabled()) {                \
            NSLog(@"[SparkleStub] " __VA_ARGS__);       \
        }                                               \
    } while (0)

#define STUB_LOG_SEL() STUB_LOG("%s -- no-op", sel_getName(_cmd))

// Each stub class owns at least one Objective-C object so the compiler emits a
// -cxx_destruct for it. Sparkle's real classes all expose one and destructors
// of subclasses compiled against them call it through super.
#if !__has_feature(objc_arc)
#error "The Sparkle stub must be compiled with ARC (-fobjc-arc)."
#endif

#endif /* SPARKLE_STUB_INTERNAL_H */
