#import "ZYGestureManager.h"

@interface ZYGestureCallback : NSObject

@property (nonatomic, copy) ZYGestureCallbackBlock callbackBlock;
@property (nonatomic, copy) ZYGestureConditionBlock conditionBlock;
// OR
@property (nonatomic, strong) NSObject<ZYGestureCallbackProtocol> *target;

@property (nonatomic) UIRectEdge screenEdge;
@property (nonatomic) NSUInteger priority;
@property (nonatomic, retain) NSString *identifier;

@end
