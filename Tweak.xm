#define ZYPEN_CORE 1
#import "headers.h"
#include <execinfo.h>

BOOL $__IS_SPRINGBOARD = NO;
%ctor {
	$__IS_SPRINGBOARD = [NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"];
}

/*

		Long way to go boys
		gonna be a several month project
		May include snippets from Multiplexer
		Credits to Elijah Frederickson for original code
		good luck to me

*/
