#include "Interfaces.h"

@implementation ZYPAppChooserOptionsListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"AppChooser" target:self] retain];
	}

	return _specifiers;
}

@end
