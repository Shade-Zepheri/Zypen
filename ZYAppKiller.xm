#import "ZYAppKiller.h"
#import "ZYRunningAppsProvider.h"

extern "C" void BKSTerminateApplicationForReasonAndReportWithDescription(NSString *app, int a, int b, NSString *description);

@interface ZYAppKiller () {
	NSMutableDictionary *completionDictionary;
}
@end

@implementation ZYAppKiller : NSObject
+(instancetype) sharedInstance
{
	SHARED_INSTANCE2(ZYAppKiller,
		[sharedInstance initialize];
	);
}

+(void) killAppWithIdentifier:(NSString*)identifier
{
	return [ZYAppKiller killAppWithIdentifier:identifier completion:nil];
}

+(void) killAppWithIdentifier:(NSString*)identifier completion:(void(^)())handler
{
	return [ZYAppKiller killAppWithSBApplication:[[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:identifier] completion:handler];
}

+(void) killAppWithSBApplication:(SBApplication*)app
{
	return [ZYAppKiller killAppWithSBApplication:app completion:nil];
}

+(void) killAppWithSBApplication:(SBApplication*)app completion:(void(^)())handler
{
	return [ZYAppKiller checkAppDead:app withTries:0 andCompletion:handler];
}

+(void) checkAppDead:(SBApplication*)app withTries:(int)tries andCompletion:(void(^)())handler
{
	/*
	BOOL isDeadOrMaxed = (app.pid == 0 || app.isRunning == NO) && tries < 5;
	if (isDeadOrMaxed)
	{
		if (handler)
		{
			handler();
		}
	}
	else
	{
		if (tries == 0)
		{
			// Try nicely
			FBApplicationProcess *process = [[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:app.bundleIdentifier];
    		[process killForReason:1 andReport:NO withDescription:@"PSY SLAYED" completion:nil];
		}
		/*else if (tries == 1)
		{
			BKSTerminateApplicationForReasonAndReportWithDescription(app.bundleIdentifier, 5, 1, @"PSY SLAYED");
		}
		else if (tries == 2)
		{
			kill(app.pid, SIGTERM);
		}
		else
		{
			// Attempt force
			kill(app.pid, SIGKILL);
		}* /
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.25 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
			[ZYAppKiller checkAppDead:app withTries:tries + 1 andCompletion:handler];
		});
	}
	*/

	[ZYAppKiller.sharedInstance->completionDictionary setObject:[handler copy] forKey:app.bundleIdentifier];
	BKSTerminateApplicationForReasonAndReportWithDescription(app.bundleIdentifier, 5, 1, @"Multiplexer requested this process to be slayed.");
}

-(void) initialize
{
	completionDictionary = [NSMutableDictionary dictionary];
	[ZYRunningAppsProvider.sharedInstance addTarget:self];
}

-(void) appDidDie:(__unsafe_unretained SBApplication*)app
{
	if (completionDictionary && [completionDictionary objectForKey:app.bundleIdentifier] != nil)
	{
		dispatch_block_t block = completionDictionary[app.bundleIdentifier];
		block();
		[completionDictionary removeObjectForKey:app.bundleIdentifier];
	}
}
@end
