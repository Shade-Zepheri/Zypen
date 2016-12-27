#import "ZYFakePhoneMode.h"
#import "ZYMessagingClient.h"
#import "ZYMessagingServer.h"

/*
This is a wrapper for the ReachAppFakePhoneMode subproject.
I split them apart when i was trying to find some issue with app resizing/touches.
*/

#define ZY_4S_SIZE CGSizeMake(320, 480)
#define ZY_5S_SIZE CGSizeMake(320, 568)
#define ZY_6P_SIZE CGSizeMake(414, 736)

CGSize forcePhoneModeSize = ZY_6P_SIZE;

@implementation ZYFakePhoneMode
+ (void)load {
    // Prevent iPhone issue
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ // somehow, this is needed to make sure that both force resizing and Fake Phone Mode work. Without the dispatch_after, even if fake phone mode is disabled,
                // force resizing seems to render touches incorrectly ¯\_(ツ)_/¯
            IF_NOT_SPRINGBOARD {
                if ([ZYFakePhoneMode shouldFakeForThisProcess]) {
                    dlopen("/Library/MobileSubstrate/DynamicLibraries/ZYFakePhoneMode.dylib", RTLD_NOW);
                }
            }
        });
    }
}

+ (CGSize)fakedSize {
	if (UIInterfaceOrientationIsLandscape(UIApplication.sharedApplication.statusBarOrientation))
		return CGSizeMake(forcePhoneModeSize.height, forcePhoneModeSize.width);
	return forcePhoneModeSize;
}

+ (CGSize)fakeSizeForAppWithIdentifier:(NSString*)identifier {
	return forcePhoneModeSize;
}

+ (void)updateAppSizing {
    CGRect f = UIWindow.keyWindow.frame;
    f.origin = CGPointZero;
    UIWindow.keyWindow.frame = f;
}

+ (BOOL)shouldFakeForAppWithIdentifier:(NSString*)identifier {
	IF_SPRINGBOARD {
		return [ZYMessagingServer.sharedInstance getDataForIdentifier:identifier].forcePhoneMode;
	}
	NSLog(@"[ReachApp] WARNING: +[ZYFakePhoneMode shouldFakeForAppWithIdentifier:] called from outside SpringBoard!");
	return NO;
}

+ (BOOL)shouldFakeForThisProcess {
    static char fakeFlag = 0;
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        if (!ZYMessagingClient.sharedInstance.hasRecievedData)
        {
            [ZYMessagingClient.sharedInstance requestUpdateFromServer];
        }

        fakeFlag = ZYMessagingClient.sharedInstance.currentData.forcePhoneMode;
    });

    return fakeFlag;
}
@end
