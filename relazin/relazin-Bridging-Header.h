//
//  lara-Bridging-Header.h
//  lara
//

@import UIKit;
#import <Foundation/Foundation.h>

#import "darksword.h"
#import "offsets.h"
#import "utils.h"
#import "vnode.h"
#import "apfs.h"
#import "vfs.h"
#import "sbx.h"
#import "IconServices.h"
#import "rc.h"
#import "RemoteCall.h"
#import "decrypt.h"
#import "persistence.h"
#import "ota.h"
#import "screentime.h"

// cyengine — tweaks ported from cyanide
#import "cyengine/tweaks/appswitchergrid.h"
#import "cyengine/tweaks/killallapps.h"
#import "cyengine/tweaks/hide_home_bar.h"
#import "cyengine/tweaks/darksword_tweaks.h"
#import "cyengine/tweaks/sbcustomizer.h"
#import "cyengine/tweaks/statbar.h"
#import "cyengine/tweaks/nsbar.h"
#import "cyengine/tweaks/darksword_ota.h"
#import "cyengine/tweaks/call_recording_sound.h"
#import "cyengine/tweaks/powercuff.h"

#import <zlib.h>

long findcachedataoff(const char *mgkey);
void LaraClearIconCache(void);

@interface UIDevice(Private)
+ (BOOL)_hasHomeButton;
@end

void test(NSString *path);

NS_ASSUME_NONNULL_BEGIN

@interface VarCleanBridge : NSObject

+ (NSDictionary *)loadRulesNamed:(NSString *)resourceName
                        inBundle:(NSBundle *)bundle
                           error:(NSError * _Nullable * _Nullable)error;

+ (BOOL)probePathExists:(NSString *)path
            isDirectory:(BOOL *)isDirectory
              isSymlink:(BOOL *)isSymlink;

@end

NS_ASSUME_NONNULL_END
