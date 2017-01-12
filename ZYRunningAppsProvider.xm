#import "ZYRunningAppsProvider.h"

@implementation ZYRunningAppsProvider
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(ZYRunningAppsProvider,
		sharedInstance->apps = [NSMutableArray array];
		sharedInstance->targets = [NSMutableArray array];
		sharedInstance->lock = [[NSLock alloc] init];
	);
}

- (void)addRunningApp:(__unsafe_unretained SBApplication*)app {
	[lock lock];

	[apps addObject:app];
	for (NSObject<ZYRunningAppsProviderDelegate>* target in targets) {
		if ([target respondsToSelector:@selector(appDidStart:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidStart:app];
			});
		}
	}
	[lock unlock];
}

- (void)removeRunningApp:(__unsafe_unretained SBApplication*)app {
	[lock lock];

	[apps removeObject:app];

	for (NSObject<ZYRunningAppsProviderDelegate>* target in targets) {
		if ([target respondsToSelector:@selector(appDidDie:)]) {
			dispatch_async(dispatch_get_main_queue(), ^{
				[target appDidDie:app];
			});
		}
	}
	[lock unlock];
}

- (void)addTarget:(__weak NSObject<ZYRunningAppsProviderDelegate>*)target {
	[lock lock];

	if (![targets containsObject:target]) {
			[targets addObject:target];
	}
	[lock unlock];
}

- (void)removeTarget:(__weak NSObject<ZYRunningAppsProviderDelegate>*)target {
	[lock lock];

	[targets removeObject:target];

	[lock unlock];
}

- (NSArray*)runningApplications {
	return apps;
}

- (NSMutableArray*)mutableRunningApplications {
	return apps;
}

@end

%hook SBApplication
- (void)updateProcessState:(unsafe_id)arg1 {
	%orig;

	if (self.isRunning && ![ZYRunningAppsProvider.sharedInstance.mutableRunningApplications containsObject:self]) {
		[ZYRunningAppsProvider.sharedInstance addRunningApp:self];
	} else if (!self.isRunning && [ZYRunningAppsProvider.sharedInstance.mutableRunningApplications containsObject:self]) {
		[ZYRunningAppsProvider.sharedInstance removeRunningApp:self];
	}
}

%end
