#import "headers.h"

@interface ZYKeyboardStateListener : NSObject
+ (instancetype)sharedInstance;
@property (nonatomic, assign, readonly) BOOL visible;
@property (nonatomic, assign, readonly) CGSize size;


- (void)_setVisible:(BOOL)val;
- (void)_setSize:(CGSize)size;
@end
