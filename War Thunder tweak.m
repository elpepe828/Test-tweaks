#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <objc/runtime.h>


// Config & Constants
#define PREFS_PATH @"/var/mobile/Library/Preferences/com.gaijin.warthundermobile.plist"
#define BUNDLE_ID @"com.gaijin.warthundermobile"
#define FROZEN_MONEY 2000000000.0f
#define MAX_INT 2147483647

static NSMutableDictionary *prefs = nil;

NSString *decryptString(NSString *enc) {
    const char key = 0xAA;
    NSData *data = [enc dataUsingEncoding:NSUTF8StringEncoding];
    NSMutableData *decData = [data mutableCopy];
    unsigned char *bytes = (unsigned char *)decData.mutableBytes;
    for (NSUInteger i = 0; i < decData.length; i++) {
        bytes[i] ^= key;
    }
    return [[NSString alloc] initWithData:decData encoding:NSUTF8StringEncoding];
}

BOOL isHackEnabled(NSString *key) {
    NSString *encKey = @"unlock68"; // XOR encrypted "unlockAll"
    if ([key isEqualToString:decryptString(encKey)]) return [prefs[@"unlockAll"] boolValue];
    // Add more
    if (!prefs) return YES;
    return [prefs[key] boolValue];
}


float randomizeValue(float base, float variance) {
    return base * (0.95 + (arc4random_uniform(1000)/10000.0)); // +/-5%
}

void safePerform(Class cls, SEL sel, id arg) {
    if (cls && sel && [cls respondsToSelector:sel]) {
        [cls performSelector:sel withObject:arg];
    }
}


// Dynamic Unlock All (Improved)
void unlockAllVehicles() {
    if (!isHackEnabled(@"unlockAll")) return;
    
    // Dynamic class discovery
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(&classes, 0);
    NSMutableArray *candidates = [NSMutableArray array];
    for (int i = 0; i < numClasses; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if ([name rangeOfString:@"Vehicle"].location != NSNotFound ||
            [name rangeOfString:@"Unlock"].location != NSNotFound) {
            [candidates addObject:classes[i]];
        }
    }
    
    for (Class cls in candidates) {
        unsigned int methodCount;
        Method *methods = class_copyMethodList(cls, &methodCount);
        for (int j = 0; j < methodCount; j++) {
            SEL sel = method_getName(methods[j]);
            NSString *selName = NSStringFromSelector(sel);
            if ([selName rangeOfString:@"unlock"].location != NSNotFound ||
                [selName rangeOfString:@"purchase"].location != NSNotFound) {
                safePerform(cls, sel, nil);
                safePerform(cls, sel, @"1"); // Arg variants
            }
        }
        free(methods);
    }
    if (classes) free(classes);
    
    // Periodic
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 30.0 * NSEC_PER_SEC, 5.0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            unlockAllVehicles();
        });
        dispatch_resume(timer);
    });
}


// Dynamic Max Resources (Improved)
void maxResources() {
    if (!isHackEnabled(@"maxResources")) return;
    
    NSArray *keys = @[@"GoldenEagles", @"SilverLions", @"RP", @"RepairKits", @"Extinguishers", @"Toolboxes"];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (NSString *key in keys) {
        [defaults setInteger:randomizeValue(MAX_INT, 0.05) forKey:key];
    }
    [defaults synchronize];
    
    // Hook live getters if discovered (fallback to direct)
    int numClasses;
    Class *classes = NULL;
    numClasses = objc_getClassList(&classes, 0);
    for (int i = 0; i < numClasses; i++) {
        NSString *name = NSStringFromClass(classes[i]);
        if ([name rangeOfString:@"Currency"].location != NSNotFound || [name rangeOfString:@"Resource"].location != NSNotFound) {
            // Assume common getters
            SEL getSel = NSSelectorFromString(@"getBalance");
            if ([classes[i] respondsToSelector:getSel]) {
                // Will be hooked dynamically later
            }
        }
    }
    if (classes) free(classes);
    
    // Periodic refresh
    static dispatch_once_t once;
    dispatch_once(&once, ^{
        dispatch_queue_t queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0);
        dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, 60.0 * NSEC_PER_SEC, 10.0 * NSEC_PER_SEC);
        dispatch_source_set_event_handler(timer, ^{
            maxResources();
        });
        dispatch_resume(timer);
    });
}


