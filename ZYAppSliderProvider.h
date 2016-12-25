#import "headers.h"

@class ZYHostedAppView;

@interface ZYAppSliderProvider : NSObject
@property (nonatomic, retain) NSArray *availableIdentifiers;
@property (nonatomic) NSInteger currentIndex;

- (BOOL)canGoLeft;
- (BOOL)canGoRight;

- (ZYHostedAppView*)viewToTheLeft;
- (ZYHostedAppView*)viewToTheRight;
- (ZYHostedAppView*)viewAtCurrentIndex;

- (void)goToTheLeft;
- (void)goToTheRight;
@end
