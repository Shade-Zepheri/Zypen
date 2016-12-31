#import <UIKit/UIKit.h>
#import "ZYRemoteKeyboardView.h"

@interface ZYKeyboardWindow : UIWindow {
	ZYRemoteKeyboardView *kbView;
}

- (void)setupForKeyboardAndShow:(NSString*)identifier;
- (void)removeKeyboard;

- (NSUInteger)contextId;
@end
