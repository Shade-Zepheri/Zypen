#include "Interfaces.h"

@implementation ZYPEmpoleonController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [self loadSpecifiersFromPlistName:@"Empoleon" target:self];
	}

	return _specifiers;
}

@end
