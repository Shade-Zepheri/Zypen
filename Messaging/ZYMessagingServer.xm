#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "ZYMessagingServer.h"
#import "ZYSpringBoardKeyboardActivation.h"
#import "dispatch_after_cancel.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>
#import "ZYKeyboardStateListener.h"
#import "ZYSettings.h"
#import "ZYAppKiller.h"
#import "ZYDesktopManager.h"
#import "ZYWindowSnapDataProvider.h"
#import "ZYHostManager.h"

extern BOOL launchNextOpenIntoWindow;

@interface ZYMessagingServer () {
	NSMutableDictionary *asyncHandles;
}
@end

@implementation ZYMessagingServer
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(ZYMessagingServer,
		[sharedInstance loadServer];
		sharedInstance->dataForApps = [NSMutableDictionary dictionary];
		sharedInstance->contextIds = [NSMutableDictionary dictionary];
		sharedInstance->waitingCompletions = [NSMutableDictionary dictionary];
		sharedInstance->asyncHandles = [NSMutableDictionary dictionary];
	);
}

-(void) loadServer
{
    messagingCenter = [objc_getClass("CPDistributedMessagingCenter") centerNamed:@"com.shade.zypen.messaging.server"];

    void* handle = dlopen("/usr/lib/librocketbootstrap.dylib", RTLD_LAZY);
    if (handle)
    {
        void (*rocketbootstrap_distributedmessagingcenter_apply)(CPDistributedMessagingCenter*);
        rocketbootstrap_distributedmessagingcenter_apply = (void(*)(CPDistributedMessagingCenter*))dlsym(handle, "rocketbootstrap_distributedmessagingcenter_apply");
        rocketbootstrap_distributedmessagingcenter_apply(messagingCenter);
        dlclose(handle);
    }

    [messagingCenter runServerOnCurrentThread];

    [messagingCenter registerForMessageName:ZYMessagingShowKeyboardMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingHideKeyboardMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingUpdateKeyboardContextIdMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingRetrieveKeyboardContextIdMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingUpdateAppInfoMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];

    [messagingCenter registerForMessageName:ZYMessagingUpdateKeyboardSizeMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingOpenURLKMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];

    [messagingCenter registerForMessageName:ZYMessagingGetFrontMostAppInfoMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingChangeFrontMostAppMessageName target:self selector:@selector(handleMessageNamed:userInfo:)];

    [messagingCenter registerForMessageName:ZYMessagingSnapFrontMostWindowLeftMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingSnapFrontMostWindowRightMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingGoToDesktopOnTheLeftMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingGoToDesktopOnTheRightMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingMaximizeAppMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingAddNewDesktopMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingCloseAppMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
    [messagingCenter registerForMessageName:ZYMessagingDetachCurrentAppMessageName target:self selector:@selector(handleKeyboardEvent:userInfo:)];
}

-(NSDictionary*) handleMessageNamed:(NSString*)identifier userInfo:(NSDictionary*)info
{
	if ([identifier isEqual:ZYMessagingShowKeyboardMessageName])
		[self receiveShowKeyboardForAppWithIdentifier:info[@"bundleIdentifier"]];
	else if ([identifier isEqual:ZYMessagingHideKeyboardMessageName])
		[self receiveHideKeyboard];
	else if ([identifier isEqual:ZYMessagingUpdateKeyboardContextIdMessageName])
		[self setKeyboardContextId:[info[@"contextId"] integerValue] forIdentifier:info[@"bundleIdentifier"]];
	else if ([identifier isEqual:ZYMessagingRetrieveKeyboardContextIdMessageName])
		return @{ @"contextId": @([self getStoredKeyboardContextIdForApp:info[@"bundleIdentifier"]]) };
	else if ([identifier isEqual:ZYMessagingUpdateKeyboardSizeMessageName])
	{
		CGSize size = CGSizeFromString(info[@"size"]);
		[ZYKeyboardStateListener.sharedInstance _setSize:size];
	}
	else if ([identifier isEqual:ZYMessagingUpdateAppInfoMessageName])
	{
		NSString *identifier = info[@"bundleIdentifier"];
		ZYMessageAppData data = [self getDataForIdentifier:identifier];

		if ([waitingCompletions objectForKey:identifier] != nil)
		{
			ZYMessageCompletionCallback callback = (ZYMessageCompletionCallback)waitingCompletions[identifier];
			[waitingCompletions removeObjectForKey:identifier];
			callback(YES);
		}

		// Got the message, cancel the re-sender
		if ([asyncHandles objectForKey:identifier] != nil)
		{
			struct dispatch_async_handle *handle = (struct dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		return @{
			@"data": [NSData dataWithBytes:&data length:sizeof(data)],
		};
	}
	else if ([identifier isEqual:ZYMessagingOpenURLKMessageName])
	{
		NSURL *url = [NSURL URLWithString:info[@"url"]];
		BOOL openInWindow = [ZYSettings.sharedSettings openLinksInWindows]; // [info[@"openInWindow"] boolValue];
		if (openInWindow)
			launchNextOpenIntoWindow = YES;

		BOOL success = [UIApplication.sharedApplication openURL:url];
		return @{ @"success": @(success) };
	}
	else if ([identifier isEqual:ZYMessagingGetFrontMostAppInfoMessageName])
	{
		if (UIApplication.sharedApplication._accessibilityFrontMostApplication)
			return nil;
		ZYWindowBar *window = ZYDesktopManager.sharedInstance.lastUsedWindow;
		if (window)
		{
			SBApplication *app = window.attachedView.app;
			if (app.pid)
				return @{
					@"pid": @(app.pid),
					@"bundleIdentifier": app.bundleIdentifier
				};
		}
	}
	else if ([identifier isEqual:ZYMessagingChangeFrontMostAppMessageName])
	{
		NSString *bundleIdentifier = info[@"bundleIdentifier"];
		ZYWindowBar *window = [ZYDesktopManager.sharedInstance windowForIdentifier:bundleIdentifier];
		if (window)
		{
			ZYDesktopManager.sharedInstance.lastUsedWindow = window;
			CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.shade.zypen.frontmostAppDidUpdate"), NULL, (__bridge CFDictionaryRef)@{ @"bundleIdentifier": bundleIdentifier }, YES);
		}
	}

	return nil;
}

-(void) handleKeyboardEvent:(NSString*)identifier userInfo:(NSDictionary*)info
{
	if ([identifier isEqual:ZYMessagingDetachCurrentAppMessageName])
	{
        SBApplication *topApp = [[UIApplication sharedApplication] _accessibilityFrontMostApplication];

        if (topApp)
        {
	        [[%c(SBWallpaperController) sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];
	        [[%c(SBUIController) sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];

	        UIView *appView = [ZYHostManager systemHostViewForApplication:topApp].superview;

		    [UIView animateWithDuration:0.2 animations:^{
		        appView.transform = CGAffineTransformMakeScale(0.5, 0.5);
		    } completion:^(BOOL _) {
	       		[[%c(SBWallpaperController) sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
		        FBWorkspaceEvent *event = [%c(FBWorkspaceEvent) eventWithName:@"ActivateSpringBoard" handler:^{
		            SBAppToAppWorkspaceTransaction *transaction = [[%c(SBAppToAppWorkspaceTransaction) alloc] initWithAlertManager:nil exitedApp:UIApplication.sharedApplication._accessibilityFrontMostApplication];
		            [transaction begin];
		        }];
		        [(FBWorkspaceEventQueue*)[%c(FBWorkspaceEventQueue) sharedInstance] executeOrAppendEvent:event];
		        [ZYDesktopManager.sharedInstance.currentDesktop createAppWindowForSBApplication:topApp animated:YES];
		    }];
        }
	}
	else if ([identifier isEqual:ZYMessagingGoToDesktopOnTheLeftMessageName])
	{
		int newIndex = ZYDesktopManager.sharedInstance.currentDesktopIndex - 1;
		BOOL isValid = newIndex >= 0 && newIndex <= ZYDesktopManager.sharedInstance.numberOfDesktops;
		if (isValid)
			[ZYDesktopManager.sharedInstance switchToDesktop:newIndex];
	}
	else if ([identifier isEqual:ZYMessagingGoToDesktopOnTheRightMessageName])
	{
		int newIndex = ZYDesktopManager.sharedInstance.currentDesktopIndex + 1;
		BOOL isValid = newIndex >= 0 && newIndex < ZYDesktopManager.sharedInstance.numberOfDesktops;
		if (isValid)
			[ZYDesktopManager.sharedInstance switchToDesktop:newIndex];
	}
	else if ([identifier isEqual:ZYMessagingAddNewDesktopMessageName])
	{
		[ZYDesktopManager.sharedInstance addDesktop:YES];
	}

	ZYWindowBar *window = ZYDesktopManager.sharedInstance.lastUsedWindow;
	if (!window)
		return;
	if ([identifier isEqual:ZYMessagingSnapFrontMostWindowLeftMessageName])
	{
		[ZYWindowSnapDataProvider snapWindow:window toLocation:ZYWindowSnapLocationGetLeftOfScreen() animated:YES];
	}
	else if ([identifier isEqual:ZYMessagingSnapFrontMostWindowRightMessageName])
	{
		[ZYWindowSnapDataProvider snapWindow:window toLocation:ZYWindowSnapLocationGetRightOfScreen() animated:YES];
	}
	else if ([identifier isEqual:ZYMessagingMaximizeAppMessageName])
	{
		[window maximize];
	}
	else if ([identifier isEqual:ZYMessagingCloseAppMessageName])
	{
		[window close];
	}
}

-(void) alertUser:(NSString*)description {

}

-(ZYMessageAppData) getDataForIdentifier:(NSString*)identifier
{
	ZYMessageAppData ret;
	if ([dataForApps objectForKey:identifier] != nil)
		[dataForApps[identifier] getValue:&ret];
	else
	{
		// Initialize with some default values
		ret.shouldForceSize = NO;
		ret.wantedClientOriginX = -1;
		ret.wantedClientOriginY = -1;
		ret.wantedClientWidth = -1;
		ret.wantedClientHeight = -1;
		ret.statusBarVisibility = YES;
		ret.shouldForceStatusBar = NO;
		ret.canHideStatusBarIfWanted = NO;
		ret.forcedOrientation = UIInterfaceOrientationPortrait;
		ret.shouldForceOrientation = NO;
		ret.forcePhoneMode = NO;
		ret.shouldUseExternalKeyboard = NO;
		ret.isBeingHosted = NO;
	}
	return ret;
}

-(void) setData:(ZYMessageAppData)data forIdentifier:(NSString*)identifier
{
	if (identifier)
	{
		dataForApps[identifier] = [NSValue valueWithBytes:&data objCType:@encode(ZYMessageAppData)];
	}
}

-(void) checkIfCompletionStillExitsForIdentifierAndFailIt:(NSString*)identifier
{
	if ([waitingCompletions objectForKey:identifier] != nil)
	{
		// We timed out, remove the re-sender
		if ([asyncHandles objectForKey:identifier] != nil)
		{
			struct dispatch_async_handle *handle = (struct dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		ZYMessageCompletionCallback callback = (ZYMessageCompletionCallback)waitingCompletions[identifier];
		[waitingCompletions removeObjectForKey:identifier];

		SBApplication *app = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:identifier];
		[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app %@ (%@)", app.displayName, identifier]];
		callback(NO);
	}
}

-(void) sendDataWithCurrentTries:(int)tries toAppWithBundleIdentifier:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:identifier];
	if (!app.isRunning || [app mainScene] == nil)
	{
		if (tries > 4)
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app that isn't running: %@ (%@)", app.displayName, identifier]];
			if (callback)
				callback(NO);
			return;
		}

		if ([asyncHandles objectForKey:identifier] != nil)
		{
			struct dispatch_async_handle *handle = (struct dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		struct dispatch_async_handle *handle = dispatch_after_cancellable(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendDataWithCurrentTries:tries + 1 toAppWithBundleIdentifier:identifier completion:callback];
		});
		asyncHandles[identifier] = [NSValue valueWithPointer:handle];
		return;
	}

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), (__bridge CFStringRef)[NSString stringWithFormat:@"com.shade.zypen.clientupdate-%@",identifier], nil, nil, YES);

	if (tries <= 4)
	{
		if ([asyncHandles objectForKey:identifier] != nil)
		{
			struct dispatch_async_handle *handle = (struct dispatch_async_handle *)[asyncHandles[identifier] pointerValue];
			dispatch_after_cancel(handle);
			[asyncHandles removeObjectForKey:identifier];
		}

		struct dispatch_async_handle *handle = dispatch_after_cancellable(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendDataWithCurrentTries:tries + 1 toAppWithBundleIdentifier:identifier completion:callback];
		});
		asyncHandles[identifier] = [NSValue valueWithPointer:handle];

		if ([waitingCompletions objectForKey:identifier] == nil)
		{
			//if (callback == nil)
			//	callback = ^(BOOL _) { };
			if (callback)
				waitingCompletions[identifier] = [callback copy];
		}
		// Reset failure checker
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(checkIfCompletionStillExitsForIdentifierAndFailIt:) object:identifier];
		[self performSelector:@selector(checkIfCompletionStillExitsForIdentifierAndFailIt:) withObject:identifier afterDelay:4];
	}


/*
	SBApplication *app = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:identifier];

	if (!app.isRunning || [app mainScene] == nil)
	{
		if (tries > 4)
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app that isn't running: %@ (%@)", app.displayName, identifier]];
			if (callback)
				callback(NO);
			return;
		}

		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[self sendData:data toApp:center withCurrentTries:tries + 1 bundleIdentifier:identifier completion:callback];
		});
		return;
	}

	NSDictionary *success = [center sendMessageAndReceiveReplyName:ZYMessagingUpdateAppInfoMessageName userInfo:data];

	if (!success || [success objectForKey:@"success"] == nil || [success[@"success"] boolValue] == NO)
	{
		if (tries <= 4)
		{
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.75 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
				[self sendData:data toApp:center withCurrentTries:tries + 1 bundleIdentifier:identifier completion:callback];
			});
		}
		else
		{
			[self alertUser:[NSString stringWithFormat:@"Unable to communicate with app %@ (%@)\n\nadditional info: %@", app.displayName, identifier, success]];
			if (callback)
				callback(NO);
		}
	}
	else
		if (callback)
			callback(YES);
*/
}

-(void) sendStoredDataToApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	if (!identifier || identifier.length == 0)
		return;

	[self sendDataWithCurrentTries:0 toAppWithBundleIdentifier:identifier completion:callback];
}

