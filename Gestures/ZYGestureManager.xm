#import "headers.h"
#import "ZYGestureManager.h"
#import "ZYGestureCallback.h"

@implementation ZYGestureManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(ZYGestureManager,
		sharedInstance->gestures = [NSMutableArray array];
		sharedInstance->ignoredAreas = [NSMutableDictionary dictionary];
	);
}

- (void)sortGestureRecognizers {
	[gestures sortUsingComparator:^NSComparisonResult(ZYGestureCallback *a, ZYGestureCallback *b) {
		if (a.priority > b.priority) {
			return NSOrderedAscending;
		} else if (a.priority < b.priority) {
			return NSOrderedDescending;
		}
		return NSOrderedSame;
	}];
}

- (void)addGestureRecognizer:(ZYGestureCallbackBlock)callbackBlock withCondition:(ZYGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier {
	[self addGestureRecognizer:callbackBlock withCondition:conditionBlock forEdge:screenEdge identifier:identifier priority:ZYGesturePriorityDefault];
}

- (void)addGesture:(ZYGestureCallback*)callback {
	BOOL found = NO;
	for (ZYGestureCallback *callback_ in gestures) {
		if ([callback_.identifier isEqual:callback.identifier]) {
			found = YES;
			break;
		}
	}
	if (!found) {
		[gestures addObject:callback];
		[self sortGestureRecognizers];
	}
}

- (void)addGestureRecognizer:(ZYGestureCallbackBlock)callbackBlock withCondition:(ZYGestureConditionBlock)conditionBlock forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority {
	ZYGestureCallback *callback = [[ZYGestureCallback alloc] init];
	callback.callbackBlock = [callbackBlock copy];
	callback.conditionBlock = [conditionBlock copy];
	callback.screenEdge = screenEdge;
	callback.identifier = identifier;
	callback.priority = priority;

	[self addGesture:callback];
}

- (void)addGestureRecognizerWithTarget:(NSObject<ZYGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier {
	[self addGestureRecognizerWithTarget:target forEdge:screenEdge identifier:identifier priority:ZYGesturePriorityDefault];
}

- (void)addGestureRecognizerWithTarget:(NSObject<ZYGestureCallbackProtocol>*)target forEdge:(UIRectEdge)screenEdge identifier:(NSString*)identifier priority:(NSUInteger)priority {
	ZYGestureCallback *callback = [[ZYGestureCallback alloc] init];
	callback.target = target;
	callback.screenEdge = screenEdge;
	callback.identifier = identifier;
	callback.priority = priority;

	[self addGesture:callback];
}

- (void)removeGestureWithIdentifier:(NSString*)identifier {
	int i = 0;
	while (i < gestures.count) {
		ZYGestureCallback *callback = [self callbackAtIndex:i];
		if ([callback.identifier isEqual:identifier]) {
			[gestures removeObjectAtIndex:i];
			i--; // offset for the change
		}

		i++;
	}
}

- (ZYGestureCallback*)callbackAtIndex:(NSUInteger)index {
	ZYGestureCallback *ret = gestures[index];
	//[gestures[index] getValue:&ret];
	return ret;
}

- (BOOL)canHandleMovementWithPoint:(CGPoint)point velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge {
	for (int i = 0; i < gestures.count; i++) {
		ZYGestureCallback *callback = [self callbackAtIndex:i];
		if (callback.screenEdge & edge) {
			if (callback.conditionBlock) {
				if (callback.conditionBlock(point, velocity)) {
					return YES;
				}
			} else if (callback.target && [callback.target respondsToSelector:@selector(ZYGestureCallback_canHandle:velocity:)]) {
				if ([callback.target ZYGestureCallback_canHandle:point velocity:velocity]) {
					return YES;
				}
			}
		}
	}
	return NO;
}

- (BOOL)handleMovementOrStateUpdate:(UIGestureRecognizerState)state withPoint:(CGPoint)point velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge {
	// If we don't do this check here, but in canHandleMovementWithPoint:forEdge:, the recognizer hooks will not begin tracking the swipe
	// This is an issue if someone calls stopIgnoringSwipesForIdentifier: while a swipe is going on.
	/*for (NSString *key in ignoredAreas.allKeys)
	{
		NSValue *value = ignoredAreas[key];
		CGRect rect = [value CGRectValue];
		if (CGRectContainsPoint(rect, point))
			return NO; // IGNORED
	}*/

	BOOL ret = NO;
	for (int i = 0; i < gestures.count; i++) {
		ZYGestureCallback *callback = [self callbackAtIndex:i];

		NSValue *value = [ignoredAreas objectForKey:callback.identifier];
		if (value) {
			CGRect rect = [value CGRectValue];
			if (CGRectContainsPoint(rect, point)) {
				continue;
			}
		}
		if (callback.screenEdge & edge) {
			BOOL isThisCallbackCapable = NO;
			if (callback.conditionBlock) {
				if (callback.conditionBlock(point, velocity)) {
					isThisCallbackCapable = YES;
				}
			} else if (callback.target && [callback.target respondsToSelector:@selector(ZYGestureCallback_canHandle:velocity:)]) {
				if ([callback.target ZYGestureCallback_canHandle:point velocity:velocity]) {
					isThisCallbackCapable = YES;
				}
			}
			if (isThisCallbackCapable) {
				if (callback.callbackBlock) {
					ZYGestureCallbackResult result = callback.callbackBlock(state, point, velocity);
					if (result == ZYGestureCallbackResultSuccessAndContinue || result == ZYGestureCallbackResultSuccessAndStop) {
						ret = YES;
					}
					if (result == ZYGestureCallbackResultSuccessAndStop) {
						break;
					}
				} else if (callback.target && [callback.target respondsToSelector:@selector(ZYGestureCallback_handle:withPoint:velocity:forEdge:)]) {
					ZYGestureCallbackResult result = [callback.target ZYGestureCallback_handle:state withPoint:point velocity:velocity forEdge:edge];
					if (result == ZYGestureCallbackResultSuccessAndContinue || result == ZYGestureCallbackResultSuccessAndStop) {
						ret = YES;
					}
					if (result == ZYGestureCallbackResultSuccessAndStop) {
						break;
					}
				}
			}
		}
	}
	return ret;
}

- (void)ignoreSwipesBeginningInRect:(CGRect)area forIdentifier:(NSString*)identifier {
	[ignoredAreas setObject:[NSValue valueWithCGRect:area] forKey:identifier];
}

- (void)stopIgnoringSwipesForIdentifier:(NSString*)identifier {
	[ignoredAreas removeObjectForKey:identifier];
}

- (void)ignoreSwipesBeginningOnSide:(UIRectEdge)side aboveYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier {
	if (side != UIRectEdgeLeft && side != UIRectEdgeRight) {
		@throw [NSException exceptionWithName:@"InvalidRectEdgeException" reason:@"Expected UIRectEdgeLeft or UIRectEdgeRight" userInfo:nil];
	}
	CGRect r = CGRectMake(side == UIRectEdgeLeft ? 0 : UIScreen.mainScreen.bounds.size.width / 2.0 , 0, UIScreen.mainScreen.bounds.size.width / 2.0, axis);
	[self ignoreSwipesBeginningInRect:r forIdentifier:identifier];
}

- (void)ignoreSwipesBeginningOnSide:(UIRectEdge)side belowYAxis:(NSUInteger)axis forIdentifier:(NSString*)identifier {
	if (side != UIRectEdgeLeft && side != UIRectEdgeRight) {
		@throw [NSException exceptionWithName:@"InvalidRectEdgeException" reason:@"Expected UIRectEdgeLeft or UIRectEdgeRight" userInfo:nil];
	}
	CGRect r = CGRectMake(side == UIRectEdgeLeft ? 0 : UIScreen.mainScreen.bounds.size.width / 2.0 , axis, UIScreen.mainScreen.bounds.size.width / 2.0, UIScreen.mainScreen.bounds.size.height - axis);
	[self ignoreSwipesBeginningInRect:r forIdentifier:identifier];
}
@end
