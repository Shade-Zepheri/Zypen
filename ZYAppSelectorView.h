#import "headers.h"

@class ZYAppSelectorView;

@protocol ZYAppSelectorViewDelegate
- (void)appSelector:(ZYAppSelectorView*)view appWasSelected:(NSString*)bundleIdentifier;
@end

@interface ZYAppSelectorView : UIScrollView
@property (nonatomic, weak) NSObject<ZYAppSelectorViewDelegate> *target;

- (void)relayoutApps;
@end
