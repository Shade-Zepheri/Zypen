#import <libactivator/libactivator.h>
#import "ZYDesktopManager.h"
#import "ZYBackgrounder.h"
#import "Zypen"

@interface ZYActivatorLaunchWindow : NSObject <LAListener>
@end

static ZYActivatorLaunchWindow *sharedInstance;

@implementation ZYActivatorLaunchWindow
- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event {
  NSString *ident = NSBundle.mainBundle.bundleIdentifier;
  SBApplication *app = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:ident];
  ZYIconIndicatorViewInfo indicatorInfo = [[%c(ZYBackgrounder) sharedInstance] allAggregatedIndicatorInfoForIdentifier:ident];

  // Close app
  [[%c(ZYBackgrounder) sharedInstance] temporarilyApplyBackgroundingMode:ZYBackgroundModeForcedForeground forApplication:app andCloseForegroundApp:NO];
  FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
      SBDeactivationSettings *deactiveSets = [[%c(SBDeactivationSettings) alloc] init];
      [deactiveSets setFlag:YES forDeactivationSetting:20];
      [deactiveSets setFlag:NO forDeactivationSetting:2];
      [app _setDeactivationSettings:deactiveSets];

      SBAppToAppWorkspaceTransaction *transaction = [Zypen createSBAppToAppWorkspaceTransactionForExitingApp:topApp];
      [transaction begin];

      // Open in window
      [ZYDesktopManager.sharedInstance.currentDesktop createAppWindowWithIdentifier:ident animated:YES];
  }];
  [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];

  // Pop forced foreground backgrounding
  [[%c(ZYBackgrounder) sharedInstance] queueRemoveTemporaryOverrideForIdentifier:ident];
  [[%c(ZYBackgrounder) sharedInstance] removeTemporaryOverrideForIdentifier:ident];
  [[%c(ZYBackgrounder) sharedInstance] updateIconIndicatorForIdentifier:ident withInfo:indicatorInfo];
}
@end

%ctor {
    if ([NSBundle.mainBundle.bundleIdentifier isEqualToString:@"com.apple.springboard"]) {
        sharedInstance = [[ZYActivatorLaunchWindow alloc] init];
        [[%c(LAActivator) sharedInstance] registerListener:sharedInstance forName:@"com.shade.zypen.empoleon.launchWindow"];
    }
}
