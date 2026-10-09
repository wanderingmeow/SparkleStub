//
//  SUAppcast.h
//
//  Appcast fetching + XML parsing.
//  (Real header: Sparkle/Source/SUAppcast.h)
//
//  ============================  KILL SWITCH #1  ============================
//  Telegram's ExternalUpdateDriver parses appcasts through this class (its
//  binary references -parseAppcastItemsFromXMLData:error:). The stub
//  It fetches nothing and parses to an empty array, which callers read as "the
//  feed contains no items" -> "you are up to date". No error, no alert, no
//  callback, no update.
//  ==========================================================================
//

#ifndef SPARKLE_STUB_SUAPPCAST_H
#define SPARKLE_STUB_SUAPPCAST_H

#import <Foundation/Foundation.h>
#import "SPUDownloaderDelegate.h"

@class SUAppcastItem;

NS_ASSUME_NONNULL_BEGIN

typedef void (^SUAppcastCompletionBlock)(NSArray *items, NSError *_Nullable error);

@interface SUAppcast : NSObject <SPUDownloaderDelegate>

- (instancetype)initWithDomain:(NSString *_Nullable)domain;

/// No fetch, no completionBlock call.
- (void)fetchAppcastFromURL:(NSURL *)appcastURL
               inBackground:(BOOL)background
            completionBlock:(SUAppcastCompletionBlock _Nullable)completionBlock;

/// Returns an empty array: no updates exist.
- (NSArray<SUAppcastItem *> *)parseAppcastItemsFromXMLFile:(NSString *)xmlFile
                                                     error:(id _Nullable __autoreleasing * _Nullable)error;
/// Returns an empty array: no updates exist.
- (NSArray<SUAppcastItem *> *)parseAppcastItemsFromXMLData:(NSData *)xmlData
                                                     error:(id _Nullable __autoreleasing * _Nullable)error;

- (id _Nullable)bestNodeInNodes:(NSArray *)nodes;
- (NSDictionary *_Nullable)attributesOfNode:(id)node;
- (NSString *_Nullable)sparkleNamespacedNameOfNode:(id)node;
- (void)reportError:(NSError *)error;
- (SUAppcast *)copyWithoutDeltaUpdates;

@property (nonatomic, copy, nullable) SUAppcastCompletionBlock completionBlock;
@property (nonatomic, copy, nullable) NSString *userAgentString;
@property (nonatomic, copy, nullable) NSDictionary *httpHeaders;
@property (nonatomic, strong, nullable) id download;
@property (nonatomic, copy) NSArray<SUAppcastItem *> *items;
@property (nonatomic, copy, nullable) NSString *domain;

// SPUDownloaderDelegate (inert: no download is reported)
- (void)downloaderDidSetDestinationName:(NSString *)destinationName
                     temporaryDirectory:(NSString *)temporaryDirectory;
- (void)downloaderDidReceiveExpectedContentLength:(int64_t)expectedContentLength;
- (void)downloaderDidReceiveDataOfLength:(uint64_t)length;
- (void)downloaderDidFinishWithTemporaryDownloadData:(SPUDownloadData *_Nullable)downloadData;
- (void)downloaderDidFailWithError:(NSError *)error;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUAPPCAST_H */
