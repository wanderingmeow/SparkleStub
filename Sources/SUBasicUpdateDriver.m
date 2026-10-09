//
//  SUBasicUpdateDriver.m  (stub)
//

#import "SUBasicUpdateDriver.h"
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUHost.h"
#import "SUStandardVersionComparator.h"
#import "SparkleStubInternal.h"

@implementation SUBasicUpdateDriver

+ (SUAppcastItem *)bestItemFromAppcastItems:(NSArray<SUAppcastItem *> *)appcastItems
                              getDeltaItem:(SUAppcastItem *_Nullable __autoreleasing * _Nullable)deltaItem
                           withHostVersion:(NSString *)hostVersion
                                comparator:(id<SUVersionComparison>)comparator
{
    STUB_LOG(@"bestItemFromAppcastItems (%lu items) -> none", (unsigned long)appcastItems.count);
    if (deltaItem != NULL) {
        *deltaItem = nil;
    }
    return nil;
}

+ (BOOL)hostSupportsItem:(SUAppcastItem *)item { return NO; }

// The comparator that answers "same version" for any input (kill switch #2).
- (void)checkForUpdatesAtURL:(NSURL *)URL host:(SUHost *)host domain:(NSString *)domain
{
    STUB_LOG(@"checkForUpdatesAtURL:%@ -- refusing to check", URL);
}

- (void)abortUpdate { STUB_LOG_SEL(); }

- (id<SUVersionComparison>)versionComparator
{
    return [SUStandardVersionComparator defaultComparator];
}

- (BOOL)isItemNewer:(SUAppcastItem *)uiItem                { return NO; }
- (BOOL)itemContainsSkippedVersion:(SUAppcastItem *)uiItem { return NO; }
- (BOOL)itemContainsValidUpdate:(SUAppcastItem *)uiItem    { return NO; }

// Telegram's driver subclass calls [super appcastDidFinishLoading:] and then
// waits for the state machine to report the outcome: the host clears its
// "Retrieving information..." label in -didNotFindUpdate. Real Sparkle decides
// that here from the parsed items. With no items the answer is fixed, and
// reporting it is what keeps the host's UI from hanging.
- (void)appcastDidFinishLoading:(SUAppcast *)theAppcast
{
    STUB_LOG(@"appcastDidFinishLoading: (%lu items) -- reporting no update",
             (unsigned long)theAppcast.items.count);
    [self didNotFindUpdate];
}
- (void)didFindValidUpdate   { STUB_LOG(@"didFindValidUpdate -- unreachable in practice"); }
- (void)didNotFindUpdate     { STUB_LOG_SEL(); }
- (NSString *)appCachePath   { return nil; }

- (void)downloadUpdate           { STUB_LOG(@"downloadUpdate -- refused"); }
- (void)extractUpdate            { STUB_LOG(@"extractUpdate -- refused"); }
- (void)failedToApplyDeltaUpdate { STUB_LOG_SEL(); }

- (void)installWithToolAndRelaunch:(BOOL)relaunch
{
    STUB_LOG(@"installWithToolAndRelaunch:%d -- refused", relaunch);
}

- (void)installWithToolAndRelaunch:(BOOL)relaunch displayingUserInterface:(BOOL)showUserInterface
{
    STUB_LOG(@"installWithToolAndRelaunch:%d displayingUserInterface:%d -- refused",
             relaunch, showUserInterface);
}

- (BOOL)preparePathForRelaunchTool:(NSString *)path error:(id _Nullable __autoreleasing * _Nullable)outError
{
    if (outError != NULL) {
        *outError = nil;
    }
    return NO;
}

- (BOOL)mayUpdateAndRestart { return NO; }

- (void)terminateApp     { STUB_LOG(@"terminateApp -- refused"); }
- (void)cleanUpDownload  { STUB_LOG_SEL(); }

- (void)installerForHost:(SUHost *)host failedWithError:(NSError *)error { STUB_LOG_SEL(); }
- (void)abortUpdateWithError:(NSError *)error { STUB_LOG(@"abortUpdateWithError: %@", error); }

- (void)unarchiver:(id<SUUnarchiverProtocol>)unarchiver extractedProgress:(double)progress { STUB_LOG_SEL(); }
- (void)unarchiverDidFinish:(id<SUUnarchiverProtocol>)unarchiver { STUB_LOG_SEL(); }
- (void)unarchiverDidFailWithError:(NSError *)error             { STUB_LOG_SEL(); }

// SPUDownloaderDelegate -- inert.
- (void)downloaderDidSetDestinationName:(NSString *)destinationName
                     temporaryDirectory:(NSString *)temporaryDirectory { STUB_LOG_SEL(); }
- (void)downloaderDidReceiveExpectedContentLength:(int64_t)expectedContentLength { STUB_LOG_SEL(); }
- (void)downloaderDidReceiveDataOfLength:(uint64_t)bytesCount { STUB_LOG_SEL(); }
- (void)downloaderDidFinishWithTemporaryDownloadData:(SPUDownloadData *)downloadData
{
    STUB_LOG(@"downloaderDidFinishWithTemporaryDownloadData -- ignored");
}
- (void)downloaderDidFailWithError:(NSError *)error { STUB_LOG_SEL(); }

@end
