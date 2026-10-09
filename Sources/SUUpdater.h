//
//  SUUpdater.h
//
//  The classic Sparkle 1.x façade (the object behind a "Check for Updates…"
//  menu item).
//  (Real header: Sparkle/Source/SUUpdater.h)
//
//  Telegram does NOT import this class -- no undefined symbol for it exists in
//  the binary -- but it is *the* entry point of the v1 API, it costs little,
//  and other hosts that do use it keep working: with updates permanently off,
//  no timers and no UI.
//
//  STUB BEHAVIOUR: every check/install entry point is a no-op;
//  automaticallyChecksForUpdates / automaticallyDownloadsUpdates /
//  sendsSystemProfile read as NO whatever was set; updateCheckInterval reports
//  ~10 years, so a host computing "next check" schedules one a decade out.
//

#ifndef SPARKLE_STUB_SUUPDATER_H
#define SPARKLE_STUB_SUUPDATER_H

#import <Foundation/Foundation.h>
#import "SUUpdaterPrivate.h"

@class NSMenuItem, SUHost, SUAppcastItem;   // NSMenuItem: only used as a pointer type

NS_ASSUME_NONNULL_BEGIN

/// Telegram's binary carries this protocol name in its metadata.
@protocol SUUpdaterDelegate <NSObject>
@optional
- (void)updaterDidFindUpdateButUserDeclined:(id)updater;
@end

@interface SUUpdater : NSObject <SUUpdaterPrivate>

+ (instancetype)sharedUpdater;
+ (instancetype)updaterForBundle:(NSBundle *)bundle;

- (instancetype)initForBundle:(NSBundle *)bundle;

- (void)checkForUpdates:(id _Nullable)sender;
- (void)checkForUpdatesInBackground;
- (void)checkForUpdateInformation;
- (void)installUpdatesIfAvailable;
- (void)startUpdateCycle;
- (void)resetUpdateCycle;
- (void)scheduleNextUpdateCheck;
- (void)checkIfConfiguredProperly;
- (void)updatePermissionRequestFinishedWithResponse:(id)response;
- (void)updateDriverDidFinish:(id)driver;
- (void)checkForUpdatesWithDriver:(id)driver;
- (void)showAlertText:(NSString *)title informativeText:(NSString *)description;   // displays nothing
- (void)registerAsObserver;
- (void)unregisterAsObserver;
- (void)updateLastUpdateCheckDate;
- (void)observeValueForKeyPath:(NSString *_Nullable)keyPath ofObject:(id _Nullable)object
                        change:(NSDictionary *_Nullable)change context:(void *_Nullable)context;

- (BOOL)canCheckForUpdates;      // NO
- (BOOL)updateInProgress;        // NO
- (BOOL)validateMenuItem:(NSMenuItem *)item;

@property (nonatomic, assign) BOOL automaticallyChecksForUpdates;   // reads as NO
@property (nonatomic, assign) BOOL automaticallyDownloadsUpdates;   // reads as NO
@property (nonatomic, assign) BOOL sendsSystemProfile;              // reads as NO
@property (nonatomic, assign) double updateCheckInterval;           // ~10 years
@property (nonatomic, copy, nullable) NSURL *feedURL;
@property (nonatomic, readonly, nullable) NSURL *parameterizedFeedURL;
@property (nonatomic, readonly, nullable) NSDate *lastUpdateCheckDate;
@property (nonatomic, copy, nullable) NSString *userAgentString;
@property (nonatomic, copy, nullable) NSDictionary *httpHeaders;
@property (nonatomic, copy, nullable) NSString *decryptionPassword;
@property (nonatomic, weak, nullable) id<SUUpdaterDelegate> delegate;
@property (nonatomic, strong, nullable) NSBundle *hostBundle;
@property (nonatomic, strong, nullable) SUHost *host;
@property (nonatomic, strong, nullable) id driver;
@property (nonatomic, strong, nullable) id checkTimer;
@property (nonatomic, strong, nullable) SUAppcastItem *updateItem;
@property (nonatomic, strong, nullable) id sparkleBundle;
@property (nonatomic, strong, nullable) id updateLastCheckedDate;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUUPDATER_H */
