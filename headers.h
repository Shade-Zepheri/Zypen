#import <SpringBoard/SpringBoard.h>
#import <SpringBoard/SBIconModel.h>
#import <SpringBoard/SBIcon.h>
#import <SpringBoard/SBIconController.h>
#import <SpringBoard/SBApplicationIcon.h>
#import <UIKit/UIImage.h>
#import <UIKit/UIImageView.h>
#import <SpringBoard/SBIconLabel.h>
#import <SpringBoard/SBApplication.h>
#import <QuartzCore/QuartzCore.h>
#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#include <mach/mach.h>
#include <libkern/OSCacheControl.h>
#include <stdbool.h>
#include <dlfcn.h>
#include <sys/sysctl.h>
#import <notify.h>
#import <IOKit/hid/IOHIDEvent.h>
#import <GraphicsServices/GraphicsServices.h>

#define ZY_BASE_PATH @"/Library/Zypen"

#import "ZYSBWorkspaceFetcher.h"
#define GET_SBWORKSPACE [ZYSBWorkspaceFetcher getCurrentSBWorkspaceImplementationInstanceForThisOS]

#define GET_STATUSBAR_ORIENTATION (UIApplication.sharedApplication._accessibilityFrontMostApplication == nil ? UIApplication.sharedApplication.statusBarOrientation : UIApplication.sharedApplication._accessibilityFrontMostApplication.statusBarOrientation)

#if ZYPEN_CORE
extern BOOL $__IS_SPRINGBOARD;
#define IS_SPRINGBOARD $__IS_SPRINGBOARD
#else
#define IS_SPRINGBOARD [NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"]
#endif

#define ON_MAIN_THREAD(block) \
    { \
        dispatch_block_t _blk = block; \
        if (NSThread.isMainThread) \
            _blk(); \
        else \
            dispatch_sync(dispatch_get_main_queue(), _blk); \
    }

#define IF_SPRINGBOARD if (IS_SPRINGBOARD)
#define IF_NOT_SPRINGBOARD if (!IS_SPRINGBOARD)
#define IF_THIS_PROCESS(x) if ([[x objectForKey:@"bundleIdentifier"] isEqual:NSBundle.mainBundle.bundleIdentifier])

// ugh, i got so tired of typing this in by hand, plus it expands method declarations by a LOT.
#define unsafe_id __unsafe_unretained id

#define kBGModeUnboundedTaskCompletion @"unboundedTaskCompletion"
#define kBGModeContinuous              @"continuous"
#define kBGModeFetch                   @"fetch"
#define kBGModeRemoteNotification      @"remote-notification"
#define kBGModeExternalAccessory       @"external-accessory"
#define kBGModeVoIP                    @"voip"
#define kBGModeLocation                @"location"
#define kBGModeAudio                   @"audio"
#define kBGModeBluetoothCentral        @"bluetooth-central"
#define kBGModeBluetoothPeripheral     @"bluetooth-peripheral"
// newsstand-content

//extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(radians) ((radians) * (M_PI / 180))

void SET_BACKGROUNDED(id settings, BOOL val);

#define SHARED_INSTANCE2(cls, extracode) \
static cls *sharedInstance = nil; \
static dispatch_once_t onceToken = 0; \
dispatch_once(&onceToken, ^{ \
    sharedInstance = [[cls alloc] init]; \
    extracode; \
}); \
return sharedInstance;

#define SHARED_INSTANCE(cls) SHARED_INSTANCE2(cls, );

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

//extern "C" void BKSHIDServicesCancelTouchesOnMainDisplay();

@interface SBAppSwitcherModel : NSObject
+(id)sharedInstance;
-(id)mainSwitcherDisplayItems;
-(id)commandTabDisplayItems;
-(void)addToFront:(id)arg1 role:(long long)arg2 ;
-(id)_recentsFromPrefs;
-(id)_displayItemRolesFromPrefsForLoadedDisplayItems:(id)arg1 ;
-(void)_saveRecents;
-(void)_appActivationStateDidChange:(id)arg1 ;
-(void)_warmUpRecentIcons;
-(id)initWithUserDefaults:(id)arg1 andIconController:(id)arg2 ;
-(id)_recentsFromLegacyPrefs;
-(void)_warmUpIconForDisplayItem:(id)arg1 ;
-(void)_pruneRoles;
-(id)displayItemsForAppsOfRoles:(id)arg1 ;
-(void)dealloc;
-(id)init;
-(void)remove:(id)arg1 ;
@end

