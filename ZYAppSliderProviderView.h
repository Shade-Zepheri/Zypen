#import "headers.h"
#import "ZYHostedAppView.h"
#import "ZYGestureManager.h"

@class ZYAppSliderProvider;

@interface ZYAppSliderProviderView : UIView<ZYGestureCallbackProtocol> {
	ZYHostedAppView *currentView;
}
@property (nonatomic, retain) ZYAppSliderProvider *swipeProvider;
@property (nonatomic) BOOL isSwipeable;

- (CGRect)clientFrame;
- (NSString*)currentBundleIdentifier;

- (void)goToTheLeft;
- (void)goToTheRight;

- (void)load;
- (void)unload;
- (void)updateCurrentView;
@end
