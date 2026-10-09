//
//  SUHost.h
//
//  Read-only view on the host application bundle.
//  (Real header: Sparkle/Source/SUHost.h)
//
//  STUB BEHAVIOUR: answers honestly (bundle name, version, paths, Info.plist
//  values) because Telegram uses these for its own update UI and logging, and
//  unexpected nils/empties there are more annoying than truthful values.
//  The *writes* to user defaults are dropped: the stub does not persist
//  update state (SUHasLaunchedBefore, SUEnableAutomaticChecks, ...).
//

#ifndef SPARKLE_STUB_SUHOST_H
#define SPARKLE_STUB_SUHOST_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SUHost : NSObject

- (instancetype)initWithBundle:(NSBundle *)bundle;

@property (nonatomic, readonly) NSString *bundlePath;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *displayVersion;
@property (nonatomic, readonly) BOOL isRunningOnReadOnlyVolume;
@property (nonatomic, readonly, nullable) id publicEDKey;
@property (nonatomic, readonly, nullable) id publicDSAKey;
@property (nonatomic, readonly, nullable) id publicKeys;
@property (nonatomic, readonly, nullable) NSString *publicDSAKeyFileKey;
@property (nonatomic, readonly) BOOL isMainBundle;
@property (nonatomic, copy, nullable) NSString *defaultsDomain;   // defaults to the bundle id

- (id _Nullable)objectForInfoDictionaryKey:(NSString *)key;
- (BOOL)boolForInfoDictionaryKey:(NSString *)key;
- (id _Nullable)objectForUserDefaultsKey:(NSString *)defaultName;
- (void)setObject:(id _Nullable)value forUserDefaultsKey:(NSString *)defaultName;  // dropped
- (BOOL)boolForUserDefaultsKey:(NSString *)defaultName;
- (void)setBool:(BOOL)value forUserDefaultsKey:(NSString *)defaultName;            // dropped
- (id _Nullable)objectForKey:(NSString *)key;
- (BOOL)boolForKey:(NSString *)key;

@property (nonatomic, strong) NSBundle *bundle;
@property (nonatomic, assign) BOOL usesStandardUserDefaults;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUHOST_H */
