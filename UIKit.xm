#import <UIKit/UIKit.h>
#import <substrate.h>
#import <SpringBoard/SBApplication.h>
#import "headers.h"
#import "ZYWidgetSectionManager.h"
#import "ZYSettings.h"
#import "ZYMessagingClient.h"
#import "ZYFakePhoneMode.h"

UIInterfaceOrientation prevousOrientation;
BOOL setPreviousOrientation = NO;
NSInteger wasStatusBarHidden = -1;

NSMutableDictionary *oldFrames = [NSMutableDictionary new];

static Class $memorized$UITextEffectsWindow$class;

%hook UIWindow
- (void)setFrame:(CGRect)frame {
    if (![self.class isEqual:$memorized$UITextEffectsWindow$class] && [ZYMessagingClient.sharedInstance shouldResize]) {
        if (![oldFrames objectForKey:@(self.hash)]) {
            [oldFrames setObject:[NSValue valueWithCGRect:frame] forKey:@(self.hash)];
        }
        frame.origin.x = ZYMessagingClient.sharedInstance.currentData.wantedClientOriginX == -1 ? 0 : ZYMessagingClient.sharedInstance.currentData.wantedClientOriginX;
        frame.origin.y = ZYMessagingClient.sharedInstance.currentData.wantedClientOriginY == -1 ? 0 : ZYMessagingClient.sharedInstance.currentData.wantedClientOriginY;
        CGFloat overrideWidth = [ZYMessagingClient.sharedInstance resizeSize].width;
        CGFloat overrideHeight = [ZYMessagingClient.sharedInstance resizeSize].height;
        if (overrideWidth != -1 && overrideWidth != 0) {
            frame.size.width = overrideWidth;
        }
        if (overrideHeight != -1 && overrideHeight != 0) {
            frame.size.height = overrideHeight;
        }
        if (self.subviews.count > 0) {
            ((UIView*)self.subviews[0]).frame = frame;
        }
    }

    %orig(frame);
}

- (void)_rotateWindowToOrientation:(UIInterfaceOrientation)arg1 updateStatusBar:(BOOL)arg2 duration:(double)arg3 skipCallbacks:(BOOL)arg4 {
    if ([ZYMessagingClient.sharedInstance shouldForceOrientation] && arg1 != [ZYMessagingClient.sharedInstance forcedOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:arg1]) {
        return;
    }
    %orig;
}

- (BOOL)_shouldAutorotateToInterfaceOrientation:(int)arg1 checkForDismissal:(BOOL)arg2 isRotationDisabled:(BOOL*)arg3 {
    if ([ZYMessagingClient.sharedInstance shouldForceOrientation] && arg1 != [ZYMessagingClient.sharedInstance forcedOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:arg1]) {
        return NO;
    }
    return %orig;
}

- (void)_setWindowInterfaceOrientation:(int)arg1 {
    if ([ZYMessagingClient.sharedInstance shouldForceOrientation] && arg1 != [ZYMessagingClient.sharedInstance forcedOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:arg1]) {
        return;
    }
    %orig([ZYMessagingClient.sharedInstance shouldForceOrientation] && [UIApplication.sharedApplication _isSupportedOrientation:[ZYMessagingClient.sharedInstance forcedOrientation]] ? [ZYMessagingClient.sharedInstance forcedOrientation] : arg1);
}

- (void)_sendTouchesForEvent:(unsafe_id)arg1 {
    %orig;

    dispatch_async(dispatch_get_main_queue(), ^{
        [ZYMessagingClient.sharedInstance notifySpringBoardOfFrontAppChangeToSelf];
    });
}
%end

%hook UIApplication
- (void)applicationDidResume {
    %orig;
    [ZYMessagingClient.sharedInstance requestUpdateFromServer];
    //[ZYFakePhoneMode updateAppSizing];
}
/*
+(void) _startWindowServerIfNecessary
{
    %orig;
    //[ZYMessagingClient.sharedInstance requestUpdateFromServer];
    [ZYFakePhoneMode updateAppSizing];
}
*/
- (void)_setStatusBarHidden:(BOOL)arg1 animationParameters:(unsafe_id)arg2 changeApplicationFlag:(BOOL)arg3 {
	//if ([ZYSettings.sharedSettings unifyStatusBar])
    if ([ZYMessagingClient.sharedInstance shouldHideStatusBar]) {
        arg1 = YES;
        arg3 = YES;
    } else if ([ZYMessagingClient.sharedInstance shouldShowStatusBar]) {
        arg1 = NO;
        arg3 = YES;
    }
    //arg1 = ((forcingRotation&&NO) || overrideDisplay) ? (isTopApp ? NO : YES) : arg1;

    %orig(arg1, arg2, arg3);
}

/*
- (void)_notifySpringBoardOfStatusBarOrientationChangeAndFenceWithAnimationDuration:(double)arg1
{
    if (overrideViewControllerDismissal)
        return;
    %orig;
}
*/

