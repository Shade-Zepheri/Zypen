#include "Interfaces.h"
#import "ZYThemeManager.h"

@implementation ZYPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Zypen" target:self];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	CGRect frame = CGRectMake(0, 0, self.table.bounds.size.width, 127);

	UIImage *headerImage = [[UIImage alloc]
		initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/zypen.bundle"] pathForResource:@"zypenHeader" ofType:@"png"]];

	UIImageView *headerView = [[UIImageView alloc] initWithFrame:frame];
	[headerView setImage:headerImage];
	headerView.backgroundColor = [UIColor blackColor];
	[headerView setContentMode:UIViewContentModeScaleAspectFit];
	[headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

	self.table.tableHeaderView = headerView;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	CGRect wrapperFrame = ((UIView *)self.table.subviews[0]).frame; // UITableViewWrapperView
	CGRect frame = CGRectMake(wrapperFrame.origin.x, self.table.tableHeaderView.frame.origin.y, wrapperFrame.size.width, self.table.tableHeaderView.frame.size.height);

	self.table.tableHeaderView.frame = frame;
}

- (void)resetData {
		UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Zypen"
                               message:@"Please confirm your choice to reset all settings & respring."
                               preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
		  handler:^(UIAlertAction * action) {
				CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.shade.zypen/ResetSettings"), nil, nil, YES);
		}];

		UIAlertAction* cancelAction = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel
			handler:^(UIAlertAction * action) {
		}];

		[alert addAction:defaultAction];
		[alert addAction:cancelAction];
		[self presentViewController:alert animated:YES completion:nil];
}

- (NSArray*)themeTitles {
    NSArray *themes = [ZYThemeManager.sharedInstance allThemes];
    NSMutableArray *ret = [NSMutableArray array];
    for (ZYTheme *theme in themes) {
			[ret addObject:theme.themeName];
		}
    return ret;
}

- (NSArray*)themeValues {
    NSArray *themes = [ZYThemeManager.sharedInstance allThemes];
    NSMutableArray *ret = [NSMutableArray array];
    for (ZYTheme *theme in themes) {
			[ret addObject:theme.themeIdentifier];
		}
    return ret;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationController.navigationBar.tintColor = DarkPurpleColor;
	self.navigationController.navigationController.navigationBar.barTintColor = PurpleColor;
	self.navigationController.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};

	[UISlider appearanceWhenContainedInInstancesOfClasses:@[[self class]]].tintColor = DarkPurpleColor;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[[self class]]].onTintColor = DarkPurpleColor;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[[self class]]].tintColor = DarkPurpleColor;

	prevStatusStyle = [[UIApplication sharedApplication] statusBarStyle];
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewWillDisappear:(BOOL)animated {
	[super viewWillDisappear:animated];
	self.navigationController.navigationController.navigationBar.tintColor = nil;
	self.navigationController.navigationController.navigationBar.barTintColor = nil;
	self.navigationController.navigationController.navigationBar.titleTextAttributes = nil;

	[[UIApplication sharedApplication] setStatusBarStyle:prevStatusStyle];
	prevStatusStyle = [[UIApplication sharedApplication] statusBarStyle];
}

@end
