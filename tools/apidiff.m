//
//  apidiff.m
//
//  Verification tool for the Sparkle stub.
//
//      apidiff dump <mach-o>               print one line per class and per
//                                          method that image defines:
//      C <class> <superclass>
//      M <class> <I|C> <selector> <type encoding>
//
//      apidiff diff <real.api.txt> <stub.api.txt>
//
//  `diff` verdicts:
//    * class in real, absent from stub              -> note (the stub implements
//      only what the host imports)
//    * selector of a stubbed class missing, or with a different type encoding
//                                                   -> ERROR
//      The host is compiled against the real headers and calls these through
//      the class and through `[super ...]`. A wrong encoding mis-marshals
//      registers and stack, which corrupts memory.
//    * class/selector only the stub has             -> note
//
//  Exit status: 0 = no errors, 1 = errors, 2 = usage/IO failure.
//

#import <Foundation/Foundation.h>
#import <objc/runtime.h>
#import <dlfcn.h>
#import <mach-o/dyld.h>
#import <limits.h>

static NSString *RealPath(NSString *path)
{
    char buf[PATH_MAX];
    if (path.length > 0 && realpath(path.fileSystemRepresentation, buf) != NULL) {
        return @(buf);
    }
    return path;
}

static NSString *ClassName(Class cls)
{
    const char *name = cls ? class_getName(cls) : NULL;
    return name ? @(name) : @"<nil>";
}

// Which loaded image corresponds to `path`? class_getImageName() reports the
// path the image was loaded from, so compare canonical paths.
static NSString *LoadedImagePath(NSString *path)
{
    NSString *want = RealPath(path);
    for (uint32_t i = 0; i < _dyld_image_count(); i++) {
        const char *name = _dyld_get_image_name(i);
        if (name == NULL) {
            continue;
        }
        if ([RealPath(@(name)) isEqualToString:want]) {
            return @(name);
        }
    }
    return nil;
}

static void AppendProtocols(NSMutableArray<NSString *> *rows, NSString *className,
                           Class cls, char kind)
{
    unsigned count = 0;
    Protocol *__unsafe_unretained *protocols = class_copyProtocolList(cls, &count);
    for (unsigned i = 0; i < count; i++) {
        const char *name = protocol_getName(protocols[i]);
        [rows addObject:[NSString stringWithFormat:@"P\t%@\t%c\t%s",
                         className, kind, name ?: ""]];
    }
    free(protocols);
}

static void AppendMethods(NSMutableArray<NSString *> *rows, NSString *className,
                          Class cls, char kind)
{
    unsigned count = 0;
    Method *methods = class_copyMethodList(cls, &count);
    for (unsigned i = 0; i < count; i++) {
        const char *sel = sel_getName(method_getName(methods[i]));
        const char *enc = method_getTypeEncoding(methods[i]);
        [rows addObject:[NSString stringWithFormat:@"M\t%@\t%c\t%s\t%@",
                         className, kind, sel, @(enc ?: "")]];
    }
    free(methods);
}

static int Dump(int argc, const char **argv)
{
    if (argc < 3) {
        fprintf(stderr, "usage: apidiff dump <mach-o>\n");
        return 2;
    }
    NSString *path = @(argv[2]);
    if (dlopen(path.fileSystemRepresentation, RTLD_NOW | RTLD_LOCAL) == NULL) {
        fprintf(stderr, "dlopen(%s) failed: %s\n",
                path.fileSystemRepresentation, dlerror());
        return 2;
    }
    NSString *imagePath = LoadedImagePath(path);
    if (imagePath == nil) {
        fprintf(stderr, "image %s is not loaded\n", path.UTF8String);
        return 2;
    }

    unsigned count = 0;
    Class *classes = objc_copyClassList(&count);
    NSMutableArray<NSString *> *rows = [NSMutableArray array];
    for (unsigned i = 0; i < count; i++) {
        const char *imageName = class_getImageName(classes[i]);
        if (imageName == NULL || ![[@(imageName) lastPathComponent]
                                   isEqualToString:[imagePath lastPathComponent]]) {
            continue;
        }
        if (![RealPath(@(imageName)) isEqualToString:RealPath(imagePath)]) {
            continue;
        }
        NSString *name = ClassName(classes[i]);
        [rows addObject:[NSString stringWithFormat:@"C\t%@\t%@",
                         name, ClassName(class_getSuperclass(classes[i]))]];
        AppendMethods(rows, name, classes[i], 'I');
        AppendMethods(rows, name, object_getClass(classes[i]), 'C');
        AppendProtocols(rows, name, classes[i], 'I');
        AppendProtocols(rows, name, object_getClass(classes[i]), 'C');
    }
    free(classes);

    for (NSString *row in [rows sortedArrayUsingSelector:@selector(compare:)]) {
        printf("%s\n", row.UTF8String);
    }
    return 0;
}