@interface SBAppSwitcherModel ()
+(id)sharedInstance;
-(id)mainSwitcherDisplayItems;
-(id)commandTabDisplayItems;
-(void)addToFront:(id)arg1 role:(long long)arg2 ;
-(id)_recentsFromPrefs;
-(id)_displayItemRolesFromPrefsForLoadedDisplayItems:(id)arg1 ;
-(void)_saveRecents;
-(void)_appActivationStateDidChange:(id)arg1 ;
-(void)_warmUpRecentIcons;
-(id)initWithUserDefaults:(id)arg1 andIconController:(id)arg2 ;
-(id)_recentsFromLegacyPrefs;
-(void)_warmUpIconForDisplayItem:(id)arg1 ;
-(void)_pruneRoles;
-(id)displayItemsForAppsOfRoles:(id)arg1 ;
-(void)dealloc;
-(id)init;
-(void)remove:(id)arg1 ;
@end

@interface SBDeactivationSettings
-(id)init;
-(void)setFlag:(int)flag forDeactivationSetting:(unsigned)deactivationSetting;
@end

@interface SBApplication ()
-(void) _setDeactivationSettings:(SBDeactivationSettings*)arg1;
-(void) clearDeactivationSettings;
-(FBScene*) mainScene;
-(id) mainScreenContextHostManager;
-(id) mainSceneID;
- (void)activate;

- (void)processDidLaunch:(id)arg1;
- (void)processWillLaunch:(id)arg1;
- (void)resumeForContentAvailable;
- (void)resumeToQuit;
- (void)_sendDidLaunchNotification:(_Bool)arg1;
- (void)notifyResumeActiveForReason:(long long)arg1;

@property(readwrite, nonatomic) int pid;
@end

@interface SBApplicationController : NSObject
+(id) sharedInstance;
-(SBApplication*) applicationWithBundleIdentifier:(NSString*)identifier;
-(SBApplication*) applicationWithDisplayIdentifier:(NSString*)identifier;
-(SBApplication*)applicationWithPid:(int)arg1;
-(SBApplication*) ZY_applicationWithBundleIdentifier:(NSString*)bundleIdentifier;
@end

@interface SBDisplayItem : NSObject
@property (nonatomic,copy,readonly) NSString * type;                           //@synthesize type=_type - In the implementation block
@property (nonatomic,copy,readonly) NSString * displayIdentifier;              //@synthesize displayIdentifier=_displayIdentifier - In the implementation block
+(id)displayItemWithType:(NSString*)arg1 displayIdentifier:(id)arg2 ;
+(id)homeScreenDisplayItem;
+(id)sideSwitcherDisplayItem;
-(id)initWithType:(NSString*)arg1 displayIdentifier:(id)arg2 ;
-(id)uniqueStringRepresentation;
-(id)_calculateUniqueStringRepresentation;
-(BOOL)isHomeScreenDisplayItem;
-(BOOL)isSideSwitcherDisplayItem;
-(id)init;
-(BOOL)isEqual:(id)arg1 ;
-(unsigned long long)hash;
-(id)description;
-(NSString *)displayIdentifier;
-(NSString *)type;
-(id)copyWithZone:(NSZone*)arg1 ;
@end

