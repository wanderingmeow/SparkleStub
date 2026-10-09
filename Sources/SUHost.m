//
//  SUHost.m  (stub)
//

#import "SUHost.h"
#import "SparkleStubInternal.h"

@implementation SUHost

- (instancetype)initWithBundle:(NSBundle *)bundle
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _bundle = bundle ?: [NSBundle mainBundle];
        _usesStandardUserDefaults = YES;
    }
    return self;
}

- (NSBundle *)bundle
{
    if (_bundle == nil) {
        _bundle = [NSBundle mainBundle];
    }
    return _bundle;
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@: %p (stub) path=%@>",
            NSStringFromClass([self class]), (void *)self, self.bundlePath];
}

- (NSString *)bundlePath { return self.bundle.bundlePath; }

- (NSString *)name
{
    NSDictionary *info = self.bundle.infoDictionary;
    return info[@"CFBundleDisplayName"] ?: info[@"CFBundleName"]
           ?: self.bundle.bundleIdentifier ?: @"";
}

- (NSString *)version        { return self.bundle.infoDictionary[@"CFBundleVersion"] ?: @""; }
- (NSString *)displayVersion { return self.bundle.infoDictionary[@"CFBundleShortVersionString"] ?: @""; }

- (BOOL)isRunningOnReadOnlyVolume { return NO; }
- (BOOL)isMainBundle              { return [self.bundle isEqual:[NSBundle mainBundle]]; }
// The stub writes no defaults. The host may set the domain; it falls back
// to the bundle identifier like the original does.
- (NSString *)defaultsDomain      { return _defaultsDomain ?: self.bundle.bundleIdentifier; }

// No update verification happens in the stub, so there are no public keys.
- (id)publicEDKey                 { return nil; }
- (id)publicDSAKey                { return nil; }
- (id)publicKeys                  { return nil; }
- (NSString *)publicDSAKeyFileKey { return nil; }

- (id)objectForInfoDictionaryKey:(NSString *)key
{
    return self.bundle.infoDictionary[key];
}

- (BOOL)boolForInfoDictionaryKey:(NSString *)key
{
    return [self.bundle.infoDictionary[key] boolValue];
}

- (NSUserDefaults *)stub_defaults
{
    NSString *domain = self.defaultsDomain;
    if (self.usesStandardUserDefaults || domain.length == 0) {
        return [NSUserDefaults standardUserDefaults];
    }
    return [[NSUserDefaults alloc] initWithSuiteName:domain];
}

- (id)objectForUserDefaultsKey:(NSString *)defaultName
{
    return [[self stub_defaults] objectForKey:defaultName];
}

- (BOOL)boolForUserDefaultsKey:(NSString *)defaultName
{
    return [[self stub_defaults] boolForKey:defaultName];
}

- (void)setObject:(id)value forUserDefaultsKey:(NSString *)defaultName
{
    // Not written: the stub keeps no update state.
    STUB_LOG(@"dropped defaults write: %@ = %@", defaultName, value);
}

- (void)setBool:(BOOL)value forUserDefaultsKey:(NSString *)defaultName
{
    STUB_LOG(@"dropped defaults write: %@ = %d", defaultName, value);
}

- (id)objectForKey:(NSString *)key
{
    id value = [self objectForUserDefaultsKey:key];
    return value ?: [self objectForInfoDictionaryKey:key];
}

- (BOOL)boolForKey:(NSString *)key
{
    return [[self objectForKey:key] boolValue];
}

@end
