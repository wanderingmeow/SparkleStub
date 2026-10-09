//
//  SPUDownloaderSession.m  (stub)
//

#import "SPUDownloaderSession.h"
#import "SPUURLRequest.h"
#import "SparkleStubInternal.h"

@implementation SPUDownloaderSession

// The whole point of this module: no NSURLSession is ever created, so no
// update payload is ever fetched.
- (void)startDownloadWithRequest:(SPUURLRequest *)request
{
    STUB_LOG(@"startDownloadWithRequest:%@ -- refused", request.url);
}

- (void)startPersistentDownloadWithRequest:(SPUURLRequest *)request
                          bundleIdentifier:(NSString *)bundleIdentifier
                           desiredFilename:(NSString *)desiredFilename
{
    STUB_LOG(@"startPersistentDownloadWithRequest:%@ -- refused", request.url);
}

- (void)startTemporaryDownloadWithRequest:(SPUURLRequest *)request
{
    STUB_LOG(@"startTemporaryDownloadWithRequest:%@ -- refused", request.url);
}

- (NSString *)suggestedFilename { return nil; }

- (void)downloadDidFinish { STUB_LOG_SEL(); }
- (void)cleanup           { STUB_LOG_SEL(); }
- (void)cancel            { STUB_LOG_SEL(); }

// A file utility that works. Telegram's downloader subclass routes files it
// fetched itself through this method; failing here would raise an error alert
// where the stub stays quiet. Downloading and installing are stubbed
// separately.
//
// The trailing parameter is passed through untouched: the shipped signature says
// 'object' (B40@0:8@16@24@32) but callers may well hand over the address of an
// NSError * slot, so the stub does not treat it as an object.
- (BOOL)moveItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath error:(NSError *)error
{
    STUB_LOG(@"moveItemAtPath:%@ toPath:%@", srcPath, dstPath);
    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *fileError = nil;
    if ([fm fileExistsAtPath:dstPath] && ![fm removeItemAtPath:dstPath error:&fileError]) {
        STUB_LOG(@"move failed: %@", fileError);
        return NO;
    }
    BOOL moved = [fm moveItemAtPath:srcPath toPath:dstPath error:&fileError];
    if (!moved) {
        STUB_LOG(@"move failed: %@", fileError);
    }
    return moved;
}

// NSURLSession delegate plumbing -- unreachable, no session is ever created.
- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location { STUB_LOG_SEL(); }

- (void)URLSession:(NSURLSession *)session
      downloadTask:(NSURLSessionDownloadTask *)downloadTask
      didWriteData:(int64_t)bytesWritten
 totalBytesWritten:(int64_t)totalBytesWritten
totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite { STUB_LOG_SEL(); }

- (void)URLSession:(NSURLSession *)session
              task:(NSURLSessionTask *)task
didCompleteWithError:(NSError *)error { STUB_LOG_SEL(); }

@end