@interface FBWindowContextHostManager
- (id)hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (void)resumeContextHosting;
- (id)_hostViewForRequester:(id)arg1 enableAndOrderFront:(BOOL)arg2;
- (id)snapshotViewWithFrame:(CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3;
- (id)snapshotUIImageForFrame:(struct CGRect)arg1 excludingContexts:(id)arg2 opaque:(BOOL)arg3 outTransform:(struct CGAffineTransform *)arg4;
- (id)visibleContexts;
- (void)orderRequesterFront:(id)arg1;
- (void)enableHostingForRequester:(id)arg1 orderFront:(BOOL)arg2;
- (void)enableHostingForRequester:(id)arg1 priority:(int)arg2;
- (void)disableHostingForRequester:(id)arg1;
- (void)_updateHostViewFrameForRequester:(id)arg1;
- (void)invalidate;

@property(copy, nonatomic) NSString *identifier; // @synthesize identifier=_identifier;
@end

@interface FBWindowContextHostView : UIView
@end

@interface FBProcess : NSObject
@end

@interface FBSSceneSettings : NSObject <NSCopying, NSMutableCopying>
{
    CGRect _frame;
    CGPoint _contentOffset;
    float _level;
    int _interfaceOrientation;
    BOOL _backgrounded;
    BOOL _occluded;
    BOOL _occludedHasBeenCalculated;
    NSSet *_ignoreOcclusionReasons;
    NSArray *_occlusions;
    //BSSettings *_otherSettings;
    //BSSettings *_transientLocalSettings;
}

+ (BOOL)_isMutable;
+ (id)settings;
@property(readonly, copy, nonatomic) NSArray *occlusions; // @synthesize occlusions=_occlusions;
@property(readonly, nonatomic, getter=isBackgrounded) BOOL backgrounded; // @synthesize backgrounded=_backgrounded;
@property(readonly, nonatomic) int interfaceOrientation; // @synthesize interfaceOrientation=_interfaceOrientation;
@property(readonly, nonatomic) float level; // @synthesize level=_level;
@property(readonly, nonatomic) CGPoint contentOffset; // @synthesize contentOffset=_contentOffset;
@property(readonly, nonatomic) CGRect frame; // @synthesize frame=_frame;
- (id)valueDescriptionForFlag:(int)arg1 object:(id)arg2 ofSetting:(unsigned int)arg3;
- (id)keyDescriptionForSetting:(unsigned int)arg1;
- (id)description;
- (BOOL)isEqual:(id)arg1;
- (unsigned int)hash;
- (id)_descriptionOfSettingsWithMultilinePrefix:(id)arg1;
- (id)transientLocalSettings;
- (BOOL)isIgnoringOcclusions;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
- (BOOL)isOccluded;
- (CGRect)bounds;
- (void)dealloc;
- (id)init;
- (id)initWithSettings:(id)arg1;
@end

@interface FBSMutableSceneSettings : FBSSceneSettings
{
}

+ (BOOL)_isMutable;
- (id)mutableCopyWithZone:(struct _NSZone *)arg1;
- (id)copyWithZone:(struct _NSZone *)arg1;
@property(copy, nonatomic) NSArray *occlusions;
- (id)transientLocalSettings;
- (id)ignoreOcclusionReasons;
- (id)otherSettings;
@property(nonatomic, getter=isBackgrounded) BOOL backgrounded;
@property(nonatomic) int interfaceOrientation;
@property(nonatomic) float level;
@property(nonatomic) struct CGPoint contentOffset;
@property(nonatomic) struct CGRect frame;
@end

@interface FBScene
-(FBWindowContextHostManager*) contextHostManager;
@property(readonly, retain, nonatomic) FBSMutableSceneSettings *mutableSettings; // @synthesize mutableSettings=_mutableSettings;
- (void)updateSettings:(id)arg1 withTransitionContext:(id)arg2;
- (void)_applyMutableSettings:(id)arg1 withTransitionContext:(id)arg2 completion:(id)arg3;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly, retain) FBProcess *clientProcess;
@end

@interface FBWindowContextHostWrapperView : UIView
@property(readonly, nonatomic) FBWindowContextHostManager *manager; // @synthesize manager=_manager;
@property(nonatomic) unsigned int appearanceStyle; // @synthesize appearanceStyle=_appearanceStyle;
- (void)_setAppearanceStyle:(unsigned int)arg1 force:(BOOL)arg2;
- (id)_stringForAppearanceStyle;
- (id)window;
@property(readonly, nonatomic) struct CGRect referenceFrame; // @dynamic referenceFrame;
@property(readonly, nonatomic, getter=isContextHosted) BOOL contextHosted; // @dynamic contextHosted;
- (void)clearManager;
- (void)_hostingStatusChanged;
- (BOOL)_isReallyHosting;
- (void)updateFrame;

