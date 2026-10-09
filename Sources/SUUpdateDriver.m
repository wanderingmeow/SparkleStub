//
//  SUUpdateDriver.m  (stub)
//

#import "SUUpdateDriver.h"
#import "SUHost.h"
#import "SUAppcastItem.h"
#import "SparkleStubInternal.h"

@implementation SUUpdateDriver
{
    BOOL _interruptible;
}

- (instancetype)initWithUpdater:(id<SUUpdaterPrivate> _Nullable)updater
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _updater = updater;
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (stub, inert)>",
            NSStringFromClass([self class]), (void *)self];
}

- (void)checkForUpdatesAtURL:(NSURL *)URL host:(SUHost *)host domain:(NSString *)domain
{
    STUB_LOG(@"checkForUpdatesAtURL:%@ -- refusing to check", URL);
}

- (void)abortUpdate { STUB_LOG_SEL(); }

- (BOOL)resumeUpdateInteractively     { return NO; }
- (BOOL)downloadsAppcastInBackground  { return NO; }
- (BOOL)downloadsUpdatesInBackground  { return NO; }
- (BOOL)isInterruptible               { return _interruptible; }
- (void)setInterruptible:(BOOL)value  { _interruptible = value; }
- (BOOL)finished                      { return YES; }   // idle: nothing is running

- (void)showAlert:(NSString *)message
{
    // No UI, ever.
    STUB_LOG(@"suppressed alert: %@", message);
}

@end
