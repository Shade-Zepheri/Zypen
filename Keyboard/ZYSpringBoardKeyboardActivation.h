#import "headers.h"
#import "ZYRunningAppsProvider.h"

@interface ZYSpringBoardKeyboardActivation : NSObject<ZYRunningAppsProviderDelegate>
+(instancetype) sharedInstance;

@property (nonatomic, readonly, retain) NSString *currentIdentifier;

-(void) showKeyboardForAppWithIdentifier:(NSString*)identifier;
-(void) hideKeyboard;

-(UIWindow*) keyboardWindow;
@end
