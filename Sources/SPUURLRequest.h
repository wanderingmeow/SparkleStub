//
//  SPUURLRequest.h
//
//  A codable, network-independent description of a request (Sparkle uses it so
//  that requests can be archived into an SPUURLRequest and replayed by the
//  downloaders).
//  (Real header: Sparkle/Source/SPUURLRequest.h)
//
//  Implemented: a value object that performs no I/O. Telegram's downloader
//  subclass reads -request, so a nil here would break its own code.
//

#ifndef SPARKLE_STUB_SPUURLREQUEST_H
#define SPARKLE_STUB_SPUURLREQUEST_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPUURLRequest : NSObject <NSSecureCoding>

+ (instancetype)URLRequestWithRequest:(NSURLRequest *)request;
+ (BOOL)supportsSecureCoding;

- (instancetype)initWithURL:(NSURL *_Nullable)url
                cachePolicy:(NSURLRequestCachePolicy)cachePolicy
            timeoutInterval:(NSTimeInterval)timeoutInterval
           httpHeaderFields:(NSDictionary *_Nullable)httpHeaderFields
         networkServiceType:(NSURLRequestNetworkServiceType)networkServiceType;

@property (nonatomic, readonly) NSURLRequest *request;
@property (nonatomic, readonly, nullable) NSURL *url;
@property (nonatomic, readonly) NSURLRequestCachePolicy cachePolicy;
@property (nonatomic, readonly) NSTimeInterval timeoutInterval;
@property (nonatomic, readonly, nullable) NSDictionary *httpHeaderFields;
@property (nonatomic, readonly) NSURLRequestNetworkServiceType networkServiceType;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SPUURLREQUEST_H */
