#import "ZYKeyboardWindow.h"
#import "headers.h"
#import "ZYKeyboardStateListener.h"
#import "ZYDesktopManager.h"

@implementation ZYKeyboardWindow
- (void)setupForKeyboardAndShow:(NSString*)identifier {
	self.userInteractionEnabled = YES;
	self.backgroundColor = UIColor.clearColor;

	if (kbView) {
		[self removeKeyboard];
	}
	kbView = [[ZYRemoteKeyboardView alloc] initWithFrame:UIScreen.mainScreen.bounds];
	[kbView connectToKeyboardWindowForApp:identifier];
	[self addSubview:kbView];

	self.windowLevel = 9999;
	self.frame = UIScreen.mainScreen.bounds;
	[self makeKeyAndVisible];
}

- (void)removeKeyboard {
	[kbView connectToKeyboardWindowForApp:nil];
	[kbView removeFromSuperview];
	kbView = nil;
}

- (NSUInteger)contextId {
	return kbView.layerHost.contextId;
}

@end