@property(retain, nonatomic) UIColor *backgroundColorWhileNotHosting;
@property(retain, nonatomic) UIColor *backgroundColorWhileHosting;
@end

@interface SBReachabilityManager : NSObject {

	NSHashTable* _observers;
	BOOL _reachabilityModeActive;
	unsigned long long _reachabilityExtensionGenerationCount;
	BOOL _reachabilityModeEnabled;
	NSMutableSet* _temporaryDisabledReasons;
}

@property (nonatomic,readonly) BOOL reachabilityModeActive;              //@synthesize reachabilityModeActive=_reachabilityModeActive - In the implementation block
@property (assign,nonatomic) BOOL reachabilityEnabled;
@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;
@property (copy,readonly) NSString * description;
@property (copy,readonly) NSString * debugDescription;
+(BOOL)reachabilitySupported;
+(id)sharedInstance;
-(void)_handleReachabilityActivated;
-(void)_handleReachabilityDeactivated;
-(void)_handleSignificantTimeChanged;
-(void)cancelPendingReachabilityRequests;
-(void)deactivateReachabilityModeForObserver:(id)arg1 ;
-(void)_pingKeepAliveWithDuration:(double)arg1 interactedBeforePing:(BOOL)arg2 initialKeepAliveTime:(double)arg3 ;
-(void)_toggleReachabilityModeWithRequestingObserver:(id)arg1 ;
-(void)triggerDidTriggerReachability:(id)arg1 ;
-(BOOL)reachabilityEnabled;
-(void)setReachabilityEnabled:(BOOL)arg1 ;
-(void)setReachabilityTemporarilyDisabled:(BOOL)arg1 forReason:(id)arg2 ;
-(BOOL)reachabilityModeActive;
-(void)dealloc;
-(id)init;
-(void)addObserver:(id)arg1 ;
-(void)removeObserver:(id)arg1 ;
-(void)_notifyObserversReachabilityModeActive:(BOOL)arg1 excludingObserver:(id)arg2 ;
-(void)_setKeepAliveTimer;
-(void)_updateReachabilityModeActive:(BOOL)arg1 withRequestingObserver:(id)arg2 ;
@end

@interface FBProcessManager : NSObject {

	NSHashTable* _observers;
	NSMapTable* _processesByPID;
	NSMapTable* _processesByBundleID;
	NSMutableDictionary* _workspacesByClientIdentity;
	int _workspaceLocked;
	int _workspaceLockedToken;

}

@property (readonly) unsigned long long hash;
@property (readonly) Class superclass;
@property (copy,readonly) NSString * description;
@property (copy,readonly) NSString * debugDescription;
+(id)sharedInstance;
-(void)dealloc;
-(id)init;
-(NSString *)description;
-(void)addObserver:(id)arg1 ;
-(void)removeObserver:(id)arg1 ;
-(BOOL)ping;
-(id)applicationProcessForPID:(int)arg1 ;
-(id)applicationProcessesForBundleIdentifier:(id)arg1 ;
-(void)_setPreferredForegroundApplicationProcess:(id)arg1 ;
-(id)allApplicationProcesses;
-(id)_systemServiceClientAdded:(id)arg1 ;
-(void)noteProcess:(id)arg1 didUpdateState:(id)arg2 ;
-(void)noteProcessDidExit:(id)arg1 ;
-(id)processForPID:(int)arg1 ;
-(id)_serviceClientAddedWithConnection:(id)arg1 ;
-(void)applicationProcessWillLaunch:(id)arg1 ;
-(BOOL)_isWorkspaceLocked;
-(id)workspaceForSceneClientWithIdentity:(id)arg1 ;
-(void)_updateWorkspaceLockedState;
-(id)_processesQueue_processesForBundleIdentifier:(id)arg1 ;
-(id)processesForBundleIdentifier:(id)arg1 ;
-(id)_processesQueue_processForPID:(int)arg1 ;
-(void)_queue_evaluateForegroundEventRouting;
-(id)createApplicationProcessForBundleID:(id)arg1 withExecutionContext:(id)arg2 ;
-(void)_queue_addProcess:(id)arg1 completion:(/*^block*/id)arg2 ;
-(id)_serviceClientAddedWithPID:(int)arg1 isUIApp:(BOOL)arg2 isExtension:(BOOL)arg3 bundleID:(id)arg4 ;
-(void)_queue_removeProcess:(id)arg1 withBundleID:(id)arg2 pid:(int)arg3 ;
-(void)_queue_notifyObserversUsingBlock:(/*^block*/id)arg1 completion:(/*^block*/id)arg2 ;
-(void)invalidateClientWorkspace:(id)arg1 ;
-(id)currentProcess;
-(id)allProcesses;
-(id)createApplicationProcessForBundleID:(id)arg1 ;
@end

