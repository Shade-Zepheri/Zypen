#import "headers.h"
#import "ZYWindowBar.h"

@interface ZYWindowOverlayView : UIView
@property (nonatomic, weak) ZYWindowBar *appWindow;
-(void) show;
-(void) dismiss;
@end
