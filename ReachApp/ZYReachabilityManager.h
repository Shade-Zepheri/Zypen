#import "ZYWidget.h"

@class ZYAppSliderProviderView;

@interface ZYReachabilityManager : NSObject
+ (instancetype)sharedInstance;

- (void)launchTopAppWithIdentifier:(NSString*)identifier;
- (void)launchWidget:(ZYWidget*)widget;
- (void)showAppWithSliderProvider:(__weak ZYAppSliderProviderView*)view;

- (void)showWidgetSelector;
@end
