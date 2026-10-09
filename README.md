# SparkleStub

An inert replacement for

    /Applications/Telegram.app/Contents/Frameworks/Sparkle.framework

It keeps the API surface and drops the behaviour: the methods that fetch,
download, extract, install, relaunch, open windows or schedule timers do
nothing.

Telegram ships a fork of **Sparkle 1.21.0** (`1.21.0 79-g48d0f55`): the `SU*` /
`SPU*` classes in framework version directory `Versions/A`. The stub reproduces
the part of that API that the Telegram binary references.

```
Sparkle.framework/
├── Sparkle                -> Versions/Current/Sparkle
└── Versions/
    ├── Current            -> A
    └── A/Sparkle          (x86_64 + arm64)
```

The tree is the dylib and two symlinks. `make INFOPLIST=1` adds
`Versions/A/Resources/Info.plist` (codesign needs it if the app is re-signed),
`make HEADERS=1` adds `Versions/A/Headers/`.

## What Telegram uses

Measured from the shipped binary (`nm`, `otool -oV`, `tools/apidiff`).

Link: `LC_LOAD_WEAK_DYLIB` → `@rpath/Sparkle.framework/Versions/A/Sparkle`,
compatibility 1.6.0, current 1.21.0. The stub uses the same install name and the
same two versions.

10 symbols imported (`make check` asserts the stub exports all of them):

```
_OBJC_CLASS_$_SPUDownloaderSession        _OBJC_CLASS_$_SUAppcastItem
_OBJC_METACLASS_$_SPUDownloaderSession    _OBJC_CLASS_$_SUBasicUpdateDriver
_OBJC_CLASS_$_SPUURLRequest               _OBJC_METACLASS_$_SUBasicUpdateDriver
_OBJC_CLASS_$_SUAppcast                   _OBJC_CLASS_$_SUHost
_OBJC_CLASS_$_SUUpdateDriver              _OBJC_CLASS_$_SUStandardVersionComparator
```

Telegram subclasses three Sparkle classes:

| Telegram class (Swift, mangled) | superclass | overrides |
|---|---|---|
| `…InternalUpdaterDownloader` | `SPUDownloaderSession` | `init`, `initWithDelegate:`, `startDownloadWithRequest:`, `cancel`, `suggestedFilename`, `moveItemAtPath:toPath:error:` |
| `…InternalUpdateDriver` | `SUBasicUpdateDriver` | `init`, `initWithUpdater:`, `checkForUpdatesAtURL:host:domain:`, `downloadUpdate`, `downloaderDidReceiveDataOfLength:`, `downloaderDidReceiveExpectedContentLength:` |
| `…ExternalUpdateDriver` | `SUBasicUpdateDriver` | the above plus `isItemNewer:`, `didFindValidUpdate`, `didNotFindUpdate`, `appcastDidFinishLoading:`, `downloaderDidFinishWithTemporaryDownloadData:`, `downloaderDidFailWithError:`, `abortUpdateWithError:`, `installerForHost:failedWithError:`, `extractUpdate`, `installWithToolAndRelaunch:displayingUserInterface:`, `unarchiverDidFinish:`, `unarchiver:extractedProgress:` |

The stub exports those classes and provides every method its subclasses can
reach, including every `[super ...]`, with the same type encoding. A wrong
encoding corrupts arguments.

Telegram does not import `SUUpdater` (no undefined symbol). The name appears in
metadata (`T@"<SUUpdaterDelegate>"`, `T@"<SUUpdaterPrivate>"`). The stub
implements it because it is the main entry point of this API, in 100 lines.

## Where updates stop

1. Parse: `-[SUAppcast parseAppcastItemsFromXMLData:error:]` and
   `…FromXMLFile:error:` return `@[]`. Telegram parses appcasts through this
   selector and sees zero items.
2. Fetch: `-[SUAppcast fetchAppcastFromURL:inBackground:completionBlock:]` does
   no I/O and does not call the completion block.
3. Compare: `-[SUStandardVersionComparator compareVersion:toVersion:]` returns
   `NSOrderedSame`, so `-[ExternalUpdateDriver isItemNewer:]` rejects every item.
4. Install: `downloadUpdate`, `extractUpdate`,
   `installWithToolAndRelaunch:`, `installWithToolAndRelaunch:displayingUserInterface:`,
   `terminateApp`, `mayUpdateAndRestart`, `start*DownloadWithRequest:` do
   nothing; `+[SUBasicUpdateDriver bestItemFromAppcastItems:…]` returns `nil`.

`-[SUUpdateDriver showAlert:]` and the other alert methods display nothing.

Getters that the host uses for logging and UI (`SUHost.name`, `version`,
`bundlePath`, `-[SPUURLRequest request]`, …) return real values, so callers do
not handle unexpected `nil`. The stub ignores writes to user defaults
(`SUEnableAutomaticChecks`, `SUHasLaunchedBefore`, …).