@interface UIApplication ()
- (void)_handleKeyUIEvent:(id)arg1;
-(UIStatusBar*) statusBar;
- (id)_mainScene;
- (BOOL)_isSupportedOrientation:(int)arg1;

// SpringBoard methods
-(BOOL)launchApplicationWithIdentifier:(id)identifier suspended:(BOOL)suspended;
-(SBApplication*) _accessibilityFrontMostApplication;
-(void)setWantsOrientationEvents:(BOOL)events;
-(void)_relaunchSpringBoardNow;

- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(id)arg2 changeApplicationFlag:(BOOL)arg3;

-(void) ZY_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting;
-(void) ZY_forceStatusBarVisibility:(BOOL)visible orRevert:(BOOL)revert;
-(void) ZY_updateWindowsForSizeChange:(CGSize)size isReverting:(BOOL)revert;

- (void)applicationDidResume;
- (void)_sendWillEnterForegroundCallbacks;
- (void)suspend;
- (void)applicationWillSuspend;
- (void)_setSuspended:(BOOL)arg1;
- (void)applicationSuspend;
- (void)_deactivateForReason:(int)arg1 notify:(BOOL)arg2;
@end

@interface SBWorkspace : NSObject
+(id) sharedInstance;
-(BOOL) isUsingReachApp;
- (void)_exitReachabilityModeWithCompletion:(id)arg1;
- (void)_disableReachabilityImmediately:(_Bool)arg1;
- (void)handleReachabilityModeDeactivated;
-(void) ZY_animateWidgetSelectorOut:(id)completion;
-(void) ZY_setView:(UIView*)view preferredHeight:(CGFloat)preferredHeight;
-(void) ZY_launchTopAppWithIdentifier:(NSString*) bundleIdentifier;
-(void) ZY_showWidgetSelector;
-(void) updateViewSizes:(CGPoint)center animate:(BOOL)animate;
-(void) ZY_closeCurrentView;
-(void) ZY_handleLongPress:(UILongPressGestureRecognizer*)gesture;
-(void) ZY_updateViewSizes;
-(void) appViewItemTap:(id)sender;
@end

@interface SBAppSwitcherSnapshotView : UIView
- (void)setOrientation:(long long)arg1 orientationBehavior:(int)arg2;
- (void)_loadSnapshotAsync;
- (void)_loadZoomUpSnapshotSync;
- (void)_loadSnapshotSync;
- (id)initWithDisplayItem:(id)arg1 application:(id)arg2 orientation:(long long)arg3 preferringDownscaledSnapshot:(_Bool)arg4 async:(_Bool)arg5 withQueue:(id)arg6;
@end

