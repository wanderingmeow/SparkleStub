//
//  smoke_test.m
//
//  Runtime smoke test for the stub. It links against the built framework
//  (-F build -framework Sparkle), so the bundle layout, the symlinks and the
//  install name (@rpath/Sparkle.framework/Versions/A/Sparkle) are exercised by
//  dyld.
//
//  It checks three things:
//    1. the class hierarchy and the runtime metadata dyld/the ObjC runtime need,
//    2. the behaviour the stub promises (nothing fetched, nothing newer, nothing
//       installed, no callbacks, no UI),
//    3. subclassing -- Telegram subclasses SUBasicUpdateDriver and
//       SPUDownloaderSession and calls into super, so a probe subclass does the
//       same, including the -cxx_destruct chain under ARC.
//
//  Exit status: 0 = all checks passed.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>

#import "SUBasicUpdateDriver.h"
#import "SPUDownloaderSession.h"
#import "SUHost.h"
#import "SUStandardVersionComparator.h"
#import "SUUpdater.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SPUURLRequest.h"
#import "SPUDownloadData.h"

static unsigned gChecks = 0, gFailures = 0;

#define CHECK(cond, ...)                                                        \
    do {                                                                        \
        gChecks++;                                                              \
        if (!(cond)) {                                                          \
            gFailures++;                                                        \
            printf("  FAIL  %s:%d  ", __FILE__, __LINE__);                      \
            printf(__VA_ARGS__);                                                \
            printf("\n");                                                       \
        }                                                                       \
    } while (0)

// ---------------------------------------------------------------------------
// Probe subclasses that mirror what Telegram's binary does
// ---------------------------------------------------------------------------

@interface ProbeBasicDriver : SUBasicUpdateDriver
@property (nonatomic, strong) NSString *probeIvar;
@end

@implementation ProbeBasicDriver
// Telegram's subclasses override -init / -initWithUpdater: and reach into super.
- (instancetype)init
{
    if ((self = [super init])) {
        _probeIvar = @"init";
    }
    return self;
}

- (instancetype)initWithUpdater:(id<SUUpdaterPrivate>)updater
{
    if ((self = [super initWithUpdater:updater])) {
        _probeIvar = @"initWithUpdater:";
    }
    return self;
}

- (void)checkForUpdatesAtURL:(NSURL *)URL host:(SUHost *)host domain:(NSString *)domain
{
    [super checkForUpdatesAtURL:URL host:host domain:domain];
}
- (void)downloadUpdate            { [super downloadUpdate]; }
- (void)extractUpdate             { [super extractUpdate]; }
- (void)abortUpdateWithError:(NSError *)e { [super abortUpdateWithError:e]; }
- (void)installWithToolAndRelaunch:(BOOL)r displayingUserInterface:(BOOL)u
{
    [super installWithToolAndRelaunch:r displayingUserInterface:u];
}
- (void)downloaderDidReceiveDataOfLength:(uint64_t)len { [super downloaderDidReceiveDataOfLength:len]; }
- (void)downloaderDidReceiveExpectedContentLength:(int64_t)len { [super downloaderDidReceiveExpectedContentLength:len]; }
- (void)unarchiverDidFinish:(id<SUUnarchiverProtocol>)u { [super unarchiverDidFinish:u]; }
- (void)unarchiver:(id<SUUnarchiverProtocol>)u extractedProgress:(double)p { [super unarchiver:u extractedProgress:p]; }
- (void)installerForHost:(SUHost *)h failedWithError:(NSError *)e { [super installerForHost:h failedWithError:e]; }
- (void)didFindValidUpdate        { [super didFindValidUpdate]; }
- (void)didNotFindUpdate          { [super didNotFindUpdate]; }
- (void)appcastDidFinishLoading:(SUAppcast *)a { [super appcastDidFinishLoading:a]; }
// -dealloc/.cxx_destruct are synthesized: this class owns an object, and so must
// its superclass, or ARC's destructor chain would trap.
@end

