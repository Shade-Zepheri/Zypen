#import "ZYSettings.h"
#import "headers.h"
#import "ZYBackgrounder.h"
#import "ZYThemeManager.h"

#define BOOL(key, default) ([_settings objectForKey:key] != nil ? [_settings[key] boolValue] : default)

NSCache *backgrounderSettingsCache = [NSCache new];


@implementation ZYSettings
+ (BOOL)isParagonInstalled {
	static BOOL installed = NO;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
	    installed = [NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/ParagonPlus.dylib"];
	});
	return installed;
}

+ (BOOL)isActivatorInstalled {
	static BOOL installed = NO;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		if ([NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libactivator.dylib"]) {
			installed = YES;
	    dlopen("/Library/MobileSubstrate/DynamicLibraries/libactivator.dylib", RTLD_LAZY);
		}
	});
	return installed;
}

+ (BOOL)isLibStatusBarInstalled {
	static BOOL installed = NO;
	static dispatch_once_t onceToken = 0;
	dispatch_once(&onceToken, ^{
		if ([NSFileManager.defaultManager fileExistsAtPath:@"/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib"]) {
			installed = YES;
	    dlopen("/Library/MobileSubstrate/DynamicLibraries/libstatusbar.dylib", RTLD_LAZY);
		}
	});
	return installed;
}

+ (instancetype)sharedSettings {
	SHARED_INSTANCE(ZYSettings);
}

- (id)init {
	if (self = [super init]) {
		[self reloadSettings];
	}
	return self;
}

- (void)reloadSettings {
	@autoreleasepool {
		// Prepare specialized setting change cases

		// Reload Settings
		if (_settings) {
			//CFRelease((__bridge CFDictionaryRef)_settings);
			_settings = nil;
		}
		CFPreferencesAppSynchronize(CFSTR("com.shade.zypen"));
		CFStringRef appID = CFSTR("com.shade.zypen");
		CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

		BOOL failed = NO;

		if (keyList) {
			//_settings = (__bridge NSDictionary *)CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
			_settings = (NSDictionary*)CFBridgingRelease(CFPreferencesCopyMultiple(keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost));
			CFRelease(keyList);

			if (!_settings) {
				//HBLogDebug(@"[ReachApp] failure loading from CFPreferences");
				failed = YES;
			}
		}
		else {
			//HBLogDebug(@"[ReachApp] failure loading keyList");
			failed = YES;
		}
		CFRelease(appID);

		if (failed) {
			_settings = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.shade.zypen.plist"];
			//HBLogDebug(@"[ReachApp] settings sandbox load: %@", _settings == nil ? @"failed" : @"succeed");
		}

		if (_settings == nil) {
			HBLogDebug(@"[ReachApp] could not load settings from CFPreferences or NSDictionary");
		}

		if ([self shouldShowStatusBarIcons] == NO && [objc_getClass("SBApplication") respondsToSelector:@selector(ZY_clearAllStatusBarIcons)])
			[objc_getClass("SBApplication") performSelector:@selector(ZY_clearAllStatusBarIcons)];

		[ZYThemeManager.sharedInstance invalidateCurrentThemeAndReload:[self currentThemeIdentifier]];
		[backgrounderSettingsCache removeAllObjects];
	}
}

- (void)resetSettings {
	IF_NOT_SPRINGBOARD {
		@throw [NSException exceptionWithName:@"NotSpringBoardException" reason:@"Cannot reset settings outside of SpringBoard" userInfo:nil];
	}
	CFPreferencesAppSynchronize(CFSTR("com.shade.zypen"));
	CFStringRef appID = CFSTR("com.shade.zypen");
	CFArrayRef keyList = CFPreferencesCopyKeyList(appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);

	if (keyList) {
		CFPreferencesSetMultiple(NULL, keyList, appID, kCFPreferencesCurrentUser, kCFPreferencesAnyHost);
		CFRelease(keyList);
	} else {
		HBLogDebug(@"[ReachApp] unable to get keyList to reset settings");
	}
	CFPreferencesAppSynchronize(appID);
	CFRelease(appID);

    CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.shade.zypen/Respring"), nil, nil, YES);
}

-(BOOL) enabled {
	return BOOL(@"enabled", YES);
}

-(BOOL) reachabilityEnabled {
	return [self enabled] && BOOL(@"reachabilityEnabled", YES);
}

-(BOOL) disableAutoDismiss {
	return BOOL(@"disableAutoDismiss", YES);
}

-(BOOL) enableRotation {
	return BOOL(@"enableRotation", YES);
}

-(BOOL) showNCInstead {
	return BOOL(@"showNCInstead", NO);
}

