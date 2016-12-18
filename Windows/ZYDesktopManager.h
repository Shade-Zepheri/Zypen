#import "ZYDesktopWindow.h"

@interface ZYDesktopManager : NSObject {
	NSMutableArray *windows;
	ZYDesktopWindow *currentDesktop;
	NSUInteger currentDesktopIndex;
}
+(instancetype) sharedInstance;

@property (nonatomic, weak) ZYWindowBar *lastUsedWindow;

-(void) addDesktop:(BOOL)switchTo;
-(void) removeDesktopAtIndex:(NSUInteger)index;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated;
-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force;

-(BOOL) isAppOpened:(NSString*)identifier;
-(ZYWindowBar*) windowForIdentifier:(NSString*)identifier;

-(NSUInteger) currentDesktopIndex;
-(NSUInteger) numberOfDesktops;
-(void) switchToDesktop:(NSUInteger)index;
-(void) switchToDesktop:(NSUInteger)index actuallyShow:(BOOL)show;
-(ZYDesktopWindow*) currentDesktop;
-(NSArray*) availableDesktops;
-(ZYDesktopWindow*) desktopAtIndex:(NSUInteger)index;

-(void) updateWindowSizeForApplication:(NSString*)identifier;
-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation;

-(void) hideDesktop;
-(void) reshowDesktop;

-(void) findNewForemostApp;
@end