@interface SBUIController : NSObject
+(id) sharedInstance;
+ (id)_zoomViewWithSplashboardLaunchImageForApplication:(id)arg1 sceneID:(id)arg2 screen:(id)arg3 interfaceOrientation:(long long)arg4 includeStatusBar:(_Bool)arg5 snapshotFrame:(struct CGRect *)arg6;
-(id) switcherController;
- (id)_appSwitcherController;
-(void) activateApplicationAnimated:(SBApplication*)app;
- (id)switcherWindow;
- (void)_animateStatusBarForSuspendGesture;
- (void)_showControlCenterGestureCancelled;
- (void)_showControlCenterGestureFailed;
- (void)_hideControlCenterGrabber;
- (void)_showControlCenterGestureEndedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2;
- (void)_showControlCenterGestureChangedWithLocation:(CGPoint)arg1 velocity:(CGPoint)arg2 duration:(CGFloat)arg3;
- (void)_showControlCenterGestureBeganWithLocation:(CGPoint)arg1;
- (void)restoreContentUpdatingStatusBar:(_Bool)arg1;
-(void) restoreContentAndUnscatterIconsAnimated:(BOOL)arg1;
- (_Bool)shouldShowControlCenterTabControlOnFirstSwipe;- (_Bool)isAppSwitcherShowing;
-(BOOL) _activateAppSwitcher;
- (void)_releaseTransitionOrientationLock;
- (void)_releaseSystemGestureOrientationLock;
- (void)releaseSwitcherOrientationLock;
- (void)_lockOrientationForSwitcher;
- (void)_lockOrientationForSystemGesture;
- (void)_lockOrientationForTransition;
- (void)_dismissSwitcherAnimated:(_Bool)arg1;
- (void)dismissSwitcherAnimated:(_Bool)arg1;
- (void)_dismissAppSwitcherImmediately;
- (void)dismissSwitcherForAlert:(id)arg1;

- (void)activateApplication:(id)arg1;
@end

@interface SBWallpaperController
+(id) sharedInstance;
-(void) beginRequiringWithReason:(NSString*)reason;
-(void) endRequiringWithReason:(NSString*)reason;
@end

@interface UIScreen (Wut)
- (CGRect)_referenceBounds;
- (CGPoint)convertPoint:(CGPoint)arg1 toCoordinateSpace:(id)arg2;
+ (CGPoint)convertPoint:(CGPoint)arg1 toView:(id)arg2;

-(CGRect)_interfaceOrientedBounds; // ios 8
-(CGRect)ZY_interfaceOrientedBounds; // ios 8 + 9 (wrapper)
@end

@interface UIWindow ()
-(void)_setRotatableViewOrientation:(long long)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 force:(BOOL)arg4;
@end

@protocol SBIconViewDelegate, SBIconViewLocker;
@class SBIconImageContainerView, SBIconBadgeImage;

@interface SBIconImageView : UIView
{
    UIImageView *_overlayView;
    //SBIconProgressView *_progressView;
    _Bool _isPaused;
    UIImage *_cachedSquareContentsImage;
    _Bool _showsSquareCorners;
    SBIcon *_icon;
    double _brightness;
    double _overlayAlpha;
}

+ (id)dequeueRecycledIconImageViewOfClass:(Class)arg1;
+ (void)recycleIconImageView:(id)arg1;
+ (double)cornerRadius;
@property(nonatomic) _Bool showsSquareCorners; // @synthesize showsSquareCorners=_showsSquareCorners;
@property(nonatomic) double overlayAlpha; // @synthesize overlayAlpha=_overlayAlpha;
@property(nonatomic) double brightness; // @synthesize brightness=_brightness;
@property(retain, nonatomic) SBIcon *icon; // @synthesize icon=_icon;
- (_Bool)_shouldAnimatePropertyWithKey:(id)arg1;
- (void)iconImageDidUpdate:(id)arg1;
- (struct CGRect)visibleBounds;
- (struct CGSize)sizeThatFits:(struct CGSize)arg1;
- (id)squareDarkeningOverlayImage;
- (id)darkeningOverlayImage;
- (id)squareContentsImage;
- (UIImage*)contentsImage;
- (void)_clearCachedImages;
- (id)_generateSquareContentsImage;
- (void)_updateProgressMask;
- (void)_updateOverlayImage;
- (id)_currentOverlayImage;
- (void)updateImageAnimated:(_Bool)arg1;
- (id)snapshot;
- (void)prepareForReuse;
- (void)layoutSubviews;
- (void)setPaused:(_Bool)arg1;
- (void)setProgressAlpha:(double)arg1;
- (void)_clearProgressView;
- (void)progressViewCanBeRemoved:(id)arg1;
- (void)setProgressState:(long long)arg1 paused:(_Bool)arg2 percent:(double)arg3 animated:(_Bool)arg4;
- (void)_updateOverlayAlpha;
- (void)setIcon:(id)arg1 animated:(_Bool)arg2;
- (void)dealloc;
- (id)initWithFrame:(struct CGRect)arg1;
@end

