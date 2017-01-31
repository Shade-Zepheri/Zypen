#import <UIKit/UIKit.h>

typedef NS_ENUM(NSInteger, ZYMessageType) {
	ZYMessageTypeUpdateAppData = 0,

	ZYMessageTypeShowKeyboard,
	ZYMessageTypeHideKeyboard,
	ZYMessageTypeUpdateKeyboardContextId,
	ZYMessageTypeRetrieveKeyboardContextId,
};

typedef struct {
	BOOL shouldForceSize;
	// Can't use CGSize because it uses CGFloats which aren't able to be transferred between 32/64bit processes (because its float in one and something else (double? i can't remember) in the other).
	// Also why we can't use CGFloat here?
	// Well you can
	float wantedClientOriginX;
	float wantedClientOriginY;
	float wantedClientWidth;
	float wantedClientHeight;

	BOOL statusBarVisibility;
	BOOL shouldForceStatusBar;
	BOOL canHideStatusBarIfWanted;

	UIInterfaceOrientation forcedOrientation;
	BOOL shouldForceOrientation;

	BOOL shouldUseExternalKeyboard;
	BOOL isBeingHosted;
	// Only applies after the app has been restarted.
	BOOL forcePhoneMode;
} ZYMessageAppData;

static NSString *ZYMessagingUpdateAppInfoMessageName = @"updateAppInfo";
static NSString *ZYMessagingShowKeyboardMessageName = @"showKeyboard";
static NSString *ZYMessagingHideKeyboardMessageName = @"hideKeyboard";
static NSString *ZYMessagingUpdateKeyboardContextIdMessageName = @"updateKBContextId";
static NSString *ZYMessagingRetrieveKeyboardContextIdMessageName = @"getKBContextId";
static NSString *ZYMessagingUpdateKeyboardSizeMessageName = @"updateKBSize";
static NSString *ZYMessagingOpenURLKMessageName = @"openURL";
static NSString *ZYMessagingSnapFrontMostWindowLeftMessageName = @"snapLeft";
static NSString *ZYMessagingSnapFrontMostWindowRightMessageName = @"snapRight";
static NSString *ZYMessagingGoToDesktopOnTheLeftMessageName = @"switchToDesktopLeft";
static NSString *ZYMessagingGoToDesktopOnTheRightMessageName = @"switchToDesktopRight";
static NSString *ZYMessagingAddNewDesktopMessageName = @"addNewDesktop";
static NSString *ZYMessagingMaximizeAppMessageName = @"maximizeApp";
static NSString *ZYMessagingCloseAppMessageName = @"closeApp";
static NSString *ZYMessagingGetFrontMostAppInfoMessageName = @"frontMostApp";
static NSString *ZYMessagingChangeFrontMostAppMessageName = @"yes_another_message";
static NSString *ZYMessagingDetachCurrentAppMessageName = @"the_messages_never_end";

typedef void (^ZYMessageCompletionCallback)(BOOL success);
