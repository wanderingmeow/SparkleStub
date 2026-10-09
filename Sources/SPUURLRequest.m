//
//  SPUURLRequest.m  (stub)
//

#import "SPUURLRequest.h"
#import "SparkleStubInternal.h"

@implementation SPUURLRequest
{
    NSURL *_stubURL;
    NSURLRequestCachePolicy _stubCachePolicy;
    NSTimeInterval _stubTimeoutInterval;
    NSDictionary *_stubHTTPHeaderFields;
    NSURLRequestNetworkServiceType _stubNetworkServiceType;
}

+ (instancetype)URLRequestWithRequest:(NSURLRequest *)request
{
    if (![request isKindOfClass:[NSURLRequest class]]) {
        return [[self alloc] initWithURL:nil
                             cachePolicy:NSURLRequestUseProtocolCachePolicy
                         timeoutInterval:0
                       httpHeaderFields:nil
                     networkServiceType:NSURLNetworkServiceTypeDefault];
    }
    return [[self alloc] initWithURL:request.URL
                         cachePolicy:request.cachePolicy
                     timeoutInterval:request.timeoutInterval
                    httpHeaderFields:request.allHTTPHeaderFields
                  networkServiceType:request.networkServiceType];
}

// We do not implement secure coding (nothing is ever unarchived).
+ (BOOL)supportsSecureCoding { return NO; }

- (instancetype)initWithURL:(NSURL *)url
                cachePolicy:(NSURLRequestCachePolicy)cachePolicy
            timeoutInterval:(NSTimeInterval)timeoutInterval
           httpHeaderFields:(NSDictionary *)httpHeaderFields
         networkServiceType:(NSURLRequestNetworkServiceType)networkServiceType
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _stubURL                = [url copy];
        _stubCachePolicy        = cachePolicy;
        _stubTimeoutInterval    = timeoutInterval;
        _stubHTTPHeaderFields   = [httpHeaderFields copy];
        _stubNetworkServiceType = networkServiceType;
    }
    return self;
}

- (NSURLRequest *)request
{
    if (_stubURL == nil) {
        return nil;
    }
    NSMutableURLRequest *request =
        [NSMutableURLRequest requestWithURL:_stubURL
                                cachePolicy:_stubCachePolicy
                            timeoutInterval:_stubTimeoutInterval];
    request.networkServiceType = _stubNetworkServiceType;
    for (NSString *field in _stubHTTPHeaderFields) {
        [request setValue:[_stubHTTPHeaderFields[field] description] forHTTPHeaderField:field];
    }
    return request;
}

- (NSURL *)url                      { return _stubURL; }
- (NSURLRequestCachePolicy)cachePolicy      { return _stubCachePolicy; }
- (NSTimeInterval)timeoutInterval   { return _stubTimeoutInterval; }
- (NSDictionary *)httpHeaderFields  { return _stubHTTPHeaderFields; }
- (NSURLRequestNetworkServiceType)networkServiceType { return _stubNetworkServiceType; }

- (void)encodeWithCoder:(NSCoder *)coder {}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    return [self initWithURL:nil
                 cachePolicy:NSURLRequestUseProtocolCachePolicy
             timeoutInterval:0
           httpHeaderFields:nil
         networkServiceType:NSURLNetworkServiceTypeDefault];
}

@end