-(void) resizeApp:(NSString*)identifier toSize:(CGSize)size completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.wantedClientWidth = size.width;
	data.wantedClientHeight = size.height;
	data.shouldForceSize = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) moveApp:(NSString*)identifier toOrigin:(CGPoint)origin completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.wantedClientOriginX = (float)origin.x;
	data.wantedClientOriginY = (float)origin.y;
	data.shouldForceSize = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) endResizingApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	//data.wantedClientSize = CGSizeMake(-1, -1);
	data.shouldForceSize = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) rotateApp:(NSString*)identifier toOrientation:(UIInterfaceOrientation)orientation completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];

	if (data.forcePhoneMode)
		return;

	data.forcedOrientation = orientation;
	data.shouldForceOrientation = YES;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) unRotateApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.forcedOrientation = UIApplication.sharedApplication.statusBarOrientation;
	data.shouldForceOrientation = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) forceStatusBarVisibility:(BOOL)visibility forApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceStatusBar = YES;
	data.statusBarVisibility = visibility;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) unforceStatusBarVisibilityForApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldForceStatusBar = NO;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) setShouldUseExternalKeyboard:(BOOL)value forApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.shouldUseExternalKeyboard = value;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) setHosted:(BOOL)value forIdentifier:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];
	data.isBeingHosted = value;
	[self setData:data forIdentifier:identifier];
	[self sendStoredDataToApp:identifier completion:callback];
}