`SPARKLE_STUB_LOG=1` shows them running; see [Signing](#signing) for what dyld
does here.

## Build

```sh
make                        # x86_64 + arm64
make ARCH=arm64             # single architecture
make INFOPLIST=1 HEADERS=1  # add Info.plist and Headers
```

```
  built build/Sparkle
  Architectures in the fat file: build/Sparkle are: x86_64 arm64
    @rpath/Sparkle.framework/Versions/A/Sparkle
    current version 1.21.0
    compatibility version 1.6.0
    minos 11.0
```

The Mach-O versions have to satisfy the host's `LC_LOAD_DYLIB`. The deployment
target matches the original (11.0).

`TG=` may point at any app bundle: the Makefile reads the host executable from
its `Info.plist` (`CFBundleExecutable`).

## Verify

```sh
make test          # runtime smoke test, links the built framework through @rpath
make apidiff       # stub vs. the pristine Sparkle: classes, selectors,
                   # type encodings, protocol conformances
make check         # every Sparkle symbol the host imports is exported
make test-install  # install / restore / gate, against a throw-away app copy
make status        # stub or original in the app right now
```

`make test` (62 assertions) compiles probe subclasses of `SUBasicUpdateDriver`
and `SPUDownloaderSession` that call `super` the way Telegram's do.

```
  62 checks, 0 failures
  stubbed classes: 11   real classes: 44   errors: 0
  OK: every selector of every stubbed class matches the real framework
  imports from Sparkle: 10 symbols
  OK: the stub exports every Sparkle symbol the host imports
```

`make apidiff` compares against `Sparkle.framework.orig` when it exists, so the
reference stays the original.

`make test-install` copies the installed framework into a temp `Fake.app`, gives
it the same undefined Sparkle symbols Telegram has, and drives install/restore:

```
  [1] make install must pass the gate and swap the framework
    ok    install succeeded
    ok    gate ran
    ok    original kept as .orig
    ok    installed framework is the stub
    ok    backup is NOT a stub
    ok    make status calls it a stub

  [2] a stale stub must be refused (host imports SUCodeSigningVerifier)
    ok    install refused
    ok    gate named the missing symbol
    ok    nothing was moved

  21 checks, 0 failures
```

## Install / restore

```sh
make install     # gate, then move the original to Sparkle.framework.orig
                 # and copy the stub in
make restore     # move Sparkle.framework.orig back
```

* `install` runs `check` and `apidiff` against the framework that is installed
  and aborts on any error. `SKIP_CHECK=1` skips the gate.
* The Makefile signs nothing.
* `install` moves the original aside in place of copying it: one copy, kept next
  to the framework, outside `build/`, so `make clean` cannot delete it.
* `install` refuses to overwrite an existing `.orig` unless `FORCE=1`, which
  deletes it: the following `mv` would put the stub there.
* The app must not be running.

## Signing

The Makefile signs nothing and `install` leaves the app's own signature alone.

Measured on this machine (SIP disabled), with the stub installed in Telegram:

* The stub binds. `vmmap` on the running process lists
  `.../Sparkle.framework/Versions/A/Sparkle`, and `SPARKLE_STUB_LOG=1` prints the
  entry points Telegram reaches. The kill switches above are the mechanism.
* The framework's own signature decides that, not the host's.
  `tools/library_validation_test.sh` measures it:

| host | framework | result |
|---|---|---|
| shipped signature kept, hardened, not re-signed | linker-signed ad-hoc | bound |
| real Team ID, hardened runtime | linker-signed ad-hoc | bound |
| ad-hoc, hardened runtime | ad-hoc | bound |
| ad-hoc, hardened runtime | unsigned | not bound; class symbol nil |

  The linker signs the dylib at build time (`flags=0x20002 (adhoc,linker-signed)`)
  and that is enough here. Case 4 is the one to avoid: `codesign` on an unsigned
  nested framework also blocks re-signing the host, which is why the harness
  gives the test copy an `Info.plist`.
* `codesign --verify` on Telegram fails, and it failed before this change: 28
  files in the app's seal (the `libswift*.dylib` back-deployment libraries) are
  absent from the bundle, and two `Autoupdate.app` binaries did not match the
  seal. Nothing consults the seal when a non-quarantined app launches.

Other machines have other AMFI and SIP states. If dyld there skips the image,
the weak link still launches the app and updates stop because Sparkle is absent.
`SPARKLE_STUB_LOG=1` tells you which case you are in.

## Tracing

`SPARKLE_STUB_LOG=1` prints every entry point the host reaches. From a launch of
the patched Telegram:

```sh
SPARKLE_STUB_LOG=1 /Applications/Telegram.app/Contents/MacOS/Telegram 2>&1 | grep SparkleStub
```

```
[SparkleStub] initWithUpdater: -- no-op
[SparkleStub] initWithBundle: -- no-op
[SparkleStub] parseAppcastItemsFromXMLData (14117 bytes) -- returning 0 items
[SparkleStub] appcastDidFinishLoading: -- no-op
```

Telegram fetched the feed itself (14 KB) and handed the XML to the parser. The
parser returned no items, so the driver had nothing to offer: no download,
extraction, install or alert followed.

## Limits

* This stub targets this Sparkle build (1.21.0 fork, `Versions/A`).
  `make install` runs `check` and `apidiff` and refuses on a mismatch.
* `moveItemAtPath:toPath:error:` is the one method that does real work: an
  `NSFileManager` move. Telegram's downloader routes its own files through it,
  and failing there would raise an error alert where the stub stays quiet. The
  stub does not write to the trailing parameter: the shipped signature types it
  as an object (`B40@0:8@16@24@32`) while callers pass the address of an
  `NSError *` slot.
* Reinstalling Telegram from a DMG restores the real Sparkle. Run
  `make install` again.
* macOS, x86_64 and arm64. `ARCH=` accepts anything clang does.
## License

Apache 2.0. See `LICENSE`.