-(BOOL) homeButtonClosesReachability {
	return BOOL(@"homeButtonClosesReachability", YES);
}

-(BOOL) showBottomGrabber {
	return BOOL(@"showBottomGrabber", NO);
}

-(BOOL) showWidgetSelector {
	return BOOL(@"showAppSelector", YES);
}

-(BOOL) scalingRotationMode {
	return BOOL(@"rotationMode", NO);
}

-(BOOL) autoSizeWidgetSelector {
	return BOOL(@"autoSizeAppChooser", YES);
}

-(BOOL) showAllAppsInWidgetSelector {
	return BOOL(@"showAllAppsInAppChooser", YES);
}

-(BOOL) showRecentAppsInWidgetSelector {
	return BOOL(@"showRecents", YES);
}

-(BOOL) pagingEnabled {
	return BOOL(@"pagingEnabled", YES);
}

-(BOOL) NCAppEnabled {
	return [self enabled] && BOOL(@"ncAppEnabled", YES);
}

-(BOOL) shouldShowStatusBarNativeIcons {
	return BOOL(@"shouldShowStatusBarNativeIcons", NO);
}

-(NSMutableArray*) favoriteApps {
	NSMutableArray *favorites = [[NSMutableArray alloc] init];
	for (NSString *key in _settings.allKeys)
	{
		if ([key hasPrefix:@"Favorites-"])
		{
			NSString *ident = [key substringFromIndex:10];
			if ([_settings[key] boolValue])
				[favorites addObject:ident];
		}
	}
	return favorites;
}

-(BOOL) unifyStatusBar {
	return BOOL(@"unifyStatusBar", YES);
}

-(BOOL) flipTopAndBottom {
	return BOOL(@"flipTopAndBottom", NO);
}

-(NSString*) NCApp {
	return [_settings objectForKey:@"NCApp"] == nil ? @"com.apple.Preferences" : _settings[@"NCApp"];
}

-(BOOL) alwaysEnableGestures {
	return BOOL(@"alwaysEnableGestures", YES);
}

-(BOOL) snapWindows {
	return BOOL(@"snapWindows", YES);
}

-(BOOL) launchIntoWindows {
	return BOOL(@"launchIntoWindows", NO);
}

-(BOOL) openLinksInWindows {
	return BOOL(@"openLinksInWindows", NO);
}

-(BOOL) backgrounderEnabled {
	return [self enabled] && BOOL(@"backgrounderEnabled", YES);
}

-(BOOL) shouldShowIconIndicatorsGlobally {
	return BOOL(@"showIconIndicators", YES);
}

-(BOOL) showNativeStateIconIndicators {
	return BOOL(@"showNativeStateIconIndicators", NO);
}

-(BOOL) missionControlEnabled {
	return [self enabled] && BOOL(@"missionControlEnabled", YES);
}

-(BOOL) replaceAppSwitcherWithMC {
	return BOOL(@"replaceAppSwitcherWithMC", NO);
}

-(BOOL) missionControlKillApps {
	return BOOL(@"mcKillApps", YES);
}

-(BOOL) snapRotation {
	return BOOL(@"snapRotation", YES);
}

- (NSInteger)globalBackgroundMode {
	return [_settings objectForKey:@"globalBackgroundMode"] == nil ? ZYBackgroundModeNative : [_settings[@"globalBackgroundMode"] intValue];
}

-(NSInteger) windowRotationLockMode {
	return [_settings objectForKey:@"windowRotationLockMode"] == nil ? 0 : [_settings[@"windowRotationLockMode"] intValue];
}

-(BOOL) shouldShowStatusBarIcons {
	return BOOL(@"shouldShowStatusBarIcons", YES);
}

