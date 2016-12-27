#include "Interfaces.h"

@implementation ZYPAppChooserOptionsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"AppChooser" target:self];
	}

	return _specifiers;
}

@end
