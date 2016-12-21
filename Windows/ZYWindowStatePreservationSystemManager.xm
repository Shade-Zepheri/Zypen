#import "ZYWindowStatePreservationSystemManager.h"
#import "ZYDesktopManager.h"
#import "ZYHostedAppView.h"

#define FILE_PATH @"/User/Library/Preferences/com.efrederickson.empoleon.windowstates.plist"

@implementation ZYWindowStatePreservationSystemManager
+(id) sharedInstance
{
	SHARED_INSTANCE2(ZYWindowStatePreservationSystemManager, [sharedInstance loadInfo]);
}

-(void) loadInfo
{
	dict = [NSMutableDictionary dictionaryWithContentsOfFile:FILE_PATH] ?: [NSMutableDictionary dictionary];
}

-(void) saveInfo
{
	[dict writeToFile:FILE_PATH atomically:YES];
}

-(void) saveDesktopInformation:(ZYDesktopWindow*)desktop
{
	NSUInteger index = [ZYDesktopManager.sharedInstance.availableDesktops indexOfObject:desktop];
	NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)index];
	NSMutableArray *openApps = [NSMutableArray array];
	for (ZYHostedAppView *app in desktop.hostedWindows)
	{
		[openApps addObject:app.app.bundleIdentifier];
	}

	dict[key] = openApps;

	[self saveInfo];
}

-(BOOL) hasDesktopInformationAtIndex:(NSInteger)index
{
	NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)index];
	return [dict objectForKey:key] != nil;
}

-(ZYPreservedDesktopInformation) desktopInformationForIndex:(NSInteger)index
{
	ZYPreservedDesktopInformation info;
	info.index = index;
	NSString *key = [NSString stringWithFormat:@"%lu",(unsigned long)index];

	NSMutableArray *apps = [NSMutableArray array];
	for (NSString *ident in dict[key])
		[apps addObject:ident];

	info.openApps = apps;

	return info;
}

// Window
-(void) saveWindowInformation:(ZYWindowBar*)window
{
	CGPoint center = window.center;
	CGAffineTransform transform = window.transform;
	NSString *appIdent = window.attachedView.app.bundleIdentifier;

	dict[appIdent] = @{
		@"center": NSStringFromCGPoint(center),
		@"transform": NSStringFromCGAffineTransform(transform)
	};

	[self saveInfo];
}

-(BOOL) hasWindowInformationForIdentifier:(NSString*)appIdentifier
{
	return [dict objectForKey:appIdentifier] != nil;
}

-(ZYPreservedWindowInformation) windowInformationForAppIdentifier:(NSString*)identifier
{
	ZYPreservedWindowInformation info = (ZYPreservedWindowInformation) { CGPointZero, CGAffineTransformIdentity };

	NSDictionary *appInfo = dict[identifier];
	if (!appInfo)
		return info;

	info.center = CGPointFromString(appInfo[@"center"]);
	info.transform = CGAffineTransformFromString(appInfo[@"transform"]);

	return info;
}

-(void) removeWindowInformationForIdentifier:(NSString*)appIdentifier
{
	[dict removeObjectForKey:appIdentifier];
	[self saveInfo];
}
@end
