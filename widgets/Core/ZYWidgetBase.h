#import "headers.h"

@interface ZYWidgetBase : UIView
- (NSString*)identifier;
- (NSString*)displayName;

- (void)didAppear;
- (void)didDisappear;
@end
