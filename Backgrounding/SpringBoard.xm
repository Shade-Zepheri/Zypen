#import "headers.h"
#import "ZYBackgrounder.h"
#import "ZYAppSwitcherModelWrapper.h"

%hook SBApplication
- (BOOL)shouldAutoRelaunchAfterExit {
    return [ZYBackgrounder.sharedInstance shouldAutoRelaunchApplication:self.bundleIdentifier] || %orig;
}

- (BOOL)shouldAutoLaunchOnBootOrInstall {
    return [ZYBackgrounder.sharedInstance shouldAutoLaunchApplication:self.bundleIdentifier] || %orig;
}

- (BOOL)_shouldAutoLaunchOnBootOrInstall:(BOOL)arg1 {
    return [ZYBackgrounder.sharedInstance shouldAutoLaunchApplication:self.bundleIdentifier] || %orig;
}
%end

// STAY IN "FOREGROUND"
%hook FBUIApplicationResignActiveManager
-(void) _sendResignActiveForReason:(int)arg1 toProcess:(__unsafe_unretained FBApplicationProcess*)arg2 {
    if ([ZYBackgrounder.sharedInstance shouldKeepInForeground:arg2.bundleIdentifier]) {
      return;
    }

    %orig;

    if ([ZYBackgrounder.sharedInstance shouldSuspendImmediately:arg2.bundleIdentifier]) {
        BKSProcess *bkProcess = MSHookIvar<BKSProcess*>(arg2, "_bksProcess");
        [arg2 processWillExpire:bkProcess];
    }
}
%end

%hook FBUIApplicationSceneDeactivationManager // iOS 9
- (BOOL)_isEligibleProcess:(__unsafe_unretained FBApplicationProcess*)arg1 {
    if ([ZYBackgrounder.sharedInstance shouldKeepInForeground:arg1.bundleIdentifier]) {
      return NO;
    }
    return %orig;
}
%end

%hook FBSSceneImpl
- (id)_initWithQueue:(unsafe_id)arg1 callOutQueue:(unsafe_id)arg2 identifier:(unsafe_id)arg3 display:(unsafe_id)arg4 settings:(__unsafe_unretained UIMutableApplicationSceneSettings*)arg5 clientSettings:(unsafe_id)arg6 {
    if ([ZYBackgrounder.sharedInstance shouldKeepInForeground:arg3]) {
        // what?
        if (!arg5) {
            UIMutableApplicationSceneSettings *fakeSettings = [[%c(UIMutableApplicationSceneSettings) alloc] init];
            arg5 = fakeSettings;
        }
        SET_BACKGROUNDED(arg5, NO);
    }
    return %orig(arg1, arg2, arg3, arg4, arg5, arg6);
}
%end

%hook FBUIApplicationWorkspaceScene
- (void)host:(__unsafe_unretained FBScene*)arg1 didUpdateSettings:(__unsafe_unretained FBSSceneSettings*)arg2 withDiff:(unsafe_id)arg3 transitionContext:(unsafe_id)arg4 completion:(unsafe_id)arg5 {
    [ZYBackgrounder.sharedInstance removeTemporaryOverrideForIdentifier:arg1.identifier];
    if (arg1 && arg1.identifier && arg2 && arg1.clientProcess) {
        if (arg2.backgrounded) {
            if ([ZYBackgrounder.sharedInstance killProcessOnExit:arg1.identifier]) {
                FBProcess *proc = arg1.clientProcess;

                if ([proc isKindOfClass:[%c(FBApplicationProcess) class]]) {
                    FBApplicationProcess *proc2 = (FBApplicationProcess*)proc;
                    [proc2 killForReason:1 andReport:NO withDescription:@"Zypen.Backgrounder.killOnExit" completion:nil];
                    [ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:ZYIconIndicatorViewInfoForceDeath];
                    if ([ZYBackgrounder.sharedInstance shouldRemoveFromSwitcherWhenKilledOnExit:arg1.identifier]) {
                        [%c(ZYAppSwitcherModelWrapper) removeItemWithIdentifier:arg1.identifier];
                    }
                }
                [ZYBackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier];
            }

            if ([ZYBackgrounder.sharedInstance shouldKeepInForeground:arg1.identifier]) {
                [ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
                [ZYBackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier];
                return;
            } else if ([ZYBackgrounder.sharedInstance backgroundModeForIdentifier:arg1.identifier] == ZYBackgroundModeNative) {
                [ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
                [ZYBackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier];
            } else if ([ZYBackgrounder.sharedInstance shouldSuspendImmediately:arg1.identifier]) {
                [ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
                [ZYBackgrounder.sharedInstance queueRemoveTemporaryOverrideForIdentifier:arg1.identifier];
            }
        } else if ([ZYBackgrounder.sharedInstance shouldSuspendImmediately:arg1.identifier]) {
            [ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:arg1.identifier withInfo:[ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:arg1.identifier]];
        }
    }
    %orig(arg1, arg2, arg3, arg4, arg5);
}
%end

// PREVENT KILLING
%hook FBApplicationProcess
- (void)killForReason:(int)arg1 andReport:(BOOL)arg2 withDescription:(unsafe_id)arg3 completion:(unsafe_id/*block*/)arg4 {
    if ([ZYBackgrounder.sharedInstance preventKillingOfIdentifier:self.bundleIdentifier]) {
        [ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
        return;
    }
    %orig;
}
%end

%ctor {
    IF_SPRINGBOARD {
        %init;
    }
}
