#import "headers.h"
#import <SettingsKit/SKTintedListController.h>

@interface ZYBGPerAppDetailsController : SKTintedListController<SKListControllerProtocol>
{
	NSString* _appName;
	NSString* _identifier;
}
-(id)initWithAppName:(NSString*)appName identifier:(NSString*)identifier;
@end