%new - (void)ZY_forceRotationToInterfaceOrientation:(UIInterfaceOrientation)orientation isReverting:(BOOL)reverting {
    if (!reverting) {
        if (!setPreviousOrientation) {
            setPreviousOrientation = YES;
            prevousOrientation = UIApplication.sharedApplication.statusBarOrientation;
            if (wasStatusBarHidden == -1) {
                wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
            }
        }
    } else if (setPreviousOrientation) {
        orientation = prevousOrientation;
        setPreviousOrientation = NO;
    }

    if (![UIApplication.sharedApplication _isSupportedOrientation:orientation]) {
        return;
    }

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        [window _setRotatableViewOrientation:orientation updateStatusBar:YES duration:0.25 force:YES];
    }
}

%new - (void)ZY_forceStatusBarVisibility:(BOOL)visible orRevert:(BOOL)revert {
    if (revert) {
        if (wasStatusBarHidden != -1) {
            [UIApplication.sharedApplication _setStatusBarHidden:wasStatusBarHidden animationParameters:nil changeApplicationFlag:YES];
        }
    } else {
        if (wasStatusBarHidden == -1) {
            wasStatusBarHidden = UIApplication.sharedApplication.statusBarHidden;
        }
        [UIApplication.sharedApplication _setStatusBarHidden:visible animationParameters:nil changeApplicationFlag:YES];
    }
}

%new - (void)ZY_updateWindowsForSizeChange:(CGSize)size isReverting:(BOOL)revert {
    if (revert) {
        for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
            CGRect frame = window.frame;
            if ([oldFrames objectForKey:@(window.hash)] != nil) {
                frame = [[oldFrames objectForKey:@(window.hash)] CGRectValue];
                [oldFrames removeObjectForKey:@(window.hash)];
            }

            [UIView animateWithDuration:0.4 animations:^{
                [window setFrame:frame];
            }];
        }

        if ([oldFrames objectForKey:@"statusBar"] != nil) {
            UIApplication.sharedApplication.statusBar.frame = [oldFrames[@"statusBar"] CGRectValue];
        }
        return;
    }

    if (size.width != -1) {
        if (![oldFrames objectForKey:@"statusBar"]) {
            [oldFrames setObject:[NSValue valueWithCGRect:UIApplication.sharedApplication.statusBar.frame] forKey:@"statusBar"];
        }
        UIApplication.sharedApplication.statusBar.frame = CGRectMake(0, 0, size.width, UIApplication.sharedApplication.statusBar.frame.size.height);
    }

    for (UIWindow *window in [[UIApplication sharedApplication] windows]) {
        if (![oldFrames objectForKey:@(window.hash)]) {
            [oldFrames setObject:[NSValue valueWithCGRect:window.frame] forKey:@(window.hash)];
        }
        [UIView animateWithDuration:0.3 animations:^{
            [window setFrame:window.frame]; // updates with client message app data in the setFrame: hook
        }];
    }
}

// Its gotta be here
- (BOOL)isNetworkActivityIndicatorVisible {
    if ([ZYMessagingClient.sharedInstance isBeingHosted]) {
        return [objc_getAssociatedObject(self, @selector(ZY_networkActivity)) boolValue];
    } else {
        return %orig;
    }
}

- (void)setNetworkActivityIndicatorVisible:(BOOL)arg1 {
    %orig(arg1);
    if ([ZYMessagingClient.sharedInstance isBeingHosted]) {
        objc_setAssociatedObject(self, @selector(ZY_networkActivity), @(arg1), OBJC_ASSOCIATION_RETAIN_NONATOMIC);

        StatusBarData *data = [UIStatusBarServer getStatusBarData];
        data->itemIsEnabled[24] = arg1; // 24 = activity indicator (actually about)
        [UIApplication.sharedApplication.statusBar forceUpdateToData:data animated:YES];
    }
}

- (BOOL)openURL:(__unsafe_unretained NSURL*)url {
    if ([ZYMessagingClient.sharedInstance isBeingHosted]) {
        return [ZYMessagingClient.sharedInstance notifyServerToOpenURL:url openInWindow:[ZYSettings.sharedSettings openLinksInWindows]];
    }
    return %orig;
}
%end

%hook UIStatusBar
- (void)statusBarServer:(unsafe_id)arg1 didReceiveStatusBarData:(StatusBarData*)arg2 withActions:(int)arg3 {
    if ([ZYMessagingClient.sharedInstance isBeingHosted]) {
        arg2->itemIsEnabled[24] = [UIApplication.sharedApplication isNetworkActivityIndicatorVisible];
    }
    %orig;
}
%end

void reloadSettings(CFNotificationCenterRef center,
                    void *observer,
                    CFStringRef name,
                    const void *object,
                    CFDictionaryRef userInfo) {
    [ZYSettings.sharedSettings reloadSettings];
}

%ctor {
    IF_NOT_SPRINGBOARD {
        %init;
        $memorized$UITextEffectsWindow$class = objc_getClass("UITextEffectsWindow");
    }

    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, &reloadSettings, CFSTR("com.shade.zypen/ReloadPrefs"), NULL, 0);
    [ZYSettings sharedSettings];
}
