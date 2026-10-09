//
//  Sparkle.h  (stub umbrella header)
//
//  Umbrella of this stub build, mirroring the name of Sparkle's own umbrella
//  header. It exposes the modules Telegram for macOS needs:
//
//      SPUDownloadData / SPUDownloader / SPUDownloaderSession / SPUURLRequest
//      SUAppcast / SUAppcastItem / SUHost / SUStandardVersionComparator
//      SUUpdateDriver / SUBasicUpdateDriver / SUUpdater
//
//  The headers in this directory are documentation: the host app is compiled
//  against Sparkle's real headers, and this build only has to match them at the
//  level of exported symbols, selectors and type encodings.
//  `make apidiff` verifies that against the framework that is installed.
//

#ifndef SPARKLE_STUB_UMBRELLA_H
#define SPARKLE_STUB_UMBRELLA_H

// Protocols
#import "SUVersionComparison.h"
#import "SUUpdaterPrivate.h"
#import "SUUnarchiverProtocol.h"
#import "SPUDownloaderDelegate.h"

// Downloads
#import "SPUDownloadData.h"
#import "SPUDownloader.h"
#import "SPUDownloaderSession.h"
#import "SPUURLRequest.h"

// Appcast & host
#import "SUAppcast.h"
#import "SUAppcastItem.h"
#import "SUHost.h"
#import "SUStandardVersionComparator.h"

// Update drivers & façade
#import "SUUpdateDriver.h"
#import "SUBasicUpdateDriver.h"
#import "SUUpdater.h"

#endif /* SPARKLE_STUB_UMBRELLA_H */