-(void) forcePhoneMode:(BOOL)value forIdentifier:(NSString*)identifier andRelaunchApp:(BOOL)relaunch
{
	ZYMessageAppData data = [self getDataForIdentifier:identifier];

	data.forcePhoneMode = value;
	[self setData:data forIdentifier:identifier];

	if (relaunch)
	{
		[ZYAppKiller killAppWithIdentifier:identifier completion:^{
			[ZYDesktopManager.sharedInstance updateWindowSizeForApplication:identifier];
		}];
	}
}

-(void) receiveShowKeyboardForAppWithIdentifier:(NSString*)identifier
{
	[ZYSpringBoardKeyboardActivation.sharedInstance showKeyboardForAppWithIdentifier:identifier];
}

-(void) receiveHideKeyboard
{
	[ZYSpringBoardKeyboardActivation.sharedInstance hideKeyboard];
}

-(void) setKeyboardContextId:(unsigned int)id forIdentifier:(NSString*)identifier
{
	HBLogDebug(@"[ReachApp] got c id %d", id);
	contextIds[identifier] = @(id);
}

-(unsigned int) getStoredKeyboardContextIdForApp:(NSString*)identifier
{
	return [contextIds objectForKey:identifier] != nil ? [contextIds[identifier] unsignedIntValue] : 0;
}
@end

%ctor
{
	IF_SPRINGBOARD {
		[ZYMessagingServer sharedInstance];
	}
}
