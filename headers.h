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

extern "C" CFNotificationCenterRef CFNotificationCenterGetDistributedCenter(void);

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

extern "C" void BKSHIDServicesCancelTouchesOnMainDisplay();

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
