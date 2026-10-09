//
//  SPUDownloader.m  (stub)
//

#import "SPUDownloader.h"
#import "SPUURLRequest.h"
#import "SparkleStubInternal.h"

@implementation SPUDownloader

- (instancetype)initWithDelegate:(id<SPUDownloaderDelegate>)delegate
{
    STUB_LOG_SEL();
    self = [super init];
    if (self) {
        _delegate = delegate;
    }
    return self;
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

- (void)enableAutomaticTermination            { STUB_LOG_SEL(); }
- (void)cleanup                               { STUB_LOG_SEL(); }
- (void)cancel                                { STUB_LOG_SEL(); }
- (void)downloadDidFinish                     { STUB_LOG_SEL(); }
- (void)downloadDidFinishWithData:(id)downloadData { STUB_LOG_SEL(); }

// Real Sparkle creates a private temp directory here. The stub downloads
// so it hands out nothing (callers only use it to place a download).
- (NSString *)getAndCleanTempDirectory        { return nil; }

@end
