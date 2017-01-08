#import "ZYWidgetHostManager.h"

@implementation ZYWidgetHostManager
+ (instancetype)sharedInstance {
	SHARED_INSTANCE2(ZYWidgetHostManager,
		sharedInstance->widgets = [NSMutableArray array]
	);
}

- (void)addWidget:(ZYWidgetBase*)widget {
	if ([widgets containsObject:widget] == NO) {
		[widgets addObject:widget];
	}
}

- (void)removeWidget:(ZYWidgetBase*)widget {
	[self removeWidgetWithIdentifier:widget.identifier];
}

- (void)removeWidgetWithIdentifier:(NSString*)identifier {
	for (ZYWidgetBase *w in widgets) {
		if ([w.identifier isEqual:identifier]) {
			[widgets removeObject:w];
			return;
		}
	}
}

- (ZYWidgetBase*)widgetForIdentifier:(NSString*)identifier {
	for (ZYWidgetBase *w in widgets) {
		if ([w.identifier isEqual:identifier]) {
			return w;
		}
	}
	return nil;
}

@end
