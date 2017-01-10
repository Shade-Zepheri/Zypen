#import "ZYFakePhoneMode.h"

#define FAKE \
    \//if (IS_SPRINGBOARD || ignorePhoneMode) \
    \//    return %orig; \
\
    if ([%c(FakePhoneMode) shouldFakeForThisProcess]) \
    { \
        CGRect frame = (CGRect) { CGPointZero, [%c(FakePhoneMode) fakedSize] }; \
        return frame; \
    }

%hook UIDevice
- (UIUserInterfaceIdiom)userInterfaceIdiom {
    UIUserInterfaceIdiom origIdiom = %orig;

    //if (IS_SPRINGBOARD || ignorePhoneMode)
    //    return origIdiom;

    if (origIdiom != UIUserInterfaceIdiomPhone && [%c(FakePhoneMode) shouldFakeForThisProcess]) {
        return UIUserInterfaceIdiomPhone;
    }
    return origIdiom;
}
%end

%hook UIScreen
- (CGRect)_unjailedReferenceBounds {
	FAKE;
    return %orig;
}

- (CGRect)_referenceBounds {
	FAKE;
    return %orig;
}

- (CGRect)_interfaceOrientedBounds {
	FAKE;
    return %orig;
}

- (CGRect)bounds {
	FAKE;
    return %orig;
}

- (CGRect)nativeBounds {
	FAKE;
    return %orig;
}

- (CGRect)applicationFrame {
	FAKE;
    return %orig;
}

- (CGRect)_boundsForInterfaceOrientation:(int)arg1 {
	FAKE;
    return %orig;
}

- (CGRect)_applicationFrameForInterfaceOrientation:(int)arg1 usingStatusbarHeight:(CGFloat)arg2 ignoreStatusBar:(BOOL)arg3 {
	FAKE;
    return %orig;
}

- (CGRect)_applicationFrameForInterfaceOrientation:(int)arg1 usingStatusbarHeight:(CGFloat)arg2 {
	FAKE;
    return %orig;
}

- (CGRect)_applicationFrameForInterfaceOrientation:(int)arg1 {
	FAKE;
    return %orig;
}
%end
