#import "headers.h"
#import "ZYRunningAppsProvider.h"

@interface ZYAppKiller : NSObject <ZYRunningAppsProviderDelegate>
+ (void)killAppWithIdentifier:(NSString*)identifier;
+ (void)killAppWithIdentifier:(NSString*)identifier completion:(void(^)())handler;
+ (void)killAppWithSBApplication:(SBApplication*)app;
+ (void)killAppWithSBApplication:(SBApplication*)app completion:(void(^)())handler;
@end
