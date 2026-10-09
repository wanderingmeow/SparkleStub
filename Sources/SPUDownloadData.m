//
//  SPUDownloadData.m  (stub)
//

#import "SPUDownloadData.h"
#import "SparkleStubInternal.h"

@implementation SPUDownloadData

- (instancetype)initWithData:(NSData *)data
            textEncodingName:(NSString *)textEncodingName
                    MIMEType:(NSString *)MIMEType
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _data             = [data copy] ?: [NSData data];
        _textEncodingName = [textEncodingName copy];
        _MIMEType         = [MIMEType copy];
    }
    return self;
}

+ (BOOL)supportsSecureCoding { return NO; }

// NSCoding shape only -- nothing is ever archived by the stub.
- (void)encodeWithCoder:(NSCoder *)coder {}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self initWithData:[NSData data] textEncodingName:nil MIMEType:nil];
}

@end
