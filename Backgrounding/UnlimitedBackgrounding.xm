#import "headers.h"
#import "ZYBackgrounder.h"
#import "ZYRunningAppsProvider.h"

NSMutableDictionary *processAssertions = [NSMutableDictionary dictionary];
BKSProcessAssertion *keepAlive$temp;

%hook FBUIApplicationWorkspaceScene
- (void)host:(__unsafe_unretained FBScene*)arg1 didUpdateSettings:(__unsafe_unretained FBSSceneSettings*)arg2 withDiff:(unsafe_id)arg3 transitionContext:(unsafe_id)arg4 completion:(unsafe_id)arg5 {
    if ([ZYBackgrounder.sharedInstance hasUnlimitedBackgroundTime:arg1.identifier] && arg2.backgrounded && ![processAssertions objectForKey:arg1.identifier]) {
    	SBApplication *app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:arg1.identifier];

		keepAlive$temp = [[%c(BKSProcessAssertion) alloc] initWithPID:[app pid]
			flags:(ProcessAssertionFlagPreventSuspend | ProcessAssertionFlagAllowIdleSleep | ProcessAssertionFlagPreventThrottleDownCPU | ProcessAssertionFlagWantsForegroundResourcePriority)
            reason:kProcessAssertionReasonBackgroundUI
            name:@"reachapp"
			withHandler:^{
				HBLogDebug(@"ReachApp: %d kept alive: %@", [app pid], [keepAlive$temp valid] ? @"TRUE" : @"FALSE");
				if (keepAlive$temp.valid) {
          processAssertions[arg1.identifier] = keepAlive$temp;
        } else {

        }
			}];
    }
    %orig(arg1, arg2, arg3, arg4, arg5);
}
%end

@interface ZYUnlimitedBackgroundingAppWatcher : NSObject <ZYRunningAppsProviderDelegate>
+ (void)load;
@end

ZYUnlimitedBackgroundingAppWatcher *sharedInstance$ZYUnlimitedBackgroundingAppWatcher;

@implementation ZYUnlimitedBackgroundingAppWatcher
+ (void)load {
    IF_SPRINGBOARD {
        sharedInstance$ZYUnlimitedBackgroundingAppWatcher = [[ZYUnlimitedBackgroundingAppWatcher alloc] init];
        [[%c(ZYRunningAppsProvider) sharedInstance] addTarget:sharedInstance$ZYUnlimitedBackgroundingAppWatcher];
    }
}

- (void)appDidDie:(__unsafe_unretained SBApplication*)app {
    if (/*W[ZYBackgrounder.sharedInstance preventKillingOfIdentifier:app.bundleIdentifier] == NO && */[processAssertions objectForKey:app.bundleIdentifier]) {
        [processAssertions[app.bundleIdentifier] invalidate];
        [processAssertions removeObjectForKey:app.bundleIdentifier];
    }
}
@end