-(NSDictionary*) _createAndCacheBackgrounderSettingsForIdentifier:(NSString*)identifier {
	NSMutableDictionary *ret = [NSMutableDictionary dictionary];

	ret[@"enabled"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-enabled",identifier]] ?: @NO;
	ret[@"backgroundMode"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundMode",identifier]] ?: @1;
	ret[@"autoLaunch"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-autoLaunch",identifier]] ?: @NO;
	ret[@"autoRelaunch"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-autoRelaunch",identifier]] ?: @NO;
	ret[@"showIndicatorOnIcon"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-showIndicatorOnIcon",identifier]] ?: @YES;
	ret[@"preventDeath"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-preventDeath",identifier]] ?: @NO;
	ret[@"unlimitedBackgrounding"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-unlimitedBackgrounding",identifier]] ?: @NO;
	ret[@"removeFromSwitcher"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-removeFromSwitcher",identifier]] ?: @NO;
	ret[@"showStatusBarIcon"] = _settings[[NSString stringWithFormat:@"backgrounder-%@-showStatusBarIcon",identifier]] ?: @YES;

	ret[@"backgroundModes"] = [NSMutableDictionary dictionary];
	ret[@"backgroundModes"][kBGModeUnboundedTaskCompletion] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeUnboundedTaskCompletion]] ?: @NO;
	ret[@"backgroundModes"][kBGModeContinuous] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeContinuous]] ?: @NO;
	ret[@"backgroundModes"][kBGModeFetch] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeFetch]] ?: @NO;
	ret[@"backgroundModes"][kBGModeRemoteNotification] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeRemoteNotification]] ?: @NO;
	ret[@"backgroundModes"][kBGModeExternalAccessory] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeExternalAccessory]] ?: @NO;
	ret[@"backgroundModes"][kBGModeVoIP] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeVoIP]] ?: @NO;
	ret[@"backgroundModes"][kBGModeLocation] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeLocation]] ?: @NO;
	ret[@"backgroundModes"][kBGModeAudio] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeAudio]] ?: @NO;
	ret[@"backgroundModes"][kBGModeBluetoothCentral] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeBluetoothCentral]] ?: @NO;
	ret[@"backgroundModes"][kBGModeBluetoothPeripheral] = _settings[[NSString stringWithFormat:@"backgrounder-%@-backgroundmodes-%@",identifier,kBGModeBluetoothPeripheral]] ?: @NO;

	[backgrounderSettingsCache setObject:ret forKey:identifier];

	return ret;
}

- (NSDictionary*)rawCompiledBackgrounderSettingsForIdentifier:(NSString*)identifier {
	return [backgrounderSettingsCache objectForKey:identifier] ?: [self _createAndCacheBackgrounderSettingsForIdentifier:identifier];
}

-(BOOL) isFirstRun {
	HBLogDebug(@"[ReachApp] %d", BOOL(@"isFirstRun", YES));
	return BOOL(@"isFirstRun", YES);
}

-(void) setFirstRun:(BOOL)value {
	CFPreferencesSetAppValue(CFSTR("isFirstRun"), value ? kCFBooleanTrue : kCFBooleanFalse, CFSTR("com.shade.zypen"));
	CFPreferencesAppSynchronize(CFSTR("com.shade.zypen"));
	[self reloadSettings];
}

-(BOOL) alwaysShowSOGrabber {
	return BOOL(@"alwaysShowSOGrabber", NO);
}

-(BOOL) swipeOverEnabled {
	return [self enabled] && BOOL(@"swipeOverEnabled", YES);
}

-(BOOL) windowedMultitaskingEnabled {
	return [self enabled] && BOOL(@"windowedMultitaskingEnabled", YES);
}

-(BOOL) exitAppAfterUsingActivatorAction {
	return BOOL(@"exitAppAfterUsingActivatorAction", YES);
}

-(BOOL) windowedMultitaskingCompleteAnimations {
	return BOOL(@"windowedMultitaskingCompleteAnimations", NO);
}

- (NSString*)currentThemeIdentifier {
	return _settings[@"currentThemeIdentifier"] ?: @"com.shade.zypen.themes.default";
}

-(NSInteger) missionControlDesktopStyle {
	return [_settings[@"missionControlDesktopStyle"] ?: @1 intValue];
}

-(BOOL) missionControlPagingEnabled {
	return BOOL(@"missionControlPagingEnabled", NO);
}

-(BOOL) showFavorites {
	return BOOL(@"showFavorites", YES);
}

-(BOOL) onlyShowWindowBarIconsOnOverlay {
	return BOOL(@"onlyShowWindowBarIconsOnOverlay", NO);
}

-(BOOL) quickAccessUseGenericTabLabel {
	return BOOL(@"quickAccessUseGenericTabLabel", NO);
}

-(BOOL) ncAppHideOnLS {
	return BOOL(@"ncAppHideOnLS", NO);
}

-(BOOL) showSnapHelper {
	return BOOL(@"showSnapHelper", NO);
}

- (ZYGrabArea) windowedMultitaskingGrabArea {
	return [_settings objectForKey:@"windowedMultitaskingGrabArea"] == nil ? ZYGrabAreaBottomLeftThird : (ZYGrabArea)[_settings[@"windowedMultitaskingGrabArea"] intValue];
}

- (ZYGrabArea)swipeOverGrabArea {
	return [_settings objectForKey:@"swipeOverGrabArea"] == nil ? ZYGrabAreaSideAnywhere : (ZYGrabArea)[_settings[@"swipeOverGrabArea"] intValue];
}

@end
