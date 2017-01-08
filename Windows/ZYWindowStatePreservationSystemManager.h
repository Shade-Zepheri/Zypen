#import "headers.h"
#import "ZYDesktopWindow.h"
#import "ZYWindowBar.h"

 typedef struct {
	CGPoint center;
	CGAffineTransform transform;
} ZYPreservedWindowInformation;

typedef struct {
	NSUInteger index;
	NSArray *openApps; //NSArray<NSString>
} ZYPreservedDesktopInformation;

@interface ZYWindowStatePreservationSystemManager : NSObject {
	NSMutableDictionary *dict;
}
+ (instancetype)sharedInstance;

- (void)loadInfo;
- (void)saveInfo;

// Desktop
- (void)saveDesktopInformation:(ZYDesktopWindow*)desktop;
- (BOOL)hasDesktopInformationAtIndex:(NSInteger)index;
- (ZYPreservedDesktopInformation)desktopInformationForIndex:(NSInteger)index;

// Window
- (void)saveWindowInformation:(ZYWindowBar*)window;
- (BOOL)hasWindowInformationForIdentifier:(NSString*)appIdentifier;
- (ZYPreservedWindowInformation)windowInformationForAppIdentifier:(NSString*)identifier;
- (void)removeWindowInformationForIdentifier:(NSString*)appIdentifier;
@end
