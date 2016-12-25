#import "headers.h"

@interface ZYAppSwitcherModelWrapper : NSObject
+ (void)addToFront:(SBApplication*)app;
+ (void)addIdentifierToFront:(NSString*)ident;
+ (NSArray*)appSwitcherAppIdentiferList;

+ (void)removeItemWithIdentifier:(NSString*)ident;
@end
