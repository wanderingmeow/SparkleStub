//
//  SUVersionComparison.h
//
//  Stub replacement for Sparkle 1.x's version comparison protocol.
//  (Real header: Sparkle/Source/SUVersionComparison.h)
//

#ifndef SPARKLE_STUB_SUVERSIONCOMPARISON_H
#define SPARKLE_STUB_SUVERSIONCOMPARISON_H

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Implemented by SUStandardVersionComparator, which in this stub
/// answers NSOrderedSame.
@protocol SUVersionComparison <NSObject>
- (NSComparisonResult)compareVersion:(NSString *)version toVersion:(NSString *)otherVersion;
@end

NS_ASSUME_NONNULL_END

#endif /* SPARKLE_STUB_SUVERSIONCOMPARISON_H */
