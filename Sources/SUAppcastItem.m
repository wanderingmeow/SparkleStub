//
//  SUAppcastItem.m  (stub)
//

#import "SUAppcastItem.h"
#import "SparkleStubInternal.h"

@implementation SUAppcastItem

- (instancetype)initWithDictionary:(NSDictionary *)dictionary domain:(NSString *)domain
{
    STUB_LOG_SEL();
    return [self initWithDictionary:dictionary failureReason:NULL domain:domain];
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                    failureReason:(id _Nullable __autoreleasing * _Nullable)failureReason
                           domain:(NSString *)domain
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        // No signature verification (EdDSA/DSA), no validation, no I/O: the
        // dictionary is retained so the getters echo what was put in.
        if (failureReason != NULL) {
            *failureReason = nil;
        }
        NSDictionary *dict = [dictionary isKindOfClass:[NSDictionary class]] ? dictionary : nil;
        _propertiesDictionary = [dict copy];
        _title                = [dict[@"title"] copy];
        _versionString        = [dict[@"sparkle:version"] copy];
        _displayVersionString = [dict[@"sparkle:shortVersionString"] copy];
        _itemDescription      = [dict[@"sparkle:releaseNotesLink"] copy];
        _osString             = [dict[@"sparkle:os"] copy];
        _fileName             = [dict[@"sparkle:installerKind"] copy];
        _minimumSystemVersion = [dict[@"sparkle:minimumSystemVersion"] copy];
        _maximumSystemVersion = [dict[@"sparkle:maximumSystemVersion"] copy];
        _dateString           = [dict[@"pubDate"] copy];
        id enclosure          = dict[@"enclosure"];
        if ([enclosure isKindOfClass:[NSDictionary class]]) {
            _deltaUpdates = [enclosure copy];
        }
    }
    return self;
}

// Derived state: an item the stub did not produce reports no delta / macOS /
// information-only update, and it has no size.
- (BOOL)isDeltaUpdate           { return NO; }
- (BOOL)isMacOsUpdate           { return NO; }
- (BOOL)isInformationOnlyUpdate { return NO; }
- (NSUInteger)contentLength     { return 0; }

@end
