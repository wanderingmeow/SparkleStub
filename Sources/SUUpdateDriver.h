//
//  SUUpdateDriver.h
//
//  Base class of Sparkle's update state machines.
//  (Real header: Sparkle/Source/SUUpdateDriver.h)
//
//  Telegram imports this class (it is the superclass of SUBasicUpdateDriver,
//  which Telegram subclasses twice). Its `updater` property is typed
//  `id<SUUpdaterPrivate>` in the real headers, hence SUUpdaterPrivate.h.
//
//  STUB BEHAVIOUR: inert state machine. It checks nothing, displays no UI, and
//  reports itself as "finished" (idle) and "not interruptible".
//

#ifndef SPARKLE_STUB_SUUPDRIVER_H
#define SPARKLE_STUB_SUUPDRIVER_H

#import <Foundation/Foundation.h>
#import "SUUpdaterPrivate.h"

@class SUHost, SUAppcastItem;

NS_ASSUME_NONNULL_BEGIN

@interface SUUpdateDriver : NSObject

- (instancetype)initWithUpdater:(id<SUUpdaterPrivate> _Nullable)updater;

- (void)checkForUpdatesAtURL:(NSURL *)URL host:(SUHost *)host domain:(NSString *_Nullable)domain;
- (void)abortUpdate;
- (BOOL)resumeUpdateInteractively;
- (BOOL)downloadsAppcastInBackground;
- (BOOL)downloadsUpdatesInBackground;
- (BOOL)isInterruptible;
- (void)setInterruptible:(BOOL)interruptible;
- (BOOL)finished;
/// Displays nothing.
- (void)showAlert:(NSString *)message;

@property (nonatomic, strong, nullable) id download;
@property (nonatomic, strong, nullable) SUAppcastItem *updateItem;
@property (nonatomic, strong, nullable) id<SUUpdaterPrivate> updater;
@property (nonatomic, strong, nullable) SUHost *host;
@property (nonatomic, copy, nullable) NSURL *appcastURL;
@property (nonatomic, assign) BOOL automaticallyInstallUpdates;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUUPDRIVER_H */
