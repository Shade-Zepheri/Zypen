#import "headers.h"
#import "ZYFavoriteAppsWidget.h"
#import "ZYReachabilityManager.h"
#import "ZYWidgetSectionManager.h"
#import "ZYSettings.h"

@interface ZYFavoriteAppsWidget () {
	CGFloat savedX;
}
@end

@implementation ZYFavoriteAppsWidget
- (BOOL)enabled {
  return [ZYSettings.sharedSettings showFavorites];
}

- (NSInteger)sortOrder {
  return 2;
}

- (NSString*)displayName {
  return @"Favorites";
}

- (NSString*)identifier {
  return @"com.shade.zypen.widgets.sections.favoriteapps";
}

- (CGFloat)titleOffset {
  return savedX;
}

- (UIView*)viewForFrame:(CGRect)frame preferredIconSize:(CGSize)size_ iconsThatFitPerLine:(NSInteger)iconsPerLine spacing:(CGFloat)spacing {
	CGSize size = [%c(SBIconView) defaultIconSize];
	spacing = (frame.size.width - (iconsPerLine * size.width)) / iconsPerLine;
	NSString *currentBundleIdentifier = [[UIApplication sharedApplication] _accessibilityFrontMostApplication].bundleIdentifier;
	if (!currentBundleIdentifier) {
    return nil;
  }
	CGSize contentSize = CGSizeMake(spacing / 2.0, 10);
	CGFloat interval = (size.width + spacing) * iconsPerLine;
	NSInteger intervalCount = 1;
	BOOL isTop = YES;
	BOOL hasSecondRow = NO;
	SBApplication *app = nil;
	CGFloat width = interval;
	savedX = spacing / 2.0;

	NSMutableArray *favorites = [ZYSettings.sharedSettings favoriteApps];
	[favorites removeObject:currentBundleIdentifier];
	if (favorites.count == 0) {
    return nil;
  }

	UIScrollView *favoritesView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, 200)];
	favoritesView.backgroundColor = [UIColor clearColor];
	favoritesView.pagingEnabled = [ZYSettings.sharedSettings pagingEnabled];
	for (NSString *str in favorites) {
		app = [[%c(SBApplicationController) sharedInstance] applicationWithBundleIdentifier:str];
    SBApplicationIcon *icon = [[%c(SBApplicationIcon) alloc] initWithApplication:app];
    UIImageView *iconView = [[UIImageView alloc] initWithImage:[icon getIconImage:1]];
    if (!iconView) {
      continue;
    }

    if (interval != 0 && contentSize.width + iconView.frame.size.width > interval * intervalCount) {
			if (isTop) {
				contentSize.height += size.height + 10;
				contentSize.width -= interval;
			} else {
				intervalCount++;
				contentSize.height -= (size.height + 10);
				width += interval;
			}
			hasSecondRow = YES;
			isTop = !isTop;
		}
				iconView.userInteractionEnabled = YES;
        iconView.frame = CGRectMake(contentSize.width, contentSize.height, iconView.frame.size.width, iconView.frame.size.height);

        iconView.tag = app.pid;
        iconView.restorationIdentifier = app.bundleIdentifier;
        UITapGestureRecognizer *iconViewTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(appViewItemTap:)];
        [iconView addGestureRecognizer:iconViewTapGestureRecognizer];

        [favoritesView addSubview:iconView];

        contentSize.width += iconView.frame.size.width + spacing;
	}
	contentSize.width = width;
	contentSize.height = 10 + ((size.height + 10) * (hasSecondRow ? 2 : 1));
	frame = favoritesView.frame;
	frame.size.height = contentSize.height;
	favoritesView.frame = frame;
	[favoritesView setContentSize:contentSize];
	return favoritesView;
}

- (void)appViewItemTap:(UIGestureRecognizer*)gesture {
	[GET_SBWORKSPACE appViewItemTap:gesture];
	//[[ZYReachabilityManager sharedInstance] launchTopAppWithIdentifier:gesture.view.restorationIdentifier];
}
@end

%ctor {
	static id _widget = [[ZYFavoriteAppsWidget alloc] init];
	[ZYWidgetSectionManager.sharedInstance registerSection:_widget];
}
