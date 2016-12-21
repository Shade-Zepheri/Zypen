#import "ZYHostedAppView.h"
#import "ZYWindowBar.h"

@interface ZYDesktopWindow : UIWindow {
	UIInterfaceOrientation lastKnownOrientation;
	NSMutableArray *appViews;

	BOOL dontClearForcedPhoneState;
}

-(ZYWindowBar*) addAppWithView:(ZYHostedAppView*)view animated:(BOOL)animated;
-(ZYWindowBar*) createAppWindowForSBApplication:(SBApplication*)app animated:(BOOL)animated;
-(ZYWindowBar*) createAppWindowWithIdentifier:(NSString*)identifier animated:(BOOL)animated;

-(void) addExistingWindow:(ZYWindowBar*)window;
-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated;
-(void) removeAppWithIdentifier:(NSString*)identifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force;

-(NSArray*) hostedWindows;
-(BOOL) isAppOpened:(NSString*)identifier;
-(ZYWindowBar*) windowForIdentifier:(NSString*)identifier;

-(UIInterfaceOrientation) currentOrientation;
-(CGFloat) baseRotationForOrientation;
-(UIInterfaceOrientation) appOrientationRelativeToThisOrientation:(CGFloat)currentRotation;
-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation;

-(void) updateWindowSizeForApplication:(NSString*)identifier;

-(void) unloadApps;
-(void) loadApps;
-(void) closeAllApps;

-(void) saveInfo;
-(void) loadInfo;
-(void) loadInfo:(NSInteger)index;
@end
