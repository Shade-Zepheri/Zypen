#include "Interfaces.h"

@implementation ZYPOptionsController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Options" target:self];
	}

	return _specifiers;
}

@end
