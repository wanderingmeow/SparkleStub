//
//  SPUDownloader.h
//
//  Abstract downloader base class + SPUDownloaderProtocol.
//  (Real header: Sparkle/Source/SPUDownloader.h)
//
//  STUB BEHAVIOUR: no request is ever started, so no delegate callback is ever
//  delivered. Telegram subclasses the concrete subclass SPUDownloaderSession,
//  so the whole shape -- including the properties its initialiser touches --
//  has to be present.
//

#ifndef SPARKLE_STUB_SPUDOWNLOADER_H
#define SPARKLE_STUB_SPUDOWNLOADER_H

#import <Foundation/Foundation.h>
#import "SPUDownloaderDelegate.h"

@class SPUURLRequest;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSUInteger, SPUDownloaderMode) {
    SPUDownloaderModeTemporary,
    SPUDownloaderModePersistent
};

@protocol SPUDownloaderProtocol <NSObject>
- (void)startPersistentDownloadWithRequest:(SPUURLRequest *)request
                          bundleIdentifier:(NSString *_Nullable)bundleIdentifier
                           desiredFilename:(NSString *_Nullable)desiredFilename;
- (void)startTemporaryDownloadWithRequest:(SPUURLRequest *)request;
- (void)cleanup;
- (void)cancel;
@end

@interface SPUDownloader : NSObject <SPUDownloaderProtocol>

- (instancetype)initWithDelegate:(id<SPUDownloaderDelegate>)delegate;

- (void)startPersistentDownloadWithRequest:(SPUURLRequest *)request
                          bundleIdentifier:(NSString *_Nullable)bundleIdentifier
                           desiredFilename:(NSString *_Nullable)desiredFilename;
- (void)startTemporaryDownloadWithRequest:(SPUURLRequest *)request;
- (void)enableAutomaticTermination;
- (void)cleanup;
- (void)cancel;
- (void)downloadDidFinish;
- (void)downloadDidFinishWithData:(id _Nullable)downloadData;
- (NSString *_Nullable)getAndCleanTempDirectory;

@property (nonatomic, strong, nullable) id<SPUDownloaderDelegate> delegate;
@property (nonatomic, copy, nullable) NSString *bundleIdentifier;
@property (nonatomic, copy, nullable) NSString *desiredFilename;
@property (nonatomic, copy, nullable) NSString *downloadFilename;
@property (nonatomic, assign) BOOL disabledAutomaticTermination;
@property (nonatomic, assign) SPUDownloaderMode mode;
@property (nonatomic, assign) BOOL receivedExpectedBytes;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SPUDOWNLOADER_H */
