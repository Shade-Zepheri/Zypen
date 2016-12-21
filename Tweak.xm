#define ZYPEN_CORE 1
#import "headers.h"
#include <execinfo.h>

BOOL $__IS_SPRINGBOARD = NO;
%ctor {
	$__IS_SPRINGBOARD = [NSBundle.mainBundle.bundleIdentifier isEqual:@"com.apple.springboard"];
}

void SET_BACKGROUNDED(id settings, BOOL value) {
#if __has_feature(objc_arc)
	// stupid ARC...
    ptrdiff_t bgOffset = ivar_getOffset(class_getInstanceVariable([settings class], "_backgrounded"));
    char *bgPtr = ((char *)(__bridge void *)settings) + bgOffset;
    memcpy(bgPtr, &value, sizeof(value));
#else
	// ARC is off, easy way
	if (value)
		object_setInstanceVariable(settings, "_backgrounded", (void*)YES); // strangely it doesn't like using the val, i have to do this.
	else
		object_setInstanceVariable(settings, "_backgrounded", (void*)NO);
#endif
}
/*

		Long way to go boys
		gonna be a several month project
		May include snippets from MUltiplexer
		Credits to Elijah Frederickson for original code
		good luck to me

*/
