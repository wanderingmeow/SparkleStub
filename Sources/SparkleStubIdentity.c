/*
 *  SparkleStubIdentity.c
 *
 *  Identity markers for this build. They exist so that a framework in some
 *  bundle can be recognised as the stub without running it:
 *
 *      nm -gU Sparkle | grep SparkleStub      ->  present  => stub
 *                                                absent   => real Sparkle
 *
 *  tools/framework_status.sh uses this test.
 */

const char *const SparkleStubMarker    = "SparkleStub: inert replacement, updates disabled";
const char *const SparkleStubAPIVersion = "1.21.0";

int SparkleStubIsStub(void) { return 1; }
