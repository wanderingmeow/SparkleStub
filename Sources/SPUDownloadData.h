//
//  SPUDownloadData.h
//
//  Value object handed to SPUDownloaderDelegate when a download finishes.
//  Telegram does not import this class; it exists so the delegate signatures
//  match the real framework.
//  (Real header: Sparkle/Source/SPUDownloadData.h)
//
//  STUB BEHAVIOUR: plain storage. It can only ever be constructed by a
//  downloader, and the stub downloaders produce none.
//

#ifndef SPARKLE_STUB_SPUDOWNLOADDATA_H
#define SPARKLE_STUB_SPUDOWNLOADDATA_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SPUDownloadData : NSObject <NSSecureCoding>

+ (BOOL)supportsSecureCoding;   // NO: the stub unarchives nothing

- (instancetype)initWithData:(NSData *)data
            textEncodingName:(NSString *_Nullable)textEncodingName
                    MIMEType:(NSString *_Nullable)MIMEType;

@property (nonatomic, readonly, copy) NSData *data;
@property (nonatomic, readonly, copy, nullable) NSString *textEncodingName;
@property (nonatomic, readonly, copy, nullable) NSString *MIMEType;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SPUDOWNLOADDATA_H */
