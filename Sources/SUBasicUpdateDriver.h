//
//  SUBasicUpdateDriver.h
//
//  Sparkle's concrete update state machine (check -> download -> extract ->
//  install).
//  (Real header: Sparkle/Source/SUBasicUpdateDriver.h)
//
//  Telegram subclasses it twice:
//      _TtC8Telegram...InternalUpdateDriver : SUBasicUpdateDriver
//          overrides -init, -initWithUpdater:, -checkForUpdatesAtURL:host:domain:,
//                    -downloadUpdate, -downloaderDidReceiveDataOfLength:,
//                    -downloaderDidReceiveExpectedContentLength:
//      _TtC8Telegram...ExternalUpdateDriver : SUBasicUpdateDriver
//          overrides -init, -initWithUpdater:, -isItemNewer:, -didFindValidUpdate,
//                    -didNotFindUpdate, -appcastDidFinishLoading:,
//                    -checkForUpdatesAtURL:host:domain:, -downloadUpdate,
//                    -downloaderDidFinishWithTemporaryDownloadData:,
//                    -unarchiverDidFinish:, -unarchiver:extractedProgress:,
//                    -downloaderDidReceiveDataOfLength:,
//                    -downloaderDidReceiveExpectedContentLength:,
//                    -downloaderDidFailWithError:, -abortUpdateWithError:,
//                    -installerForHost:failedWithError:,
//                    -installWithToolAndRelaunch:displayingUserInterface:,
//                    -extractUpdate
//  Every one of those can reach `super`, so the full method set has to exist
//  with matching type encodings. All of them are inert.
//
//  STUB BEHAVIOUR: no update is found. isItemNewer:, itemContains*,
//  +hostSupportsItem: and +bestItemFromAppcastItems: answer negatively; no
//  download, extraction or install follows; the app is not quit.
//

#ifndef SPARKLE_STUB_SUBASICUPDRIVER_H
#define SPARKLE_STUB_SUBASICUPDRIVER_H

#import <Foundation/Foundation.h>
#import "SUUpdateDriver.h"
#import "SPUDownloaderDelegate.h"
#import "SUVersionComparison.h"
#import "SUUnarchiverProtocol.h"

@class SUAppcast, SUAppcastItem, SUHost;

NS_ASSUME_NONNULL_BEGIN

@interface SUBasicUpdateDriver : SUUpdateDriver <SPUDownloaderDelegate>

+ (SUAppcastItem *_Nullable)bestItemFromAppcastItems:(NSArray<SUAppcastItem *> *)appcastItems
                                      getDeltaItem:(SUAppcastItem *_Nullable __autoreleasing * _Nullable)deltaItem
                                   withHostVersion:(NSString *)hostVersion
                                        comparator:(id<SUVersionComparison>)comparator;
+ (BOOL)hostSupportsItem:(SUAppcastItem *)item;

- (id<SUVersionComparison>)versionComparator;
- (BOOL)isItemNewer:(SUAppcastItem *)uiItem;                  // NO
- (BOOL)itemContainsSkippedVersion:(SUAppcastItem *)uiItem;   // NO
- (BOOL)itemContainsValidUpdate:(SUAppcastItem *)uiItem;      // NO
- (void)appcastDidFinishLoading:(SUAppcast *)theAppcast;
- (void)didFindValidUpdate;
- (void)didNotFindUpdate;
- (NSString *_Nullable)appCachePath;

// download / extraction / installation: all inert
- (void)downloadUpdate;
- (void)extractUpdate;
- (void)failedToApplyDeltaUpdate;
- (void)installWithToolAndRelaunch:(BOOL)relaunch;
- (void)installWithToolAndRelaunch:(BOOL)relaunch displayingUserInterface:(BOOL)showUserInterface;
- (BOOL)preparePathForRelaunchTool:(NSString *)path error:(id _Nullable __autoreleasing * _Nullable)outError;
- (BOOL)mayUpdateAndRestart;                                   // NO
- (void)terminateApp;
- (void)cleanUpDownload;
- (void)installerForHost:(SUHost *)host failedWithError:(NSError *)error;
- (void)abortUpdateWithError:(NSError *)error;

- (void)unarchiver:(id<SUUnarchiverProtocol>)unarchiver extractedProgress:(double)progress;
- (void)unarchiverDidFinish:(id<SUUnarchiverProtocol>)unarchiver;
- (void)unarchiverDidFailWithError:(NSError *)error;

@property (nonatomic, copy, nullable) NSString *downloadPath;
@property (nonatomic, strong, nullable) SUAppcastItem *nonDeltaUpdateItem;
@property (nonatomic, copy, nullable) NSString *tempDir;
@property (nonatomic, copy, nullable) NSString *relaunchPath;
@property (nonatomic, strong, nullable) id updateValidator;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUBASICUPDRIVER_H */
