#include "Interfaces.h"

@implementation ZYPOptionsController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Options" target:self] retain];
	}

	return _specifiers;
}

@end
