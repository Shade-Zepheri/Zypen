#include "Interfaces.h"

@implementation ZYPAuraController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Aura" target:self];
	}

	return _specifiers;
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
