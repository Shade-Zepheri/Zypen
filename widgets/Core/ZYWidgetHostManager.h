#import "headers.h"
#import "ZYWidgetBase.h"

@interface ZYWidgetHostManager : NSObject {
	NSMutableArray *widgets;
}
+ (id)sharedInstance;

- (void)addWidget:(ZYWidgetBase*)widget;
- (void)removeWidget:(ZYWidgetBase*)widget;
- (void)removeWidgetWithIdentifier:(NSString*)identifier;
- (ZYWidgetBase*)widgetForIdentifier:(NSString*)identifier;
@end
