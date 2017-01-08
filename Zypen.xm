#import "Zypen.h"
#import "ZYCompatibilitySystem.h"
#import "headers.h"

#define SYSTEM_VERSION_EQUAL_TO(v)                  (UIDevice.currentDevice.systemVersion compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              (UIDevice.currentDevice.systemVersion compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  (UIDevice.currentDevice.systemVersion compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 (UIDevice.currentDevice.systemVersion compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     (UIDevice.currentDevice.systemVersion compare:v options:NSNumericSearch] != NSOrderedDescending)

@implementation ZypenExtension
@end

@implementation Zypen
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(Zypen,
		sharedInstance->activeExtensions = [NSMutableArray array]
	);
}

- (NSString*)currentVersion {
  return @"0.7";
}
- (BOOL)isOnSupportedOS {
  return SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0") && SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(@"10.1.1");
}

- (void)registerExtension:(NSString*)name forZypenVersion:(NSString*)version {
	if ([self.currentVersion compare:version options:NSNumericSearch] == NSOrderedDescending) {
		[ZYCompatibilitySystem showWarning:[NSString stringWithFormat:@"Extension %@ was built for Zypen version %@, which is above the current version. Compliancy issues may occur.", name, version]];
	}

	ZypenExtension *ext = [[ZypenExtension alloc] init];
	ext.name = name;
	ext.zypenVersion = version;
	[activeExtensions addObject:ext];
}

+ (id)createSBAppToAppWorkspaceTransactionForExitingApp:(SBApplication*)app {
	if ([%c(SBAppToAppWorkspaceTransaction) respondsToSelector:@selector(initWithAlertManager:exitedApp:)]) {
		return [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:app];
	} else {
	// ** below code from Mirmir (https://github.com/EthanArbuckle/Mirmir/blob/lamo_no_ms/Lamo/CDTLamo.mm#L114-L138)
    SBWorkspaceApplicationTransitionContext *transitionContext = [[%c(SBWorkspaceApplicationTransitionContext) alloc] init];

    //set layout role to 'side' (deactivating)
    SBWorkspaceDeactivatingEntity *deactivatingEntity = [%c(SBWorkspaceDeactivatingEntity) entity];
    [deactivatingEntity setLayoutRole:3];
    [transitionContext setEntity:deactivatingEntity forLayoutRole:2];

    //set layout role for 'primary' (activating)
    SBWorkspaceHomeScreenEntity *homescreenEntity = [[%c(SBWorkspaceHomeScreenEntity) alloc] init];
    [transitionContext setEntity:homescreenEntity forLayoutRole:1];

    [transitionContext setAnimationDisabled:YES];

    //create transititon request
    SBMainWorkspaceTransitionRequest *transitionRequest = [[%c(SBMainWorkspaceTransitionRequest) alloc] initWithDisplay:[UIScreen.mainScreen valueForKey:@"_fbsDisplay"]];
    [transitionRequest setApplicationContext:transitionContext];

    return [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithTransitionRequest:transitionRequest];
    // ** //
    }
}

+ (BOOL)shouldShowControlCenterGrabberOnFirstSwipe {
	if ([%c(SBUIController) respondsToSelector:@selector(shouldShowControlCenterTabControlOnFirstSwipe)]) {
		[[%c(SBUIController) sharedInstance] shouldShowControlCenterTabControlOnFirstSwipe];
	}
	return [[%c(SBControlCenterController) sharedInstance] _shouldShowGrabberOnFirstSwipe];
}
@end
