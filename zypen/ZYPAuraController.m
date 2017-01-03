#include "Interfaces.h"

@implementation ZYPAuraController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Aura" target:self];
	}

	return _specifiers;
}

- (void)viewWillAppear:(BOOL)animated {
	[super viewWillAppear:animated];
	self.navigationController.navigationController.navigationBar.tintColor = RedColor;
	self.navigationController.navigationController.navigationBar.barTintColor = DarkRedColor;
	self.navigationController.navigationController.navigationBar.titleTextAttributes = @{NSForegroundColorAttributeName : [UIColor whiteColor]};

	[UISlider appearanceWhenContainedInInstancesOfClasses:@[[self class]]].tintColor = RedColor;
	[UISwitch appearanceWhenContainedInInstancesOfClasses:@[[self class]]].onTintColor = RedColor;
	[UISegmentedControl appearanceWhenContainedInInstancesOfClasses:@[[self class]]].tintColor = RedColor;

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

@implementation ZYBackgrounderIconIndicatorOptionsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"AuraIconOptions" target:self];
	}

	return _specifiers;
}

@end

@implementation ZYBackgrounderStatusbarOptionsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"AuraStatusBarOptions" target:self];
	}

	return _specifiers;
}

@end
