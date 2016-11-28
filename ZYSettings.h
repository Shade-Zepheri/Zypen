#import "Headers.h"

@interface ZYSettings : NSObject
@property (nonatomic, assign, readonly) BOOL showNCInstead;
@property (nonatomic, assign, readonly) BOOL reachabilityEnabled;
@property (nonatomic, assign, readonly) BOOL disableAutoDismiss;
@property (nonatomic, assign, readonly) BOOL enableRotation;
@property (nonatomic, assign, readonly) BOOL showWidgetSelector;
@property (nonatomic, assign, readonly) BOOL showBottomGrabber;
@property (nonatomic, assign, readonly) BOOL autoSizeWidgetSelector;
@property (nonatomic, assign, readonly) BOOL unifyStatusBar;

+ (instancetype)sharedSettings;

@end
