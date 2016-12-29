#include "Interfaces.h"

@implementation ZYPAuraController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Aura" target:self];
	}

	return _specifiers;
}

@end
