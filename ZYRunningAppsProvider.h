#import "headers.h"

@protocol ZYRunningAppsProviderDelegate
@optional
- (void)appDidStart:(__unsafe_unretained SBApplication*)app;
- (void)appDidDie:(__unsafe_unretained SBApplication*)app;
@end

@interface ZYRunningAppsProvider : NSObject {
	NSMutableArray *apps;
	NSMutableArray *targets;
	NSLock *lock;
}
+ (instancetype)sharedInstance;

- (void)addRunningApp:(__unsafe_unretained SBApplication*)app;
- (void)removeRunningApp:(__unsafe_unretained SBApplication*)app;
- (void)addTarget:(__weak NSObject<ZYRunningAppsProviderDelegate>*)target;
- (void)removeTarget:(__weak NSObject<ZYRunningAppsProviderDelegate>*)target;

- (NSArray*)runningApplications;
@end
