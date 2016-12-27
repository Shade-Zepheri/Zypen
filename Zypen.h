@class SBApplication;

@interface ZypenExtension : NSObject
@property (nonatomic, retain) NSString *name;
@property (nonatomic, retain) NSString *zypenVersion;
@end

@interface Zypen : NSObject {
	NSMutableArray *activeExtensions;
}
+ (instancetype)sharedInstance;

- (NSString*)currentVersion;
- (BOOL)isOnSupportedOS;

- (void)registerExtension:(NSString*)name forZypenVersion:(NSString*)version;

+ (id)createSBAppToAppWorkspaceTransactionForExitingApp:(SBApplication*)app;
+ (BOOL)shouldShowControlCenterGrabberOnFirstSwipe;
@end
