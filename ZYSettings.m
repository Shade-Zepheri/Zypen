#import "ZYSettings.h"

@interface ZYSettings (Private)
- (void)_prefsChanged;
@end

static void prefsChanged() {
  CFPreferencesAppSynchronize(CFSTR("com.shade.zypen"));
  [[ZYSettings sharedSettings] _prefsChanged];
}

@implementation ZYSettings

+ (id)sharedSettings {
    static dispatch_once_t p = 0;
    __strong static id _sharedObject = nil;
    dispatch_once(&p, ^{
        _sharedObject = [[self alloc] init];
    });
    return _sharedObject;
}

- (id)init {
  if((self = [super init])) {
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(),
		                        NULL,
		                        (CFNotificationCallback)prefsChanged,
		                        CFSTR("com.shade.zypen/ReloadPrefs"),
		                        NULL,
		                        CFNotificationSuspensionBehaviorDeliverImmediately);
    [self _prefsChanged];
  }
  return self;
}

- (void)_prefsChanged {
  @autoreleasepool {
    CFPreferencesAppSynchronize(CFSTR("com.shade.zypen"));
  	_showNCInstead = !CFPreferencesCopyAppValue(CFSTR("showNCInstead"), CFSTR("com.shade.zypen")) ? NO : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("showNCInstead"), CFSTR("com.shade.zypen")) boolValue];
    _reachabilityEnabled = !CFPreferencesCopyAppValue(CFSTR("reachabilityEnabled"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("reachabilityEnabled"), CFSTR("com.shade.zypen")) boolValue];
    _disableAutoDismiss = !CFPreferencesCopyAppValue(CFSTR("disableAutoDismiss"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("disableAutoDismiss"), CFSTR("com.shade.zypen")) boolValue];
    _enableRotation = !CFPreferencesCopyAppValue(CFSTR("enableRotation"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("enableRotation"), CFSTR("com.shade.zypen")) boolValue];
    _showWidgetSelector = !CFPreferencesCopyAppValue(CFSTR("showWidgetSelector"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("showWidgetSelector"), CFSTR("com.shade.zypen")) boolValue];
    _showBottomGrabber = !CFPreferencesCopyAppValue(CFSTR("showBottomGrabber"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("showBottomGrabber"), CFSTR("com.shade.zypen")) boolValue];
    _autoSizeWidgetSelector = !CFPreferencesCopyAppValue(CFSTR("autoSizeWidgetSelector"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("autoSizeWidgetSelector"), CFSTR("com.shade.zypen")) boolValue];
    _unifyStatusBar = !CFPreferencesCopyAppValue(CFSTR("unifyStatusBar"), CFSTR("com.shade.zypen")) ? YES : [(__bridge id)CFPreferencesCopyAppValue(CFSTR("unifyStatusBar"), CFSTR("com.shade.zypen")) boolValue];
  }
}

@end
