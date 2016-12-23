#import <UIKit/UIKit.h>
#import "ZYWidget.h"

@interface ZYWidgetSection : NSObject {
	NSMutableArray *_widgets;
}

- (BOOL)enabled;

- (NSInteger)sortOrder;
- (BOOL)showTitle;
- (NSString*)displayName;
- (NSString*)identifier;
- (CGFloat)titleOffset;

// The view should cache, if possible, to speed up loading times.
// It should NOT show the title view.
- (UIView*)viewForFrame:(CGRect)frame preferredIconSize:(CGSize)size iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing;

- (void)addWidget:(ZYWidget*)widget;
@end
