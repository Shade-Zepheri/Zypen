#import "ZYKeyboardStateListener.h"
#import "headers.h"
#import <execinfo.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "ZYMessaging.h"
#import "ZYMessagingClient.h"
#import "ZYKeyboardWindow.h"
#import "ZYRemoteKeyboardView.h"
#import "ZYDesktopManager.h"

extern BOOL overrideDisableForStatusBar;
BOOL isShowing = NO;

@implementation ZYKeyboardStateListener
+ (instancetype)sharedInstance {
    SHARED_INSTANCE(ZYKeyboardStateListener);
}

- (void)didShow:(NSNotification*)notif {
    HBLogDebug(@"[ReachApp] keyboard didShow");
    _visible = YES;
    _size = [[notif.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue].size;

    IF_NOT_SPRINGBOARD {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDistributedCenter(), CFSTR("com.shade.zypen.keyboard.didShow"), NULL, NULL, true);
        [ZYMessagingClient.sharedInstance notifyServerOfKeyboardSizeUpdate:_size];

        if ([ZYMessagingClient.sharedInstance shouldUseExternalKeyboard]) {
            [ZYMessagingClient.sharedInstance notifyServerToShowKeyboard];
            isShowing = YES;
        }
    }
}

- (void)didHide {
    HBLogDebug(@"[ReachApp] keyboard didHide");
    _visible = NO;

    IF_NOT_SPRINGBOARD {
        CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.shade.zypen.keyboard.didHide"), NULL, NULL, true);
        if ([ZYMessagingClient.sharedInstance shouldUseExternalKeyboard] || isShowing) {
            isShowing = NO;
            [ZYMessagingClient.sharedInstance notifyServerToHideKeyboard];
        }
    }
}

- (id)init {
    if ((self = [super init])) {
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(didShow:) name:UIKeyboardDidShowNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIKeyboardWillHideNotification object:nil];
        [center addObserver:self selector:@selector(didHide) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)_setVisible:(BOOL)val {
  _visible = val;
}

- (void)_setSize:(CGSize)size {
  _size = size;
}

@end

void externalKeyboardDidShow(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    [ZYKeyboardStateListener.sharedInstance _setVisible:YES];
}

void externalKeyboardDidHide(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
    //HBLogDebug(@"[ReachApp] externalKeyboardDidHide");
    [ZYKeyboardStateListener.sharedInstance _setVisible:NO];
}

%hook UIKeyboard
- (void)activate {
    %orig;

    void (^block)() = ^{
        IF_NOT_SPRINGBOARD {
            NSUInteger contextID = 0;
            if (objc_getClass("UIRemoteKeyboardWindow") != nil && [UIKeyboard activeKeyboard] && [[UIKeyboard activeKeyboard] window]) {
              contextID = [[[UIKeyboard activeKeyboard] window] _contextId]; // ((UITextEffectsWindow*)[%c(UIRemoteKeyboardWindow) remoteKeyboardWindowForScreen:UIScreen.mainScreen create:NO])._contextId;
            } else {
              contextID = UITextEffectsWindow.sharedTextEffectsWindow._contextId;
            }
            [ZYMessagingClient.sharedInstance notifyServerWithKeyboardContextId:contextID];
            HBLogDebug(@"[ReachApp] c id %tu", contextID);
        }
    };

    if (SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"9.0")) {
      dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), block);
    } else {
      block();
    }
}
%end

%ctor {
    // Any process
    [ZYKeyboardStateListener sharedInstance];

    // Just SpringBoard
    IF_SPRINGBOARD {
        CFNotificationCenterAddObserver(CFNotificationCenterGetDistributedCenter(), NULL, externalKeyboardDidShow, CFSTR("com.shade.zypen.keyboard.didShow"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
        CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, externalKeyboardDidHide, CFSTR("com.shade.zypen.keyboard.didHide"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
    }
}
