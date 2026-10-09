//
//  SUStandardVersionComparator.m  (stub)  --  see the kill-switch note in the header
//

#import "SUStandardVersionComparator.h"
#import "SparkleStubInternal.h"

@implementation SUStandardVersionComparator
{
    // This class owns no objects; the ivar below keeps the compiler emitting
    // -cxx_destruct (see SparkleStubInternal.h).
    id _stubReserved;
}

- (instancetype)init
{
    STUB_LOG_SEL();
    return [super init];
}

+ (SUStandardVersionComparator *)defaultComparator
{
    static SUStandardVersionComparator *shared;
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        shared = [[SUStandardVersionComparator alloc] init];
    });
    return shared;
}

- (NSComparisonResult)compareVersion:(NSString *)version toVersion:(NSString *)otherVersion
{
    STUB_LOG(@"compareVersion:%@ toVersion:%@ -> NSOrderedSame (stub)", version, otherVersion);
    return NSOrderedSame;
}

- (NSInteger)typeOfCharacter:(NSString *)characterAsString { return 0; }
- (NSArray *)splitVersionString:(NSString *)version        { return @[]; }

@end
