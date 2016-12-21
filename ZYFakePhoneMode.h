#import "headers.h"

@interface ZYFakePhoneMode : NSObject
+(CGSize) fakedSize;
+(BOOL) shouldFakeForThisProcess;
+(void) updateAppSizing;

+(BOOL) shouldFakeForAppWithIdentifier:(NSString*)identifier;
+(CGSize) fakeSizeForAppWithIdentifier:(NSString*)identifier;
@end
