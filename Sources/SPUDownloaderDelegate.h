//
//  SPUDownloaderDelegate.h
//
//  Download callbacks. The stub starts no download, so none of
//  these is inert; the protocol exists so the class hierarchies and the
//  metadata of images built against the real headers keep matching.
//  (Real header: Sparkle/Source/SPUDownloaderDelegate.h)
//

#ifndef SPARKLE_STUB_SPUDOWNLOADERDELEGATE_H
#define SPARKLE_STUB_SPUDOWNLOADERDELEGATE_H

#import <Foundation/Foundation.h>

@class SPUDownloadData;

NS_ASSUME_NONNULL_BEGIN

@protocol SPUDownloaderDelegate <NSObject>
- (void)downloaderDidSetDestinationName:(NSString *)destinationName
                     temporaryDirectory:(NSString *)temporaryDirectory;
- (void)downloaderDidReceiveExpectedContentLength:(int64_t)expectedContentLength;
- (void)downloaderDidReceiveDataOfLength:(uint64_t)length;
- (void)downloaderDidFinishWithTemporaryDownloadData:(SPUDownloadData *_Nullable)downloadData;
- (void)downloaderDidFailWithError:(NSError *)error;
@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SPUDOWNLOADERDELEGATE_H */
