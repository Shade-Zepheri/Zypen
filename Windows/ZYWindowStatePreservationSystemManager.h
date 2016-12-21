#import "headers.h"
#import "ZYDesktopWindow.h"
#import "ZYWindowBar.h"

struct ZYPreservedWindowInformation {
	CGPoint center;
	CGAffineTransform transform;
};

struct ZYPreservedDesktopInformation {
	NSUInteger index;
	NSArray *openApps; //NSArray<NSString>
};

@interface ZYWindowStatePreservationSystemManager : NSObject {
	NSMutableDictionary *dict;
}
+(id) sharedInstance;

-(void) loadInfo;
-(void) saveInfo;

// Desktop
-(void) saveDesktopInformation:(ZYDesktopWindow*)desktop;
-(BOOL) hasDesktopInformationAtIndex:(NSInteger)index;
-(ZYPreservedDesktopInformation) desktopInformationForIndex:(NSInteger)index;

// Window
-(void) saveWindowInformation:(ZYWindowBar*)window;
-(BOOL) hasWindowInformationForIdentifier:(NSString*)appIdentifier;
-(ZYPreservedWindowInformation) windowInformationForAppIdentifier:(NSString*)identifier;
-(void) removeWindowInformationForIdentifier:(NSString*)appIdentifier;
@end
