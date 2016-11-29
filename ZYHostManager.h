#import "headers.h"

@interface ZYHostManager : NSObject
+(UIView*) systemHostViewForApplication:(SBApplication*)app;
+(UIView*) enabledHostViewForApplication:(SBApplication*)app;
+(NSObject*) hostManagerForApp:(SBApplication*)app;
@end
