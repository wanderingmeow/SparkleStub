//
//  SUAppcastItem.h
//
//  One <item> of an appcast.
//  (Real header: Sparkle/Source/SUAppcastItem.h)
//
//  Telegram imports this class (Swift metadata refers to it as
//  `So13SUAppcastItemC`, e.g. in `[SUAppcastItem]` generic contexts), so it
//  must exist as a real class.
//
//  STUB BEHAVIOUR: plain storage. The stub creates no items, because its
//  appcast parser returns an empty array, so the class mostly serves as a type.
//  Derived getters return the neutral value for each property: no delta
//  update, no macOS update, size 0.
//

#ifndef SPARKLE_STUB_SUAPPCASTITEM_H
#define SPARKLE_STUB_SUAPPCASTITEM_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface SUAppcastItem : NSObject

- (instancetype)initWithDictionary:(NSDictionary *)dictionary domain:(NSString *_Nullable)domain;
- (instancetype)initWithDictionary:(NSDictionary *)dictionary
                    failureReason:(id _Nullable __autoreleasing * _Nullable)failureReason
                           domain:(NSString *_Nullable)domain;

@property (nonatomic, readonly) BOOL isDeltaUpdate;
@property (nonatomic, readonly) BOOL isMacOsUpdate;
@property (nonatomic, readonly) BOOL isInformationOnlyUpdate;
@property (nonatomic, readonly) NSUInteger contentLength;

@property (nonatomic, copy, nullable) NSString *dateString;
@property (nonatomic, copy, nullable) id deltaUpdates;
@property (nonatomic, copy, nullable) NSString *displayVersionString;
@property (nonatomic, strong, nullable) id signatures;
@property (nonatomic, copy, nullable) NSURL *fileURL;
@property (nonatomic, copy, nullable) NSURL *infoURL;
@property (nonatomic, copy, nullable) NSString *itemDescription;
@property (nonatomic, copy, nullable) NSString *maximumSystemVersion;
@property (nonatomic, copy, nullable) NSString *minimumSystemVersion;
@property (nonatomic, copy, nullable) NSURL *releaseNotesURL;
@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic, copy, nullable) NSString *versionString;
@property (nonatomic, copy, nullable) NSString *osString;
@property (nonatomic, copy, nullable) NSDictionary *propertiesDictionary;
@property (nonatomic, copy, nullable) NSString *env;
@property (nonatomic, copy, nullable) NSString *fileName;
@property (nonatomic, copy, nullable) NSURL *internalUrl;
@property (nonatomic, assign, getter=isCritical) BOOL critical;
@property (nonatomic, assign, getter=isForbidden) BOOL forbidden;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUAPPCASTITEM_H */
