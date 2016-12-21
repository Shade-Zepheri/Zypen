#import "ZYDesktopManager.h"
//#import "ZYMissionControlWindow.h"
#import "ZYWindowBar.h"

BOOL overrideUIWindow = NO;

@implementation ZYDesktopManager
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(ZYDesktopManager,
		sharedInstance->windows = [NSMutableArray array];
		[sharedInstance addDesktop:YES];
		overrideUIWindow = YES;
	);
}

-(void) addDesktop:(BOOL)switchTo
{
	ZYDesktopWindow *desktopWindow = [[ZYDesktopWindow alloc] initWithFrame:UIScreen.mainScreen._referenceBounds];

	[windows addObject:desktopWindow];
	if (switchTo)
		[self switchToDesktop:windows.count - 1];
	[desktopWindow loadInfo:[windows indexOfObject:desktopWindow]];
}

-(void) removeDesktopAtIndex:(NSUInteger)index
{
	if (windows.count == 1 && index == 0)
		return;

	if (currentDesktopIndex == index)
		[self switchToDesktop:0];

	ZYDesktopWindow *window = windows[index];
	[window saveInfo];
	[window closeAllApps];
	[windows removeObjectAtIndex:index];
}

-(BOOL) isAppOpened:(NSString*)identifier
{
	for (ZYDesktopWindow *desktop in windows)
		if ([desktop isAppOpened:identifier])
			return YES;
	return NO;
}

-(NSUInteger) numberOfDesktops
{
	return windows.count;
}

-(void) switchToDesktop:(NSUInteger)index
{
	[self switchToDesktop:index actuallyShow:YES];
}

-(void) switchToDesktop:(NSUInteger)index actuallyShow:(BOOL)show
{
	ZYDesktopWindow *newDesktop = windows[index];

	currentDesktop.hidden = YES;

	[currentDesktop unloadApps];
	[newDesktop loadApps];

	if (show == NO)
		newDesktop.hidden = YES;
	overrideUIWindow = NO;
	[newDesktop makeKeyAndVisible];
	overrideUIWindow = YES;
	if (show == NO)
		newDesktop.hidden = YES;

	currentDesktopIndex = index;
	currentDesktop = newDesktop;
	//[newDesktop updateForOrientation:UIApplication.sharedApplication.statusBarOrientation];
}

-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated
{
	[self removeAppWithIdentifier:bundleIdentifier animated:animated forceImmediateUnload:NO];
}

-(void) removeAppWithIdentifier:(NSString*)bundleIdentifier animated:(BOOL)animated forceImmediateUnload:(BOOL)force
{
	for (ZYDesktopWindow *window in windows)
	{
		[window removeAppWithIdentifier:bundleIdentifier animated:animated forceImmediateUnload:force];
	}
}

-(ZYWindowBar*) windowForIdentifier:(NSString*)identifier
{
	for (ZYDesktopWindow *desktop in windows)
		if ([desktop isAppOpened:identifier])
			return [desktop windowForIdentifier:identifier];
	return nil;
}

-(void) hideDesktop
{
	currentDesktop.hidden = YES;
}

-(void) reshowDesktop
{
	currentDesktop.hidden = NO;
}

-(void) updateRotationOnClients:(UIInterfaceOrientation)orientation
{
	for (ZYDesktopWindow *w in windows)
		[w updateRotationOnClients:orientation];
}

-(void) updateWindowSizeForApplication:(NSString*)identifier
{
	for (ZYDesktopManager *w in windows)
		[w updateWindowSizeForApplication:identifier];
}

-(void) setLastUsedWindow:(ZYWindowBar*)window
{
	if (_lastUsedWindow)
	{
		[_lastUsedWindow resignForemostApp];
	}
	_lastUsedWindow = window;
	[_lastUsedWindow becomeForemostApp];
}

-(void) findNewForemostApp
{
	ZYDesktopWindow *desktop = [self currentDesktop];
	for (ZYHostedAppView *hostedApp in desktop.hostedWindows)
	{
		ZYWindowBar *bar = [desktop windowForIdentifier:hostedApp.app.bundleIdentifier];
		if (bar)
		{
			self.lastUsedWindow = bar;
			return;
		}
	}
	//self.lastUsedWindow = nil;
}

-(ZYDesktopWindow*) desktopAtIndex:(NSUInteger)index { return windows[index]; }
-(NSArray*) availableDesktops { return windows; }
-(NSUInteger) currentDesktopIndex { return currentDesktopIndex; }
-(ZYDesktopWindow*) currentDesktop { return currentDesktop; }
@end

/*
%hook UIWindow
-(void) makeKeyAndVisible
{
	%orig;
	if (overrideUIWindow)
	{
		static Class c1 = [%c(ZYMissionControlWindow) class];
		static Class c2 = [%c(SBAppSwitcherWindow) class];
		if ([self isKindOfClass:c1] || [self isKindOfClass:c2])
			return;
		__weak RADesktopWindow *currentDesktop = RADesktopManager.sharedInstance.currentDesktop;
		if (currentDesktop && self != currentDesktop && currentDesktop.hidden == NO)
		{
			//[RADesktopManager.sharedInstance.currentDesktop performSelector:@selector(_orderFrontWithoutMakingKey)];
			[currentDesktop makeKeyAndVisible];
		}
	}
}
%end
*/

%hook SpringBoard
-(void)noteInterfaceOrientationChanged:(UIInterfaceOrientation)arg1 duration:(CGFloat)arg2
{
	%orig;
	[ZYDesktopManager.sharedInstance updateRotationOnClients:arg1];
}
%end

%ctor
{
	if ([NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"])
		%init;
}
