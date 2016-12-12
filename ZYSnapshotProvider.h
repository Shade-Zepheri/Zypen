#import "Windows/ZYDesktopWindow.h"

@interface ZYSnapshotProvider : NSObject {
	NSCache *imageCache;
}
+(id) sharedInstance;

//-(UIImage*) snapshotForDesktop:(ZYDesktopWindow*)desktop;
//-(void) forceReloadSnapshotOfDesktop:(ZYDesktopWindow*)desktop;

-(UIImage*) storedSnapshotOfMissionControl;
-(void) storeSnapshotOfMissionControl:(UIWindow*)window;

-(UIImage*) snapshotForIdentifier:(NSString*)identifier;
-(void) forceReloadOfSnapshotForIdentifier:(NSString*)identifier;

-(UIImage*) wallpaperImage;

-(void) forceReloadEverything;
@end
