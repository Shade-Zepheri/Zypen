#import "headers.h"
#import "ZYBackgrounder.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

@interface FBApplicationInfo : NSObject
@property (nonatomic, copy) NSString *bundleIdentifier;
- (BOOL)isExitsOnSuspend;
@end

%hook FBApplicationInfo
- (BOOL)supportsBackgroundMode:(__unsafe_unretained NSString *)mode {
	int override = [ZYBackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
  if (override == -1) {
		return %orig;
	}
	return override;
}
%end

%hook BKSProcessAssertion
- (id)initWithPID:(int)arg1 flags:(unsigned int)arg2 reason:(unsigned int)arg3 name:(unsafe_id)arg4 withHandler:(unsafe_id)arg5 {
    if ((arg3 == kProcessAssertionReasonViewServices) == NO && // whitelist this to allow share menu to work
        [arg4 isEqualToString:@"Called by Filza_main, from -[AppDelegate applicationDidEnterBackground:]"] == NO && // Whitelist filza to prevent iOS hang (?!)
        IS_SPRINGBOARD == NO) {
        NSString *identifier = NSBundle.mainBundle.bundleIdentifier;

        if (!identifier) {
					goto ORIGINAL;
				}

        //HBLogInfo(@"[ReachApp] BKSProcessAssertion initWithPID:'%zd' flags:'%tu' reason:'%tu' name:'%@' withHandler:'%@' process identifier:'%@'", arg1, arg2, arg3, arg4, arg5, identifier);

        if ([ZYBackgrounder.sharedInstance shouldSuspendImmediately:identifier]) {
            if ((arg3 >= kProcessAssertionReasonAudio && arg3 <= kProcessAssertionReasonVOiP)) {
                //HBLogDebug(@"[ReachApp] blocking BKSProcessAssertion");
                //if (arg5)
                //{
                    //void (^arg5fix)() = arg5;
                    //arg5fix();
                    // ^^ causes crashes with share menu
                //}
                return nil;
            }
            //else if (arg3 == kProcessAssertionReasonActivation)
            //{
            //    arg2 = ProcessAssertionFlagAllowIdleSleep;
            //}
        }
    }
ORIGINAL:
    return %orig(arg1, arg2, arg3, arg4, arg5);
}

%end
