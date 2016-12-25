#import "headers.h"
#import <AppSupport/CPDistributedMessagingCenter.h>
#include "ZYMessaging.h"

@interface ZYMessagingServer : NSObject {
	CPDistributedMessagingCenter *messagingCenter;
	NSMutableDictionary *dataForApps;
	NSMutableDictionary *contextIds;
	NSMutableDictionary *waitingCompletions;
}
+ (instancetype)sharedInstance;

- (void)loadServer;

- (ZYMessageAppData)getDataForIdentifier:(NSString*)identifier;
- (void)setData:(ZYMessageAppData)data forIdentifier:(NSString*)identifier;
- (void)sendStoredDataToApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;

- (void)resizeApp:(NSString*)identifier toSize:(CGSize)size completion:(ZYMessageCompletionCallback)callback;
- (void)moveApp:(NSString*)identifier toOrigin:(CGPoint)origin completion:(ZYMessageCompletionCallback)callback;
- (void)endResizingApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;

- (void)rotateApp:(NSString*)identifier toOrientation:(UIInterfaceOrientation)orientation completion:(ZYMessageCompletionCallback)callback;
- (void)unRotateApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;

- (void)forceStatusBarVisibility:(BOOL)visibility forApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;
- (void)unforceStatusBarVisibilityForApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;

- (void)setHosted:(BOOL)value forIdentifier:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;

- (void)forcePhoneMode:(BOOL)value forIdentifier:(NSString*)identifier andRelaunchApp:(BOOL)relaunch;

- (unsigned int)getStoredKeyboardContextIdForApp:(NSString*)identifier;

- (void)receiveShowKeyboardForAppWithIdentifier:(NSString*)identifier;
- (void)receiveHideKeyboard;
- (void)setShouldUseExternalKeyboard:(BOOL)value forApp:(NSString*)identifier completion:(ZYMessageCompletionCallback)callback;
@end
