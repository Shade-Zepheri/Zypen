#import "ZYBackgrounder.h"
#import "ZYSettings.h"
#import "Zypen.h"


NSString *FriendlyNameForBackgroundMode(ZYBackgroundMode mode) {
	switch (mode) {
		case ZYBackgroundModeNative:
			return @"Native";
		case ZYBackgroundModeForcedForeground:
			return @"Force Foreground";
		case ZYBackgroundModeForceNone:
			return @"Disable";
		case ZYBackgroundModeSuspendImmediately:
			return @"Suspend Immediately";
		case ZYBackgroundModeUnlimitedBackgroundingTime:
			return @"Unlimited Backgrounding Time";
		default:
			return @"Unknown";
	}
}

NSMutableDictionary *temporaryOverrides = [NSMutableDictionary dictionary];
NSMutableDictionary *temporaryShouldPop = [NSMutableDictionary dictionary];

@implementation ZYBackgrounder
+ (instancetype)sharedInstance {
	SHARED_INSTANCE(ZYBackgrounder);
}

- (BOOL)shouldAutoLaunchApplication:(NSString*)identifier {
	if (!identifier || ![[%c(ZYSettings) sharedSettings] backgrounderEnabled]) {
    return NO;
  }
	NSDictionary *dict = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [[%c(ZYSettings) sharedSettings] backgrounderEnabled] && enabled && ([dict objectForKey:@"autoLaunch"] == nil ? NO : [dict[@"autoLaunch"] boolValue]);
}

- (BOOL)shouldAutoRelaunchApplication:(NSString*)identifier {
	if (!identifier || ![[%c(ZYSettings) sharedSettings] backgrounderEnabled]) {
    return NO;
  }
	NSDictionary *dict = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [self killProcessOnExit:identifier] == NO && [[%c(ZYSettings) sharedSettings] backgrounderEnabled] && enabled && ([dict objectForKey:@"autoRelaunch"] == nil ? NO : [dict[@"autoRelaunch"] boolValue]);
}

- (NSInteger)popTemporaryOverrideForApplication:(NSString*)identifier {
	if (!identifier) {
    return -1;
  }
	if (![temporaryOverrides objectForKey:identifier]) {
    return -1;
  }
	ZYBackgroundMode override = (ZYBackgroundMode)[temporaryOverrides[identifier] intValue];
	return override;
}

- (void)queueRemoveTemporaryOverrideForIdentifier:(NSString*)identifier {
	if (!identifier) {
    return;
  }
	temporaryShouldPop[identifier] = @YES;
}

- (void)removeTemporaryOverrideForIdentifier:(NSString*)identifier {
	if (!identifier) {
    return;
  }
	if ([temporaryShouldPop objectForKey:identifier] != nil && [[temporaryShouldPop objectForKey:identifier] boolValue]) {
		[temporaryShouldPop removeObjectForKey:identifier];
		[temporaryOverrides removeObjectForKey:identifier];
	}
}

- (NSInteger)popTemporaryOverrideForApplication:(NSString*)identifier is:(ZYBackgroundMode)mode {
	NSInteger popped = [self popTemporaryOverrideForApplication:identifier];
	return popped == -1 ? -1 : (popped == mode ? 1 : 0);
}

- (ZYBackgroundMode)globalBackgroundMode {
	return (ZYBackgroundMode)[(ZYSettings*)[%c(ZYSettings) sharedSettings] globalBackgroundMode];
}

- (BOOL)shouldKeepInForeground:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == ZYBackgroundModeForcedForeground;
}

- (BOOL)shouldSuspendImmediately:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == ZYBackgroundModeSuspendImmediately;
}

- (BOOL)preventKillingOfIdentifier:(NSString*)identifier {
	if (!identifier || ![[%c(ZYSettings) sharedSettings] backgrounderEnabled]) {
    return NO;
  }
	NSDictionary *dict = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	return [[%c(ZYSettings) sharedSettings] backgrounderEnabled] && enabled && ([dict objectForKey:@"preventDeath"] == nil ? NO : [dict[@"preventDeath"] boolValue]);
}

- (BOOL)shouldRemoveFromSwitcherWhenKilledOnExit:(NSString*)identifier {
	if (!identifier || ![[%c(ZYSettings) sharedSettings] backgrounderEnabled]) {
    return NO;
  }
	NSDictionary *dict = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"removeFromSwitcher"] ? [dict[@"removeFromSwitcher"] boolValue] : NO;
	return [[%c(ZYSettings) sharedSettings] backgrounderEnabled] && enabled && ([dict objectForKey:@"removeFromSwitcher"] == nil ? NO : [dict[@"removeFromSwitcher"] boolValue]);
}

