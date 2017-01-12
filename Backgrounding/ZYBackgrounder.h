#import "headers.h"

typedef NS_ENUM(NSInteger, ZYBackgroundMode) {
    ZYBackgroundModeNative = 1,
    ZYBackgroundModeForceNativeForOldApps = 2,
    ZYBackgroundModeForcedForeground = 3,
    ZYBackgroundModeForceNone = 4,
    ZYBackgroundModeSuspendImmediately = 5,
    ZYBackgroundModeUnlimitedBackgroundingTime = 6,
};

typedef NS_ENUM(NSInteger, ZYIconIndicatorViewInfo)  {
	ZYIconIndicatorViewInfoNone = 0,
	ZYIconIndicatorViewInfoNative = 1,
	ZYIconIndicatorViewInfoForced = 2,
	ZYIconIndicatorViewInfoSuspendImmediately = 4,

	ZYIconIndicatorViewInfoUnkillable = 8,
	ZYIconIndicatorViewInfoForceDeath = 16,

	ZYIconIndicatorViewInfoUnlimitedBackgroundTime = 32,


	ZYIconIndicatorViewInfoTemporarilyInhibit = 1024,
	ZYIconIndicatorViewInfoInhibit = 2048,
	ZYIconIndicatorViewInfoUninhibit = 4096,
};

NSString *FriendlyNameForBackgroundMode(ZYBackgroundMode mode);

@interface ZYBackgrounder : NSObject
+ (instancetype)sharedInstance;

- (BOOL)shouldAutoLaunchApplication:(NSString*)identifier;
- (BOOL)shouldAutoRelaunchApplication:(NSString*)identifier;

- (BOOL)shouldKeepInForeground:(NSString*)identifier;
- (BOOL)shouldSuspendImmediately:(NSString*)identifier;

- (BOOL)killProcessOnExit:(NSString*)identifier;
- (BOOL)shouldRemoveFromSwitcherWhenKilledOnExit:(NSString*)identifier;
- (BOOL)preventKillingOfIdentifier:(NSString*)identifier;
- (NSInteger)backgroundModeForIdentifier:(NSString*)identifier;
- (BOOL)hasUnlimitedBackgroundTime:(NSString*)identifier;

- (void)temporarilyApplyBackgroundingMode:(ZYBackgroundMode)mode forApplication:(SBApplication*)app andCloseForegroundApp:(BOOL)close;
- (void)queueRemoveTemporaryOverrideForIdentifier:(NSString*)identifier;
- (void)removeTemporaryOverrideForIdentifier:(NSString*)identifier;

- (NSInteger)application:(NSString*)identifier overrideBackgroundMode:(NSString*)mode;
- (ZYIconIndicatorViewInfo)allAggregatedIndicatorInfoForIdentifier:(NSString*)identifier;
- (void)updateIconIndicatorForIdentifier:(NSString*)identifier withInfo:(ZYIconIndicatorViewInfo)info;
- (BOOL)shouldShowIndicatorForIdentifier:(NSString*)identifier;
- (BOOL)shouldShowStatusBarIconForIdentifier:(NSString*)identifier;

@end
