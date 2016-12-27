#import <UIKit/UIKit.h>

enum ZYGrabArea {
	ZYGrabAreaBottomLeftThird = 1,
	ZYGrabAreaBottomMiddleThird = 2,
	ZYGrabAreaBottomRightThird = 3,

	ZYGrabAreaSideAnywhere = 6,
	ZYGrabAreaSideTopThird = 7,
	ZYGrabAreaSideMiddleThird = 8,
	ZYGrabAreaSideBottomThird = 9,
};

@interface ZYSettings : NSObject {
	NSDictionary *_settings;
}
+(instancetype)sharedSettings;

+(BOOL) isParagonInstalled;
+(BOOL) isActivatorInstalled;
+(BOOL) isLibStatusBarInstalled;

-(void) reloadSettings;
-(void) resetSettings;

-(BOOL) enabled;

-(BOOL) reachabilityEnabled;
-(BOOL) disableAutoDismiss;
-(BOOL) enableRotation;
-(BOOL) showNCInstead;
-(BOOL) homeButtonClosesReachability;
-(BOOL) showBottomGrabber;
-(BOOL) showWidgetSelector;
-(BOOL) scalingRotationMode;
-(BOOL) autoSizeWidgetSelector;
-(BOOL) showAllAppsInWidgetSelector;
-(BOOL) showRecentAppsInWidgetSelector;
-(BOOL) pagingEnabled;
-(NSMutableArray*) favoriteApps;
-(BOOL) unifyStatusBar;
-(BOOL) flipTopAndBottom;
-(BOOL) showFavorites;

-(BOOL) NCAppEnabled;
-(NSString*) NCApp;
-(BOOL) ncAppHideOnLS;

-(BOOL) alwaysEnableGestures;
-(BOOL) snapWindows;
-(BOOL) snapRotation;
-(BOOL) launchIntoWindows;
-(BOOL) windowedMultitaskingCompleteAnimations;
-(BOOL) openLinksInWindows;
-(BOOL) showSnapHelper;

-(NSInteger) globalBackgroundMode;
-(BOOL) shouldShowStatusBarIcons;
-(BOOL) shouldShowStatusBarNativeIcons;
-(BOOL) backgrounderEnabled;
-(BOOL) shouldShowIconIndicatorsGlobally;
-(BOOL) showNativeStateIconIndicators;
-(NSDictionary*) rawCompiledBackgrounderSettingsForIdentifier:(NSString*)identifier;

-(BOOL) missionControlEnabled;
-(BOOL) replaceAppSwitcherWithMC;
-(BOOL) missionControlKillApps;
-(NSInteger) missionControlDesktopStyle;
-(BOOL) missionControlPagingEnabled;

-(BOOL) isFirstRun;
-(void) setFirstRun:(BOOL)value;

-(BOOL) swipeOverEnabled;
-(BOOL) alwaysShowSOGrabber;

-(BOOL) exitAppAfterUsingActivatorAction;

-(BOOL) quickAccessUseGenericTabLabel;

-(BOOL) windowedMultitaskingEnabled;
-(NSInteger) windowRotationLockMode;
-(ZYGrabArea) windowedMultitaskingGrabArea;
-(ZYGrabArea) swipeOverGrabArea;
-(BOOL) onlyShowWindowBarIconsOnOverlay;

-(NSString*) currentThemeIdentifier;
@end