@interface SBIconView : UIView {
	SBIcon *_icon;
	id<SBIconViewDelegate> _delegate;
	id<SBIconViewLocker> _locker;
	SBIconImageContainerView *_iconImageContainer;
	SBIconImageView *_iconImageView;
	UIImageView *_iconDarkeningOverlay;
	UIImageView *_ghostlyImageView;
	UIImageView *_reflection;
	UIImageView *_shadow;
	SBIconBadgeImage *_badgeImage;
	UIImageView *_badgeView;
	SBIconLabel *_label;
	BOOL _labelHidden;
	BOOL _labelOnWallpaper;
	UIView *_closeBox;
	int _closeBoxType;
	UIImageView *_dropGlow;
	unsigned _drawsLabel : 1;
	unsigned _isHidden : 1;
	unsigned _isGrabbed : 1;
	unsigned _isOverlapping : 1;
	unsigned _refusesRecipientStatus : 1;
	unsigned _highlighted : 1;
	unsigned _launchDisabled : 1;
	unsigned _isJittering : 1;
	unsigned _allowJitter : 1;
	unsigned _touchDownInIcon : 1;
	unsigned _hideShadow : 1;
	NSTimer *_delayedUnhighlightTimer;
	unsigned _onWallpaper : 1;
	unsigned _ghostlyRequesters;
	int _iconLocation;
	float _iconImageAlpha;
	float _iconImageBrightness;
	float _iconLabelAlpha;
	float _accessoryAlpha;
	CGPoint _unjitterPoint;
	CGPoint _grabPoint;
	NSTimer *_longPressTimer;
	unsigned _ghostlyTag;
	UIImage *_ghostlyImage;
	BOOL _ghostlyPending;
}


-(void) ZY_updateIndicatorView:(NSInteger)info;
-(void) ZY_updateIndicatorViewWithExistingInfo;
-(BOOL) ZY_isIconIndicatorInhibited;
-(void) ZY_setIsIconIndicatorInhibited:(BOOL)value;
-(void) ZY_setIsIconIndicatorInhibited:(BOOL)value showAgainImmediately:(BOOL)value2;

+ (CGSize)defaultIconSize;
+ (CGSize)defaultIconImageSize;
+ (BOOL)allowsRecycling;
+ (id)_jitterPositionAnimation;
+ (id)_jitterTransformAnimation;
+ (struct CGSize)defaultIconImageSize;
+ (struct CGSize)defaultIconSize;

- (id)initWithDefaultSize;
- (void)dealloc;

@property(assign) id<SBIconViewDelegate> delegate;
@property(assign) id<SBIconViewLocker> locker;
@property(readonly, retain) SBIcon *icon;
- (void)setIcon:(SBIcon *)icon;

