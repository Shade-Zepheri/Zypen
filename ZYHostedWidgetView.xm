#import "ZYHostedWidgetView.h"
#import "ZYWidgetBase.h"
#import "ZYWidgetHostManager.h"

@interface ZYHostedWidgetView () {
	ZYWidgetBase *widget;
}
@end

@implementation ZYHostedWidgetView
- (SBApplication*)app {
  return nil;
}

- (NSString*)displayName {
  return [self loadWidget].displayName;
}

- (ZYWidgetBase*)loadWidget {
	widget = [ZYWidgetHostManager.sharedInstance widgetForIdentifier:self.bundleIdentifier];
	return widget;
}

- (void)preloadApp {
	[self loadWidget];
}

- (void)loadApp {
	widget.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
	[self addSubview:widget];
	[widget didAppear];
}

- (void)unloadApp {
	[widget didDisappear];
	[widget removeFromSuperview];
}
@end
