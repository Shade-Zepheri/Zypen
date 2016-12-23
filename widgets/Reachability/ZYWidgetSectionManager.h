#import <UIKit/UIKit.h>
#import "ZYWidgetSection.h"

@interface ZYWidgetSectionManager : NSObject {
	NSMutableDictionary *_sections;
}

+ (instancetype)sharedInstance;

- (void)registerSection:(ZYWidgetSection*)section;

- (NSArray*)sections;
- (NSArray*)enabledSections;

- (UIView*)createViewForEnabledSectionsWithBaseFrame:(CGRect)frame preferredIconSize:(CGSize)size iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing;
@end