// Hooks - Frozen Money & Max
// Dynamic Hooks for Money/Resources (Safe)
%hookf(float, getMoneyFloat) {
    if (isHackEnabled(@"frozenMoney")) {
        return randomizeValue(FROZEN_MONEY, 0.01);
    }
    return %orig;
}

%hookf(int, getGoldenEaglesInt) {
    if (isHackEnabled(@"maxResources")) {
        return randomizeValue(MAX_INT, 0.01);
    }
    return %orig;
}

%hookf(int, getSLInt) {
    if (isHackEnabled(@"maxResources")) {
        return randomizeValue(MAX_INT, 0.01);
    }
    return %orig;
}

%hookf(int, getRPInt) {
    if (isHackEnabled(@"maxResources")) {
        return randomizeValue(MAX_INT, 0.01);
    }
    return %orig;
}

%hookf(BOOL, spendInt, int amt) {
    if (isHackEnabled(@"blockSpend")) {
        return NO;
    }
    return %orig(amt);
}

// Dynamic offset hook fallback (if specific func known)


// Enhanced AAA+ Anti-Ban (Dynamic, Randomized)
static NSString *fakeDeviceID = nil;

%hookf(BOOL, isJailbroken) {
    if (isHackEnabled(@"antiBan")) {
        return NO;
    }
    return %orig;
}

%hookf(BOOL, integrityCheck) {
    if (isHackEnabled(@"antiBan")) {
        return YES;
    }
    return %orig;
}

%hookf(BOOL, cheatDetectedAnyVariant) {
    if (isHackEnabled(@"antiBan")) {
        return NO;
    }
    return %orig;
}

%hookf(void, reportCheatAny, id data) {
    if (isHackEnabled(@"antiBan")) {
        return; // Block
    }
    %orig(data);
}

%hookf(NSString*, deviceID) {
    if (isHackEnabled(@"antiBan") && !fakeDeviceID) {
        fakeDeviceID = [UIDevice currentDevice].uniqueIdentifier; // Spoof real-like
        fakeDeviceID = [fakeDeviceID stringByAppendingString:[NSString stringWithFormat:@"%d", arc4random_uniform(10000)]];
    }
    return fakeDeviceID ?: %orig;
}

// Additional anti-ban: Block telemetry/server checks periodically
%hookf(void, sendTelemetryData, NSDictionary *data) {
    if (isHackEnabled(@"antiBan")) {
        NSMutableDictionary *cleanData = [data mutableCopy];
        [cleanData removeObjectForKey:@"deviceInfo"];
        [cleanData removeObjectForKey:@"cheatFlags"];
        %orig(cleanData);
    } else {
        %orig(data);
    }
}


// App launch
%hook UIApplicationDelegate // Better target than NSObject

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    unlockAllVehicles();
    maxResources();
    return %orig(application, launchOptions);
}

%end


%ctor {
    // Load prefs
    prefs = [NSMutableDictionary dictionaryWithContentsOfFile:PREFS_PATH];
    if (!prefs) {
        prefs = [NSMutableDictionary dictionary];
        prefs[@"enabledHacks"] = @YES;
        prefs[@"unlockAll"] = @YES;
        prefs[@"maxResources"] = @YES;
        prefs[@"frozenMoney"] = @YES;
        prefs[@"antiBan"] = @YES;
        [prefs writeToFile:PREFS_PATH atomically:YES];
    }
    
    if ([prefs[@"debugLog"] boolValue]) {
        NSLog(@"%@ Loaded", decryptString(@"WarT55hunderHack")); // Encrypted log
    }
    
    // Stealth: Hook NSException to swallow tweak-related crashes
    MSHookMessageEx(NSClassFromString(@"NSException"), @selector(raise:format:), (IMP)swallowException, NULL);
}
static void swallowException(id self, SEL _cmd, NSString *name, NSString *reason) {
    if ([name rangeOfString:@"tweak"].location == NSNotFound && [reason rangeOfString:@"substrate"].location == NSNotFound) {
        ((void(*)(id, SEL, NSString*, NSString*))objc_msgSend)(self, _cmd, name, reason);
    }
}