- (NSInteger)backgroundModeForIdentifier:(NSString*)identifier {
	@autoreleasepool {
		if (!identifier || [[%c(ZYSettings) sharedSettings] backgrounderEnabled] == NO) {
      return ZYBackgroundModeNative;
    }
		NSInteger temporaryOverride = [self popTemporaryOverrideForApplication:identifier];
		if (temporaryOverride != -1) {
      return temporaryOverride;
    }
#if __has_feature(objc_arc)
		__weak // dictionary is cached by ZYSettings anyway
#endif
		NSDictionary *dict = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
		BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
		if (!enabled) {
      return [self globalBackgroundMode];
    }
		return [dict[@"backgroundMode"] intValue];
	}
}

- (BOOL)hasUnlimitedBackgroundTime:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == ZYBackgroundModeUnlimitedBackgroundingTime;
}

- (BOOL)killProcessOnExit:(NSString*)identifier {
	return [self backgroundModeForIdentifier:identifier] == ZYBackgroundModeForceNone;
}

- (void)temporarilyApplyBackgroundingMode:(ZYBackgroundMode)mode forApplication:(SBApplication*)app andCloseForegroundApp:(BOOL)close {
	temporaryOverrides[app.bundleIdentifier] = @(mode);
	[temporaryShouldPop removeObjectForKey:app.bundleIdentifier];

	if (close) {
        FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
            SBAppToAppWorkspaceTransaction *transaction = [%c(Zypen) createSBAppToAppWorkspaceTransactionForExitingApp:app];
            [transaction begin];
        }];
        [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
	}
}

- (NSInteger)application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode {
	NSDictionary *dict = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL enabled = [dict objectForKey:@"enabled"] ? [dict[@"enabled"] boolValue] : NO;
	id val = dict[@"backgroundModes"][mode];
	return [[%c(ZYSettings) sharedSettings] backgrounderEnabled] && enabled ? (val ? [val boolValue] : -1) : -1;
}

- (ZYIconIndicatorViewInfo)allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier {
	NSInteger info = ZYIconIndicatorViewInfoNone;

	if ([self backgroundModeForIdentifier:identifier] == ZYBackgroundModeNative)
		info |= ZYIconIndicatorViewInfoNative;
	else if ([self backgroundModeForIdentifier:identifier] == ZYBackgroundModeForcedForeground)
		info |= ZYIconIndicatorViewInfoForced;
	else if ([self shouldSuspendImmediately:identifier])
		info |= ZYIconIndicatorViewInfoSuspendImmediately;
	else if ([self hasUnlimitedBackgroundTime:identifier])
		info |= ZYIconIndicatorViewInfoUnlimitedBackgroundTime;

	if ([self killProcessOnExit:identifier])
		info |= ZYIconIndicatorViewInfoForceDeath;

	if ([self preventKillingOfIdentifier:identifier])
		info |= ZYIconIndicatorViewInfoUnkillable;

	return (ZYIconIndicatorViewInfo)info;
}

- (void)updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(ZYIconIndicatorViewInfo)info {
	@autoreleasepool {
		SBIconView *ret = nil;
		if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
			SBApplicationIcon *icon = [[[%c(SBIconViewMap) homescreenMap] iconModel] applicationIconForBundleIdentifier:identifier];
			ret = [[%c(SBIconViewMap) homescreenMap] mappedIconViewForIcon:icon];
		} else {
			SBApplicationIcon *icon = [[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] applicationIconForBundleIdentifier:identifier];
			ret = [[[%c(SBIconController) sharedInstance] homescreenIconViewMap] mappedIconViewForIcon:icon];
		}
    [ret ZY_updateIndicatorView:info];
	}
}

- (BOOL)shouldShowIndicatorForIdentifier:(NSString*)identifier {
	NSDictionary *dct = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [[%c(ZYSettings) sharedSettings] shouldShowIconIndicatorsGlobally];
	return globalSetting ? ([dct objectForKey:@"showIndicatorOnIcon"] == nil ? YES : [dct[@"showIndicatorOnIcon"] boolValue]) : NO;
}

- (BOOL)shouldShowStatusBarIconForIdentifier:(NSString*)identifier {
	NSDictionary *dct = [[%c(ZYSettings) sharedSettings] rawCompiledBackgrounderSettingsForIdentifier:identifier];
	BOOL globalSetting = [[%c(ZYSettings) sharedSettings] shouldShowStatusBarIcons];
	return globalSetting ? ([dct objectForKey:@"showStatusBarIcon"] == nil ? YES : [dct[@"showStatusBarIcon"] boolValue]) : NO;
}

@end
