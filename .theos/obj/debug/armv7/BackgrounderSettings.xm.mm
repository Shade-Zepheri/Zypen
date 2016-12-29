#line 1 "BackgrounderSettings.xm"
#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>
#import <SettingsKit/SKListControllerProtocol.h>
#import <SettingsKit/SKTintedListController.h>
#import <Preferences/PSSwitchTableCell.h>
#import <AppList/AppList.h>
#import <substrate.h>
#import <notify.h>
#import "PDFImage.h"
#import <AppList/AppList.h>
#import "ZYBackgrounder.h"
#import <libactivator/libactivator.h>

#define PLIST_NAME @"/var/mobile/Library/Preferences/com.shade.zypen.plist"

@interface PSViewController (Protean)
-(void) viewDidLoad;
-(void) viewWillDisappear:(BOOL)animated;
- (void)viewDidAppear:(BOOL)animated;
@end

@interface PSViewController (SettingsKit2)
-(UINavigationController*)navigationController;
-(void)viewWillAppear:(BOOL)animated;
-(void)viewWillDisappear:(BOOL)animated;
@end

@interface ALApplicationTableDataSource (Private)
- (void)sectionRequestedSectionReload:(id)section animated:(BOOL)animated;
@end

@interface ReachAppBackgrounderSettingsListController: SKTintedListController<SKListControllerProtocol>
@end

@implementation ReachAppBackgrounderSettingsListController

















-(UIColor*) tintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }
-(UIColor*) switchTintColor { return [[UISwitch alloc] init].tintColor; }

-(NSString*) customTitle { return @"Aura"; }
-(BOOL) showHeartImage { return NO; }


-(void) viewDidAppear:(BOOL)arg1 {
    [super viewDidAppear:arg1];
    [super performSelector:@selector(setupHeader)];
}


-(NSArray*) customSpecifiers {
    return @[
             @{ @"footerText": @"Quickly enable or disable Aura. Relaunch apps to apply changes." },
             @{
                 @"cell": @"PSSwitchCell",
                 @"default": @YES,
                 @"defaults": @"com.shade.zypen",
                 @"key": @"backgrounderEnabled",
                 @"label": @"Enabled",
                 },

             @{ @"label": @"Activator",
                @"footerText": @"If enabled, the current app will be closed after performing the activation method.",
             },
             @{
                @"cell": @"PSLinkCell",
                @"action": @"showActivatorAction",
                @"label": @"Activation Method",
                
             },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Exit App After Menu",
                @"default": @YES,
                @"key": @"exitAppAfterUsingActivatorAction",
                @"defaults": @"com.shade.zypen",
                @"PostNotification": @"com.shade.zypen/ReloadPrefs",
             },

             @{ @"label": @"Global", @"footerText": @"" },

             @{
                @"cell": @"PSLinkListCell",
                @"label": @"Background Mode",
                @"key": @"globalBackgroundMode",
                @"validTitles": @[ @"Native",                 @"Unlimited Backgrounding Time",                  @"Force Foreground",                 @"Kill on Exit",      @"Suspend Immediately" ],
                @"validValues": @[ @(ZYBackgroundModeNative), @(ZYBackgroundModeUnlimitedBackgroundingTime),    @(ZYBackgroundModeForcedForeground), @(ZYBackgroundModeForceNone),    @(ZYBackgroundModeSuspendImmediately)],
                @"shortTitles": @[ @"Native",                 @"∞",                                             @"Forced",                           @"Disabled",                     @"SmartClose" ],
                @"default": @(ZYBackgroundModeNative),
                @"detail": @"ZYBackgroundingListItemsController",
                @"defaults": @"com.shade.zypen",
                @"PostNotification": @"com.shade.zypen/ReloadPrefs",
                @"staticTextMessage": @"Does not apply to apps enabled with differing options in the “Per App” section."
                },
             @{
                @"cell": @"PSLinkListCell",
                @"detail": @"ZYBackgrounderIconIndicatorOptionsListController",
                @"label": @"Icon Indicator Options",
            },
             @{
                @"cell": @"PSLinkListCell",
                @"detail": @"ZYBackgrounderStatusbarOptionsListController",
                @"label": @"Status Bar Indicator Options",
            },
             @{ @"label": @"Specific" },
             @{
                @"cell": @"PSLinkCell",
                @"label": @"Per App",
                @"detail": @"ZYBGPerAppController",
             },
             ];
}


-(void) showActivatorAction {
    id activator = objc_getClass("LAListenerSettingsViewController");
    if (!activator)
    {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Zypen" message:@"Activator must be installed to use this feature." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
    else
    {
        LAListenerSettingsViewController *vc = [[objc_getClass("LAListenerSettingsViewController") alloc] init];
        vc.listenerName = @"com.shade.zypen.backgrounder.togglemode";
        [self.rootController presentViewController:vc animate:YES];
    }
}
@end

@interface ZYBackgrounderIconIndicatorOptionsListController : SKTintedListController<SKListControllerProtocol, UIAlertViewDelegate>
@end

@implementation ZYBackgrounderIconIndicatorOptionsListController
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers {
    return @[
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show Icon Indicators",
                @"default": @YES,
                @"key": @"showIconIndicators",
                @"defaults": @"com.shade.zypen",
                @"PostNotification": @"com.shade.zypen/ReloadPrefs",
             },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show Native Mode Indicators",
                @"default": @NO,
                @"key": @"showNativeStateIconIndicators",
                @"defaults": @"com.shade.zypen",
                @"PostNotification": @"com.shade.zypen/ReloadPrefs",
             },
                 ];
}
@end

@interface ZYBackgrounderStatusbarOptionsListController : SKTintedListController<SKListControllerProtocol, UIAlertViewDelegate>
@end

@implementation ZYBackgrounderStatusbarOptionsListController
-(UIColor*) navigationTintColor { return [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f]; }
-(BOOL) showHeartImage { return NO; }

-(NSArray*) customSpecifiers {
    return @[
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show on Status Bar",
                @"default": @YES,
                @"key": @"shouldShowStatusBarIcons",
                @"defaults": @"com.shade.zypen",
                @"PostNotification": @"com.shade.zypen/ReloadPrefs",
             },
             @{
                @"cell": @"PSSwitchCell",
                @"label": @"Show Native in Status Bar",
                @"default": @NO,
                @"key": @"shouldShowStatusBarNativeIcons",
                @"defaults": @"com.shade.zypen",
                @"PostNotification": @"com.shade.zypen/ReloadPrefs",
             },
                 ];
}
@end
