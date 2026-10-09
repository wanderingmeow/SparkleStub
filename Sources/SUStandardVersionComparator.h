//
//  SUStandardVersionComparator.h
//
//  Sparkle's default version comparison.
//  (Real header: Sparkle/Source/SUStandardVersionComparator.h)
//
//  ============================  KILL SWITCH #2  ============================
//  compareVersion:toVersion: answers NSOrderedSame for any input. A version
//  string from an appcast is not newer than the running build, which is the
//  answer "should we update?" code paths need. Telegram's ExternalUpdateDriver
//  -isItemNewer: consults this comparator, so a hand-made appcast is rejected
//  too.
//  ==========================================================================
//

#ifndef SPARKLE_STUB_SUSTANDARDVERSIONCOMPARATOR_H
#define SPARKLE_STUB_SUSTANDARDVERSIONCOMPARATOR_H

#import <Foundation/Foundation.h>
#import "SUVersionComparison.h"

NS_ASSUME_NONNULL_BEGIN

@interface SUStandardVersionComparator : NSObject <SUVersionComparison>

+ (SUStandardVersionComparator *)defaultComparator;

/// NSOrderedSame for any input.
- (NSComparisonResult)compareVersion:(NSString *)version toVersion:(NSString *)otherVersion;

- (NSInteger)typeOfCharacter:(NSString *)characterAsString;
- (NSArray *)splitVersionString:(NSString *)version;

@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUSTANDARDVERSIONCOMPARATOR_H */