@interface ProbeDownloader : SPUDownloaderSession
@property (nonatomic, strong) NSString *probeIvar;
@end

@implementation ProbeDownloader
- (instancetype)init
{
    if ((self = [super init])) {
        _probeIvar = @"init";
    }
    return self;
}
- (instancetype)initWithDelegate:(id<SPUDownloaderDelegate>)delegate
{
    if ((self = [super initWithDelegate:delegate])) {
        _probeIvar = @"initWithDelegate:";
    }
    return self;
}
- (void)startDownloadWithRequest:(SPUURLRequest *)request { [super startDownloadWithRequest:request]; }
- (void)cancel { [super cancel]; }
- (NSString *)suggestedFilename { return [super suggestedFilename]; }
- (BOOL)moveItemAtPath:(NSString *)s toPath:(NSString *)d error:(NSError *)e
{
    return [super moveItemAtPath:s toPath:d error:e];
}
@end

// ---------------------------------------------------------------------------

static void CheckHierarchy(void)
{
    printf("  hierarchy & metadata\n");
    CHECK([SUBasicUpdateDriver superclass] == [SUUpdateDriver class], "SUBasicUpdateDriver super");
    CHECK([SUUpdateDriver superclass] == [NSObject class], "SUUpdateDriver super");
    CHECK([SPUDownloaderSession superclass] == [SPUDownloader class], "SPUDownloaderSession super");
    CHECK([SPUDownloader superclass] == [NSObject class], "SPUDownloader super");

    CHECK([(id)[SUBasicUpdateDriver class] conformsToProtocol:@protocol(SPUDownloaderDelegate)],
          "SUBasicUpdateDriver <SPUDownloaderDelegate>");
    CHECK([(id)[SUStandardVersionComparator class] conformsToProtocol:@protocol(SUVersionComparison)],
          "SUStandardVersionComparator <SUVersionComparison>");
    CHECK([(id)[SPUDownloaderSession class] conformsToProtocol:@protocol(SPUDownloaderProtocol)],
          "SPUDownloaderSession <SPUDownloaderProtocol>");
    CHECK([(id)[SPUDownloaderSession class] conformsToProtocol:@protocol(NSURLSessionDelegate)],
          "SPUDownloaderSession <NSURLSessionDelegate>");
    CHECK([(id)[SUUpdater class] conformsToProtocol:@protocol(SUUpdaterPrivate)],
          "SUUpdater <SUUpdaterPrivate>");

    // Every stub class must expose -cxx_destruct: subclasses compiled against the
    // real framework call it through super.
    for (Class cls in @[ [SUAppcastItem class], [SUAppcast class], [SUHost class],
                         [SUStandardVersionComparator class], [SUUpdateDriver class],
                         [SUBasicUpdateDriver class], [SPUDownloader class],
                         [SPUDownloaderSession class], [SPUURLRequest class],
                         [SPUDownloadData class], [SUUpdater class] ]) {
        CHECK(class_getInstanceMethod(cls, sel_registerName(".cxx_destruct")) != NULL,
              "%s has no -cxx_destruct", class_getName(cls));
    }
}

