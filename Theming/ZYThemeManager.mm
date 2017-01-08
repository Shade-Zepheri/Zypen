#import "ZYThemeManager.h"
#import "ZYThemeLoader.h"
#import "ZYSettings.h"
#import "headers.h"

@implementation ZYThemeManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(ZYThemeManager,
		[sharedInstance invalidateCurrentThemeAndReload:nil]
	); // will be reloaded by ZYSettings
}

- (ZYTheme*)currentTheme {
	return currentTheme;
}

- (NSArray*)allThemes {
	return allThemes.allValues;
}

- (void)invalidateCurrentThemeAndReload:(NSString*)currentIdentifier {
	currentTheme = nil;
	[allThemes removeAllObjects];
	allThemes = [NSMutableDictionary dictionary];

	NSString *folderName = [NSString stringWithFormat:@"%@/Themes/", ZY_BASE_PATH];
	NSArray *themeFileNames = [NSFileManager.defaultManager subpathsAtPath:folderName];

	for (NSString *themeName in themeFileNames) {
		if ([themeName hasSuffix:@"plist"] == NO) {
			continue;
		}
		ZYTheme *theme = [ZYThemeLoader loadFromFile:themeName];
		if (theme && theme.themeIdentifier) {
			//HBLogDebug(@"[ReachApp] adding %@", theme.themeIdentifier);
			allThemes[theme.themeIdentifier] = theme;

			if ([theme.themeIdentifier isEqual:currentIdentifier])
				currentTheme = theme;
		}
	}
	if (!currentTheme) {
		currentTheme = [allThemes objectForKey:@"com.shade.zypen.themes.default"];
		if (!currentTheme && allThemes.allKeys.count > 0) {
			currentTheme = allThemes[allThemes.allKeys[0]];
		}
	}
}

@end
