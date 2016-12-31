#import "ZYTheme.h"

@interface ZYThemeManager : NSObject {
	NSMutableDictionary *allThemes;
	ZYTheme *currentTheme;
}

+ (instancetype)sharedInstance;

- (ZYTheme*)currentTheme;
- (NSArray*)allThemes;

- (void)invalidateCurrentThemeAndReload:(NSString*)currentIdentifier;
@end