static void CheckKillSwitches(void)
{
    printf("  kill switches\n");

    // #1 nothing is parsed, nothing is fetched, no callback is delivered.
    SUAppcast *appcast = [[SUAppcast alloc] initWithDomain:@"example"];
    NSData *fakeAppcast = [@"<?xml version='1.0'?><rss><channel><item>"
                           @"<title>New</title><enclosure url='https://example/x.dmg'/>"
                           "</item></channel></rss>" dataUsingEncoding:NSUTF8StringEncoding];
    CHECK([appcast parseAppcastItemsFromXMLData:fakeAppcast error:NULL].count == 0,
          "parseAppcastItemsFromXMLData returned items");
    CHECK([appcast parseAppcastItemsFromXMLFile:@"/dev/null" error:NULL].count == 0,
          "parseAppcastItemsFromXMLFile returned items");

    __block int callbacks = 0;
    [appcast fetchAppcastFromURL:[NSURL URLWithString:@"https://example.com/appcast.xml"]
                    inBackground:NO
                 completionBlock:^(NSArray *items, NSError *error) { callbacks++; }];
    CHECK(callbacks == 0, "fetchAppcastFromURL invoked its completion block");

    // #2 no version is ever newer.
    SUStandardVersionComparator *cmp = [SUStandardVersionComparator defaultComparator];
    CHECK(cmp != nil, "defaultComparator is nil");
    CHECK(cmp == [SUStandardVersionComparator defaultComparator], "defaultComparator is not a singleton");
    CHECK([cmp compareVersion:@"99999.0" toVersion:@"1.0"] == NSOrderedSame,
          "compareVersion reported a difference");
    CHECK([cmp compareVersion:@"1.0" toVersion:@"99999.0"] == NSOrderedSame,
          "compareVersion reported a difference");

    // Passing "no item" to these is intentional; going through a variable keeps
    // -Wnonnull quiet for the nonnull-annotated parameters.
    SUAppcastItem *nilItem = nil;

    // Drivers find no update and install nothing.
    ProbeBasicDriver *driver = [[ProbeBasicDriver alloc] initWithUpdater:nil];
    CHECK(driver != nil, "subclass of SUBasicUpdateDriver failed to initialise");
    CHECK([driver probeIvar] != nil, "[super initWithUpdater:] returned nil");
    CHECK([driver isItemNewer:nilItem] == NO, "isItemNewer:");
    CHECK([driver itemContainsValidUpdate:nilItem] == NO, "itemContainsValidUpdate:");
    CHECK([driver mayUpdateAndRestart] == NO, "mayUpdateAndRestart");
    CHECK([driver versionComparator] == cmp, "versionComparator is not the same-version comparator");
    CHECK([SUBasicUpdateDriver hostSupportsItem:nilItem] == NO, "+hostSupportsItem:");
    SUAppcastItem *delta = (id)@"sentinel";
    CHECK([SUBasicUpdateDriver bestItemFromAppcastItems:@[ (id)@"x" ] getDeltaItem:&delta
                                        withHostVersion:@"1" comparator:cmp] == nil,
          "+bestItemFromAppcastItems returned an item");
    CHECK(delta == nil, "+bestItemFromAppcastItems did not clear the delta out-parameter");

    // These return without downloading or quitting.
    [driver checkForUpdatesAtURL:[NSURL URLWithString:@"https://example.com/a.xml"]
                            host:[[SUHost alloc] initWithBundle:[NSBundle mainBundle]]
                          domain:nil];
    [driver downloadUpdate];
    [driver extractUpdate];
    [driver installWithToolAndRelaunch:YES displayingUserInterface:YES];
    [driver terminateApp];
    [driver abortUpdateWithError:[NSError errorWithDomain:@"x" code:1 userInfo:nil]];
    [driver downloaderDidReceiveDataOfLength:1];
    [driver downloaderDidFinishWithTemporaryDownloadData:nil];
    CHECK([driver finished] == YES, "a stub driver should report itself finished/idle");

    // No download starts.
    ProbeDownloader *dl = [[ProbeDownloader alloc] initWithDelegate:appcast];
    CHECK(dl != nil && [dl probeIvar] != nil, "subclass of SPUDownloaderSession failed to initialise");
    CHECK([dl delegate] == appcast, "initWithDelegate: did not retain the delegate");
    [dl startDownloadWithRequest:[SPUURLRequest URLRequestWithRequest:
                                  [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com/x.dmg"]]]];
    CHECK([dl suggestedFilename] == nil, "suggestedFilename should be nil");
    CHECK([dl downloadSession] == nil, "an NSURLSession was created");
    [dl cancel];
    [dl cleanup];

    // The SUUpdater façade stays off after writes.
    SUUpdater *updater = [SUUpdater sharedUpdater];
    CHECK(updater == [SUUpdater sharedUpdater], "sharedUpdater is not a singleton");
    [updater setAutomaticallyChecksForUpdates:YES];
    [updater setAutomaticallyDownloadsUpdates:YES];
    [updater setSendsSystemProfile:YES];
    CHECK(updater.automaticallyChecksForUpdates == NO, "automaticallyChecksForUpdates reads YES");
    CHECK(updater.automaticallyDownloadsUpdates == NO, "automaticallyDownloadsUpdates reads YES");
    CHECK(updater.sendsSystemProfile == NO, "sendsSystemProfile reads YES");
    CHECK(updater.updateCheckInterval > 365 * 24 * 3600, "updateCheckInterval is short");
    CHECK(updater.canCheckForUpdates == NO, "canCheckForUpdates");
    CHECK(updater.lastUpdateCheckDate == nil, "lastUpdateCheckDate");
    [updater checkForUpdates:nil];
    [updater checkForUpdatesInBackground];
    [updater installUpdatesIfAvailable];
    [updater startUpdateCycle];
    [updater scheduleNextUpdateCheck];
}

static void CheckHostAndRequests(void)
{
    printf("  host & request value objects\n");

    NSBundle *mainBundle = [NSBundle mainBundle];
    SUHost *host = [[SUHost alloc] initWithBundle:mainBundle];
    CHECK(host.bundlePath.length > 0, "SUHost.bundlePath is empty");
    CHECK(host.isMainBundle == YES, "SUHost.isMainBundle");
    CHECK(host.version != nil, "SUHost.version is nil");
    CHECK(host.publicEDKey == nil, "the stub should not expose verification keys");

    // This test binary is a plain executable without an Info.plist, so read a
    // bundle that has one (Foundation), which shows the values are real.
    SUHost *foundation = [[SUHost alloc] initWithBundle:[NSBundle bundleForClass:[NSString class]]];
    CHECK(foundation.name.length > 0, "SUHost.name is empty");
    CHECK(foundation.version.length > 0, "SUHost.version is empty");
    CHECK(foundation.displayVersion.length > 0, "SUHost.displayVersion is empty");
    CHECK([foundation objectForInfoDictionaryKey:@"CFBundleIdentifier"] != nil,
          "objectForInfoDictionaryKey:");
    CHECK(foundation.isMainBundle == NO, "SUHost.isMainBundle for a foreign bundle");
    CHECK(foundation.defaultsDomain.length > 0, "SUHost.defaultsDomain is empty");

    // writes are dropped
    [host setObject:@(YES) forUserDefaultsKey:@"SUEnableAutomaticChecks"];
    [host setBool:YES forUserDefaultsKey:@"SUHasLaunchedBefore"];
    CHECK([host boolForUserDefaultsKey:@"SUEnableAutomaticChecks"] == NO,
          "SUHost wrote to the user defaults");

    SPUURLRequest *req = [SPUURLRequest URLRequestWithRequest:
                          [NSURLRequest requestWithURL:[NSURL URLWithString:@"https://example.com/a.xml"]]];
    CHECK(req.request.URL.absoluteString.length > 0, "SPUURLRequest.request lost its URL");
    CHECK([SPUURLRequest supportsSecureCoding] == NO, "supportsSecureCoding");

    SPUDownloadData *data = [[SPUDownloadData alloc] initWithData:[NSData data]
                                                  textEncodingName:nil
                                                          MIMEType:@"text/xml"];
    CHECK(data.MIMEType.length > 0, "SPUDownloadData lost its MIME type");
}

int main(void)
{
    @autoreleasepool {
        printf("Sparkle stub smoke test\n");
        CheckHierarchy();
        CheckKillSwitches();
        CheckHostAndRequests();

        // Force the probe objects through dealloc/.cxx_destruct before exiting.
        @autoreleasepool {
            ProbeBasicDriver *d = [[ProbeBasicDriver alloc] init];
            [d didFindValidUpdate];
            [d didNotFindUpdate];
            ProbeDownloader *p = [[ProbeDownloader alloc] init];
            (void)p;
        }

        printf("\n  %u checks, %u failures\n", gChecks, gFailures);
        return gFailures == 0 ? 0 : 1;
    }
}
