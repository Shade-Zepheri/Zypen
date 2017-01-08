#import "ZYDefaultWidgetSection.h"
#import "ZYWidget.h"
#import "ZYWidgetSectionManager.h"
#import "headers.h"

@implementation ZYDefaultWidgetSection
+ (instancetype)sharedDefaultWidgetSection {
	SHARED_INSTANCE2(ZYDefaultWidgetSection,
		[ZYWidgetSectionManager.sharedInstance registerSection:sharedInstance]
	);
}

- (NSString*)displayName {
	return @"Widgets";
}

- (NSString*)identifier {
	return @"com.shade.zypen.widgets.sections.default";
}
@end

static __attribute__((constructor)) void cant_believe_i_forgot_this_before() {
	static id _widget = [ZYDefaultWidgetSection sharedDefaultWidgetSection];
	[ZYWidgetSectionManager.sharedInstance registerSection:_widget];
}
