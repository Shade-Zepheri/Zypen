#import "ZYAppSwitcherModelWrapper.h"

@implementation ZYAppSwitcherModelWrapper
+ (void)addToFront:(SBApplication*)app {
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
	SBDisplayItem *layout = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:app.bundleIdentifier];
	[model addToFront:layout role:2];
}

+ (void)addIdentifierToFront:(NSString*)ident {
	[ZYAppSwitcherModelWrapper addToFront:[[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:ident]];
}

+ (NSArray*)appSwitcherAppIdentiferList {
	SBAppSwitcherModel *model = [%c(SBAppSwitcherModel) sharedInstance];
	NSMutableArray *ret = [NSMutableArray array];

	id list = [model mainSwitcherDisplayItems]; // NSArray<SBDisplayItem>
	for (SBDisplayItem *item in list) {
		[ret addObject:item.displayIdentifier];
	}
	return ret;
}

+ (void)removeItemWithIdentifier:(NSString*)ident {
  SBDisplayItem *item = [%c(SBDisplayItem) displayItemWithType:@"App" displayIdentifier:ident];
  [[%c(SBAppSwitcherModel) sharedInstance] remove:item];
}
@end
