//
//  SUUpdater.m  (stub)
//

#import "SUUpdater.h"
#import "SUUpdaterPrivate.h"
#import "SUHost.h"
#import "SUAppcastItem.h"
#import "SparkleStubInternal.h"

@implementation SUUpdater

+ (instancetype)sharedUpdater
{
    static SUUpdater *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[SUUpdater alloc] initForBundle:[NSBundle mainBundle]];
    });
    return shared;
}

+ (instancetype)updaterForBundle:(NSBundle *)bundle
{
    return [[SUUpdater alloc] initForBundle:bundle];
}

- (instancetype)init
{
    return [self initForBundle:[NSBundle mainBundle]];
}

- (instancetype)initForBundle:(NSBundle *)bundle
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _hostBundle = bundle ?: [NSBundle mainBundle];
        _host = [[SUHost alloc] initWithBundle:_hostBundle];
    }
    return self;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (stub, updates disabled)>",
            NSStringFromClass([self class]), (void *)self];
}

- (void)checkForUpdates:(id)sender  { STUB_LOG(@"checkForUpdates: -- refused"); }
- (void)checkForUpdatesInBackground { STUB_LOG(@"checkForUpdatesInBackground -- refused"); }
- (void)checkForUpdateInformation   { STUB_LOG(@"checkForUpdateInformation -- refused"); }
- (void)installUpdatesIfAvailable   { STUB_LOG(@"installUpdatesIfAvailable -- refused"); }
- (void)startUpdateCycle            { STUB_LOG(@"startUpdateCycle -- refused"); }
- (void)resetUpdateCycle            { STUB_LOG_SEL(); }
- (void)scheduleNextUpdateCheck     { STUB_LOG(@"scheduleNextUpdateCheck -- refused (no timer)"); }
- (void)checkIfConfiguredProperly   { STUB_LOG_SEL(); }
- (void)updatePermissionRequestFinishedWithResponse:(id)response { STUB_LOG_SEL(); }
- (void)updateDriverDidFinish:(id)driver { STUB_LOG_SEL(); }
- (void)checkForUpdatesWithDriver:(id)driver { STUB_LOG(@"checkForUpdatesWithDriver: -- refused"); }
- (void)showAlertText:(NSString *)title informativeText:(NSString *)description
{
    STUB_LOG(@"suppressed alert: %@ -- %@", title, description);
}
- (void)registerAsObserver   { STUB_LOG_SEL(); }   // no KVO is needed by the stub
- (void)unregisterAsObserver { STUB_LOG_SEL(); }
- (void)updateLastUpdateCheckDate { STUB_LOG(@"updateLastUpdateCheckDate -- dropped (no check happened)"); }

// KVO: the stub observes nothing, so nothing ever arrives here.
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object
                        change:(NSDictionary *)change context:(void *)context {}

// Shape only: the stub registers no observers, so there is nothing to tear down.
- (void)dealloc {}

- (BOOL)canCheckForUpdates          { return NO; }
- (BOOL)updateInProgress            { return NO; }

- (BOOL)validateMenuItem:(NSMenuItem *)item
{
    // Keep the host's "Check for Updates…" item looking normal; its action is inert.
    return YES;
}

- (BOOL)automaticallyChecksForUpdates { return NO; }
- (void)setAutomaticallyChecksForUpdates:(BOOL)value
{
    STUB_LOG(@"setAutomaticallyChecksForUpdates:%d -- ignored", value);
}

- (BOOL)automaticallyDownloadsUpdates { return NO; }
- (void)setAutomaticallyDownloadsUpdates:(BOOL)value
{
    STUB_LOG(@"setAutomaticallyDownloadsUpdates:%d -- ignored", value);
}

- (BOOL)sendsSystemProfile              { return NO; }
- (void)setSendsSystemProfile:(BOOL)value { STUB_LOG(@"setSendsSystemProfile:%d -- ignored", value); }

- (double)updateCheckInterval
{
    // ~10 years: hosts computing "next check = last check + interval" give up.
    return 10.0 * 365.0 * 24.0 * 3600.0;
}

- (void)setUpdateCheckInterval:(double)interval
{
    STUB_LOG(@"setUpdateCheckInterval:%f -- ignored", interval);
}

- (NSURL *)parameterizedFeedURL   { return nil; }
- (NSDate *)lastUpdateCheckDate   { return nil; }

@end
