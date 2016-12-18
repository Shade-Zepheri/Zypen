#import "../headers.h"
#import "../ZYHostedAppView.h"

@class ZYDesktopWindow;

@interface ZYWindowBar : UIView<UIGestureRecognizerDelegate, UIGestureRecognizerDelegate> {
	ZYHostedAppView *attachedView;
}

@property (nonatomic, weak) ZYDesktopWindow *desktop;

-(void) close;
-(void) maximize;
-(void) minimize;
-(void) sizingLockButtonTap:(id)arg1;
-(BOOL) isLocked;

-(void) showOverlay;
-(void) hideOverlay;
-(BOOL) isOverlayShowing;

-(ZYHostedAppView*) attachedView;
-(void) attachView:(ZYHostedAppView*)view;

-(void) updateClientRotation;
-(void) updateClientRotation:(UIInterfaceOrientation)orientation;

-(void) scaleTo:(CGFloat)scale animated:(BOOL)animate;
-(void) scaleTo:(CGFloat)scale animated:(BOOL)animate derotate:(BOOL)derotate;

-(void) saveWindowInfo;

-(void) disableLongPress;
-(void) enableLongPress;

-(void) resignForemostApp;
-(void) becomeForemostApp;
@end