- (int)location;
- (void)setLocation:(int)location;
- (void)showIconAnimationDidStop:(id)showIconAnimation didFinish:(id)finish icon:(id)icon;
- (void)setIsHidden:(BOOL)hidden animate:(BOOL)animate;
- (BOOL)isHidden;
- (BOOL)isRevealable;
- (void)positionIconImageView;
- (void)applyIconImageTransform:(CATransform3D)transform duration:(float)duration delay:(float)delay;
- (void)setDisplayedIconImage:(id)image;
- (id)snapshotSettings;
- (id)iconImageSnapshot:(id)snapshot;
- (id)reflectedIconWithBrightness:(CGFloat)brightness;
- (void)setIconImageAlpha:(CGFloat)alpha;
- (void)setIconLabelAlpha:(CGFloat)alpha;
- (SBIconImageView *)iconImageView;
- (void)setLabelHidden:(BOOL)hidden;
- (void)positionLabel;
- (CGSize)_labelSize;
- (Class)_labelClass;
- (void)updateLabel;
- (void)_updateBadgePosition;
- (id)_overriddenBadgeTextForText:(id)text;
- (void)updateBadge;
- (id)_automationID;
- (BOOL)pointMostlyInside:(CGPoint)inside withEvent:(UIEvent *)event;
- (CGRect)frameForIconOverlay;
- (void)placeIconOverlayView;
- (void)updateIconOverlayView;
- (void)_updateIconBrightness;
- (BOOL)allowsTapWhileEditing;
- (BOOL)delaysUnhighlightWhenTapped;
- (BOOL)isHighlighted;
- (void)setHighlighted:(BOOL)highlighted;
- (void)setHighlighted:(BOOL)highlighted delayUnhighlight:(BOOL)unhighlight;
- (void)_delayedUnhighlight;
- (BOOL)isInDock;
- (id)_shadowImage;
- (void)_updateShadow;
- (void)updateReflection;
- (void)setDisplaysOnWallpaper:(BOOL)wallpaper;
- (void)setLabelDisplaysOnWallpaper:(BOOL)wallpaper;
- (BOOL)showsReflection;
- (float)_reflectionImageOffset;
- (void)setFrame:(CGRect)frame;
- (void)setIsJittering:(BOOL)isJittering;
- (void)setAllowJitter:(BOOL)allowJitter;
- (BOOL)allowJitter;
- (void)removeAllIconAnimations;
- (void)setIconPosition:(CGPoint)position;
- (void)setRefusesRecipientStatus:(BOOL)status;
- (BOOL)canReceiveGrabbedIcon:(id)icon;
- (double)grabDurationForEvent:(id)event;
- (void)setIsGrabbed:(BOOL)grabbed;
- (BOOL)isGrabbed;
- (void)setIsOverlapping:(BOOL)overlapping;
- (CGAffineTransform)transformToMakeDropGlowShrinkToIconSize;
- (void)prepareDropGlow;
- (void)showDropGlow:(BOOL)glow;
- (void)removeDropGlow;
- (id)dropGlow;
- (BOOL)isShowingDropGlow;
- (void)placeGhostlyImageView;
- (id)_genGhostlyImage:(id)image;
- (void)prepareGhostlyImageIfNeeded;
- (void)prepareGhostlyImage;
- (void)prepareGhostlyImageView;
- (void)setGhostly:(BOOL)ghostly requester:(int)requester;
- (void)setPartialGhostly:(float)ghostly requester:(int)requester;
- (void)removeGhostlyImageView;
- (BOOL)isGhostly;
- (int)ghostlyRequesters;
- (void)longPressTimerFired;
- (void)cancelLongPressTimer;
- (void)touchesCancelled:(id)cancelled withEvent:(id)event;
- (void)touchesBegan:(id)began withEvent:(id)event;
- (void)touchesMoved:(id)moved withEvent:(id)event;
- (void)touchesEnded:(id)ended withEvent:(id)event;
- (BOOL)isTouchDownInIcon;
- (void)setTouchDownInIcon:(BOOL)icon;
- (void)hideCloseBoxAnimationDidStop:(id)hideCloseBoxAnimation didFinish:(id)finish closeBox:(id)box;
- (void)positionCloseBoxOfType:(int)type;
- (id)_newCloseBoxOfType:(int)type;
- (void)setShowsCloseBox:(BOOL)box;
- (void)setShowsCloseBox:(BOOL)box animated:(BOOL)animated;
- (BOOL)isShowingCloseBox;
- (void)closeBoxTapped;
- (BOOL)pointInside:(CGPoint)inside withEvent:(id)event;
- (UIEdgeInsets)snapshotEdgeInsets;
- (void)setShadowsHidden:(BOOL)hidden;
- (void)_updateShadowFrameForShadow:(id)shadow;
- (void)_updateShadowFrame;
- (BOOL)_delegatePositionIsEditable;
- (void)_delegateTouchEnded:(BOOL)ended;
- (BOOL)_delegateTapAllowed;
- (int)_delegateCloseBoxType;
- (id)createShadowImageView;
- (void)prepareForRecycling;
- (CGRect)defaultFrameForProgressBar;
- (void)iconImageDidUpdate:(id)iconImage;
- (void)iconAccessoriesDidUpdate:(id)iconAccessories;
- (void)iconLaunchEnabledDidChange:(id)iconLaunchEnabled;
- (SBIconImageView*)_iconImageView;

@end
