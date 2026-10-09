//
//  SPUDownloaderSession.h
//
//  NSURLSession-backed downloader.
//  (Real header: Sparkle/Source/SPUDownloaderSession.h)
//
//  Telegram subclasses it:
//      _TtC8Telegram...InternalUpdaterDownloader : SPUDownloaderSession
//  and overrides -init, -initWithDelegate:, -startDownloadWithRequest:,
//  -cancel, -suggestedFilename, -moveItemAtPath:toPath:error:. Those overrides
//  can call super, so each real method exists here with the same type
//  encoding. None of them starts a session.
//

#ifndef SPARKLE_STUB_SPUDOWNLOADERSESSION_H
#define SPARKLE_STUB_SPUDOWNLOADERSESSION_H

#import <Foundation/Foundation.h>
#import "SPUDownloader.h"

@class SPUURLRequest;

NS_ASSUME_NONNULL_BEGIN

@interface SPUDownloaderSession : SPUDownloader <SPUDownloaderProtocol, NSURLSessionDelegate>

- (void)startDownloadWithRequest:(SPUURLRequest *)request;
- (void)startPersistentDownloadWithRequest:(SPUURLRequest *)request
                          bundleIdentifier:(NSString *_Nullable)bundleIdentifier
                           desiredFilename:(NSString *_Nullable)desiredFilename;
- (void)startTemporaryDownloadWithRequest:(SPUURLRequest *)request;

- (NSString *_Nullable)suggestedFilename;
// NOTE: the shipped binary encodes this parameter as an OBJECT (B40@0:8@16@24@32),
// not as NSError **. The stub matches that marshalling.
- (BOOL)moveItemAtPath:(NSString *)srcPath
                toPath:(NSString *)dstPath
                 error:(NSError *_Nullable)error;

- (void)downloadDidFinish;
- (void)cleanup;
- (void)cancel;

// NSURLSession delegate callbacks (shape only, no session is ever created).
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location;
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite;
- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *_Nullable)error;

@property (nonatomic, strong, nullable) NSURLSession *downloadSession;
@property (nonatomic, strong, nullable) id download;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SPUDOWNLOADERSESSION_H */
