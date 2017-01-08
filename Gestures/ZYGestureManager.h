 #import "headers.h"

@class ZYGestureCallback;

typedef NS_ENUM(NSInteger, ZYGestureCallbackResult) {
	ZYGestureCallbackResultSuccessAndContinue,
	ZYGestureCallbackResultFailure,
	ZYGestureCallbackResultSuccessAndStop,

	ZYGestureCallbackResultSuccess = ZYGestureCallbackResultSuccessAndContinue,
};

@protocol ZYGestureCallbackProtocol
- (BOOL)ZYGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity;
- (ZYGestureCallbackResult)ZYGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge;
@end

typedef BOOL(^ZYGestureConditionBlock)(CGPoint location, CGPoint velocity);
typedef ZYGestureCallbackResult(^ZYGestureCallbackBlock)(UIGestureRecognizerState state, CGPoint location, CGPoint velocity);

const NSUInteger ZYGesturePriorityLow = 0;
const NSUInteger ZYGesturePriorityHigh = 10;
const NSUInteger ZYGesturePriorityDefault = ZYGesturePriorityLow;

@interface ZYGestureManager : NSObject {
	NSMutableArray *gestures;
	NSMutableDictionary *ignoredAreas;
}
+ (instancetype) sharedInstance;

- (void)addGestureRecognizer:(ZYGestureCallbackBlock)callbackBlock withCondition:(ZYGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority;
- (void)addGestureRecognizer:(ZYGestureCallbackBlock)callbackBlock withCondition:(ZYGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier;
- (void)addGestureRecognizerWithTarget:(NSObject<ZYGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier;
- (void)addGestureRecognizerWithTarget:(NSObject<ZYGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority;
- (void)addGesture:(ZYGestureCallback*)callback;
- (void)removeGestureWithIdentifier:(NSString*)identifier;

- (BOOL)canHandleMovementWithPoint:(CGPoint)point velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge;
- (BOOL)handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge;

- (void)ignoreSwipesBeginningInRect:(CGRect)area forIdentifier:(NSString*)identifier;
- (void)stopIgnoringSwipesForIdentifier:(NSString*)identifier;
- (void)ignoreSwipesBeginningOnSide:(UIRectEdge)side aboveYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier;
- (void)ignoreSwipesBeginningOnSide:(UIRectEdge)side belowYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier;
@end