static NSDictionary<NSString *, NSString *> *LoadMethods(NSString *file,
                                                         NSMutableSet<NSString *> *classes)
{
    NSString *text = [NSString stringWithContentsOfFile:file encoding:NSUTF8StringEncoding error:NULL];
    if (text == nil) {
        fprintf(stderr, "cannot read %s\n", file.UTF8String);
        exit(2);
    }
    NSMutableDictionary<NSString *, NSString *> *methods = [NSMutableDictionary dictionary];
    for (NSString *line in [text componentsSeparatedByString:@"\n"]) {
        NSArray<NSString *> *f = [line componentsSeparatedByString:@"\t"];
        if (f.count == 3 && [f[0] isEqualToString:@"C"]) {
            [classes addObject:f[1]];
        } else if (f.count == 5 && [f[0] isEqualToString:@"M"]) {
            methods[[NSString stringWithFormat:@"%@\tM\t%@\t%@", f[1], f[2], f[3]]] = f[4];
        } else if (f.count == 4 && [f[0] isEqualToString:@"P"]) {
            methods[[NSString stringWithFormat:@"%@\tP\t%@\t%@", f[1], f[2], f[3]]] = @"conforms";
        }
    }
    return methods;
}

static int Diff(int argc, const char **argv)
{
    if (argc < 4) {
        fprintf(stderr, "usage: apidiff diff <real.api.txt> <stub.api.txt>\n");
        return 2;
    }
    NSMutableSet<NSString *> *realClasses = [NSMutableSet set];
    NSMutableSet<NSString *> *stubClasses = [NSMutableSet set];
    NSDictionary *real = LoadMethods(@(argv[2]), realClasses);
    NSDictionary *stub = LoadMethods(@(argv[3]), stubClasses);

    NSMutableArray<NSString *> *notes = [NSMutableArray array];
    NSMutableArray<NSString *> *errors = [NSMutableArray array];

    for (NSString *cls in realClasses) {
        if (![stubClasses containsObject:cls]) {
            [notes addObject:[NSString stringWithFormat:@"not stubbed: class %@", cls]];
            continue;
        }
        NSString *prefix = [cls stringByAppendingString:@"\t"];
        for (NSString *key in real.allKeys) {
            if (![key hasPrefix:prefix]) {
                continue;
            }
            NSArray<NSString *> *f = [key componentsSeparatedByString:@"\t"];
            NSString *stubHas = stub[key];
            if (stubHas == nil) {
                if ([f[1] isEqualToString:@"M"]) {
                    NSString *kind = [f[2] isEqualToString:@"I"] ? @"-" : @"+";
                    [errors addObject:[NSString stringWithFormat:@"%@[%@ %@]  missing  (real: %@)",
                                       kind, f[0], f[3], real[key]]];
                } else {
                    [errors addObject:[NSString stringWithFormat:@"conformance  %@ <%@>  missing",
                                       f[0], f[3]]];
                }
            } else if ([f[1] isEqualToString:@"M"] && ![stubHas isEqualToString:real[key]]) {
                NSString *kind = [f[2] isEqualToString:@"I"] ? @"-" : @"+";
                [errors addObject:[NSString stringWithFormat:@"%@[%@ %@]  encoding %@  (real: %@)",
                                   kind, f[0], f[3], stubHas, real[key]]];
            }
        }
    }

    for (NSString *cls in stubClasses) {
        if (![realClasses containsObject:cls]) {
            [notes addObject:[NSString stringWithFormat:@"extra: class %@", cls]];
        }
    }

    for (NSString *n in [notes sortedArrayUsingSelector:@selector(compare:)]) {
        printf("  note  %s\n", n.UTF8String);
    }
    for (NSString *e in [errors sortedArrayUsingSelector:@selector(compare:)]) {
        printf("  ERROR %s\n", e.UTF8String);
    }

    printf("\n  stubbed classes: %lu   real classes: %lu   errors: %lu\n",
           (unsigned long)stubClasses.count, (unsigned long)realClasses.count,
           (unsigned long)errors.count);
    if (errors.count == 0) {
        printf("  OK: every selector of every stubbed class matches the real framework\n");
        return 0;
    }
    return 1;
}

int main(int argc, const char **argv)
{
    @autoreleasepool {
        if (argc >= 2 && strcmp(argv[1], "dump") == 0) {
            return Dump(argc, argv);
        }
        if (argc >= 2 && strcmp(argv[1], "diff") == 0) {
            return Diff(argc, argv);
        }
        fprintf(stderr, "usage: %s dump <mach-o>\n"
                        "       %s diff <real.api.txt> <stub.api.txt>\n",
                argv[0], argv[0]);
        return 2;
    }
}
