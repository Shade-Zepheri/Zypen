#import "ZYBackgrounder.h"
#import "ZYSettings.h"
#import <libstatusbar/LSStatusBarItem.h>
#import <applist/ALApplicationList.h>
#import "ColorBadges.h"
#import "Anemone.h"

NSMutableDictionary *indicatorStateDict = [[[NSMutableDictionary alloc] init] retain];
#define SET_INFO_(x, y)    indicatorStateDict[x] = [NSNumber numberWithInt:y]
#define GET_INFO_(x)       [indicatorStateDict[x] intValue]
#define SET_INFO(y)        if (self.icon && self.icon.application) SET_INFO_(self.icon.application.bundleIdentifier, y);
#define GET_INFO           (self.icon && self.icon.application ? GET_INFO_(self.icon.application.bundleIdentifier) : ZYIconIndicatorViewInfoNone)


NSString *stringFromIndicatorInfo(ZYIconIndicatorViewInfo info) {
	NSString *ret = @"";

	if (info & ZYIconIndicatorViewInfoNone)
		return nil;

	if ([[%c(ZYSettings) sharedSettings] showNativeStateIconIndicators] && (info & ZYIconIndicatorViewInfoNative)) {
		ret = [ret stringByAppendingString:@"N"];
	}
	if (info & ZYIconIndicatorViewInfoForced) {
		ret = [ret stringByAppendingString:@"F"];
	}
	if (info & ZYIconIndicatorViewInfoSuspendImmediately) {
		ret = [ret stringByAppendingString:@"ll"];
	}
	if (info & ZYIconIndicatorViewInfoUnkillable) {
		ret = [ret stringByAppendingString:@"U"];
	}
	if (info & ZYIconIndicatorViewInfoUnlimitedBackgroundTime) {
		ret = [ret stringByAppendingString:@"∞"];
	}
	return ret;
}

%hook SBIconView
%new - (void)ZY_updateIndicatorView:(ZYIconIndicatorViewInfo)info {
	@autoreleasepool {
		if (info == ZYIconIndicatorViewInfoTemporarilyInhibit || info == ZYIconIndicatorViewInfoInhibit) {
			[[self viewWithTag:9962] removeFromSuperview];
			[self ZY_setIsIconIndicatorInhibited:YES];
			if (info == ZYIconIndicatorViewInfoTemporarilyInhibit) {
				dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
					[self ZY_setIsIconIndicatorInhibited:NO showAgainImmediately:NO];
				});
			}
			return;
		} else if (info == ZYIconIndicatorViewInfoUninhibit) {
			[self ZY_setIsIconIndicatorInhibited:NO showAgainImmediately:NO];
		}

		NSString *text = stringFromIndicatorInfo(info);

		if (
			[self ZY_isIconIndicatorInhibited] ||
			(!text || text.length == 0) || // OR info == ZYIconIndicatorViewInfoNone
			(!self.icon || !self.icon.application || !self.icon.application.isRunning || ![ZYBackgrounder.sharedInstance shouldShowIndicatorForIdentifier:self.icon.application.bundleIdentifier]) ||
			![[%c(ZYSettings) sharedSettings] backgrounderEnabled]) {
			[[self viewWithTag:9962] removeFromSuperview];
			return;
		}

		UILabel *badge = (UILabel*)[self viewWithTag:9962];
		if (!badge) {
			badge = [[[UILabel alloc] init] retain];
			badge.tag = 9962;

			badge.textAlignment = NSTextAlignmentCenter;
			badge.clipsToBounds = YES;
			badge.font = [%c(SBIconBadgeView) _textFont];

			// Note that my macros for this deal with the situation where ColorBadges is not installed
			badge.backgroundColor = GET_COLORBADGES_COLOR(self.icon, THEMED(backgroundingIndicatorBackgroundColor));

			//badge.textColor = GET_ACCEPTABLE_TEXT_COLOR(badge.backgroundColor, THEMED(backgroundingIndicatorTextColor));
			if (HAS_COLORBADGES && [%c(ColorBadges) isEnabled]) {
				NSInteger bgColor = RGBFromUIColor(badge.backgroundColor);
				NSInteger txtColor = RGBFromUIColor(THEMED(backgroundingIndicatorTextColor));

				if ([%c(ColorBadges) isDarkColor:bgColor]) {
					// dark color
					if ([%c(ColorBadges) isDarkColor:txtColor]) {
						// dark + dark
						badge.textColor = [UIColor whiteColor];
					} else {
						// dark + light
						badge.textColor = THEMED(backgroundingIndicatorTextColor);
					}
				} else {
					// light color
					if ([%c(ColorBadges) isDarkColor:txtColor]) {
						// light + dark
						badge.textColor = THEMED(backgroundingIndicatorTextColor);
					} else {
						//light + light
						badge.textColor = [UIColor blackColor];
					}
				}
			} else {
				badge.textColor = THEMED(backgroundingIndicatorTextColor);
			}
			UIImage *bgImage = [%c(SBIconBadgeView) _checkoutBackgroundImage];
			if (HAS_ANEMONE && [[[%c(ANEMSettingsManager) sharedManager] themeSettings] containsObject:@"ModernBadges"]) {
				badge.backgroundColor = [UIColor colorWithPatternImage:bgImage];
			}

			[self addSubview:badge];
			[badge release];

			CGPoint overhang = [%c(SBIconBadgeView) _overhang];
			badge.frame = CGRectMake(-overhang.x, -overhang.y, bgImage.size.width, bgImage.size.height);
			badge.layer.cornerRadius = MAX(badge.frame.size.width, badge.frame.size.height) / 2.0;
		}

		if (HAS_ANEMONE && [[[%c(ANEMSettingsManager) sharedManager] themeSettings] containsObject:@"ModernBadges"]) {
			UIImageView *textImageView = (UIImageView*)[badge viewWithTag:42];
			if (!textImageView) {
				CGFloat padding = [objc_getClass("SBIconBadgeView") _textPadding];

				textImageView = [[UIImageView alloc] initWithFrame:CGRectMake(padding, padding, badge.frame.size.width - (padding * 2.0), badge.frame.size.height - (padding * 2.0))];
				textImageView.center = CGPointMake((badge.frame.size.width / 2.0) + [%c(SBIconBadgeView) _textOffset].x, (badge.frame.size.height / 2.0) + [%c(SBIconBadgeView) _textOffset].y);
				textImageView.tag = 42;
				[badge addSubview:textImageView];
			}

			UIImage *textImage = [%c(SBIconBadgeView) _checkoutImageForText:text highlighted:NO];
			textImageView.image = textImage;
		} else {
			[badge performSelectorOnMainThread:@selector(setText:) withObject:text waitUntilDone:YES];
		}
		SET_INFO(info);
	}
}

%new - (void)ZY_updateIndicatorViewWithExistingInfo {
	//if ([self viewWithTag:9962])
		[self ZY_updateIndicatorView:GET_INFO];
}

%new - (void)ZY_setIsIconIndicatorInhibited:(BOOL)value {
	[self ZY_setIsIconIndicatorInhibited:value showAgainImmediately:YES];
}

%new - (void)ZY_setIsIconIndicatorInhibited:(BOOL)value showAgainImmediately:(BOOL)value2 {
    objc_setAssociatedObject(self, @selector(ZY_isIconIndicatorInhibited), value ? (id)kCFBooleanTrue : (id)kCFBooleanFalse, OBJC_ASSOCIATION_ASSIGN);
    if (value2 || value) {
			[self ZY_updateIndicatorViewWithExistingInfo];
		}
}

- (void)dealloc {
	if (self) {
		UIView *view = [self viewWithTag:9962];
		if (view) {
			[view removeFromSuperview];
		}
	}
	%orig;
}

%new - (BOOL)ZY_isIconIndicatorInhibited {
    return [objc_getAssociatedObject(self, @selector(ZY_isIconIndicatorInhibited)) boolValue];
}

- (void)layoutSubviews {
    %orig;

    //if ([self viewWithTag:9962] == nil)
    // this is back in, again, to try to fix "Smartclose badges show randomly in the app switcher for random applications even though I only have one app smart closed"
	//    [self ZY_updateIndicatorView:GET_INFO];
}

- (void)setIsEditing:(_Bool)arg1 animated:(_Bool)arg2 {
	%orig;

	if (arg1) {
		// inhibit icon indicator
		[self ZY_setIsIconIndicatorInhibited:YES];
	} else {
		[self ZY_setIsIconIndicatorInhibited:NO];
	}
}
%end

NSMutableDictionary *lsbitems = [[[NSMutableDictionary alloc] init] retain];

%hook SBApplication

%new - (void)ZY_addStatusBarIconForSelfIfOneDoesNotExist {
	if (objc_getClass("LSStatusBarItem") && ![lsbitems objectForKey:self.bundleIdentifier] && [ZYBackgrounder.sharedInstance shouldShowStatusBarIconForIdentifier:self.bundleIdentifier]) {
		if ([%c(SBIconViewMap) respondsToSelector:@selector(homescreenMap)]) {
			if ([[[[%c(SBIconViewMap) homescreenMap] iconModel] visibleIconIdentifiers] containsObject:self.bundleIdentifier]) {
				ZYIconIndicatorViewInfo info = [ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
				BOOL native = (info & ZYIconIndicatorViewInfoNative);
				if ((info & ZYIconIndicatorViewInfoNone) == 0 && (!native || [[%c(ZYSettings) sharedSettings] shouldShowStatusBarNativeIcons])) {
		    	LSStatusBarItem *item = [[%c(LSStatusBarItem) alloc] initWithIdentifier:[NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier] alignment:StatusBarAlignmentLeft];
		    	if (![item customViewClass]) {
						item.customViewClass = @"ZYAppIconStatusBarIconView";
					}
	        item.imageName = [NSString stringWithFormat:@"multiplexer-%@",self.bundleIdentifier];
	    		lsbitems[self.bundleIdentifier] = item;
	    	}
			}
		} else {
			if ([[[[[%c(SBIconController) sharedInstance] homescreenIconViewMap] iconModel] visibleIconIdentifiers] containsObject:self.bundleIdentifier]) {
				ZYIconIndicatorViewInfo info = [ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier];
				BOOL native = (info & ZYIconIndicatorViewInfoNative);
				if ((info & ZYIconIndicatorViewInfoNone) == 0 && (!native || [[%c(ZYSettings) sharedSettings] shouldShowStatusBarNativeIcons])) {
			    	LSStatusBarItem *item = [[%c(LSStatusBarItem) alloc] initWithIdentifier:[NSString stringWithFormat:@"zypen-%@",self.bundleIdentifier] alignment:StatusBarAlignmentLeft];
			    	if (![item customViewClass]) {
							item.customViewClass = @"ZYAppIconStatusBarIconView";
						}
		        item.imageName = [NSString stringWithFormat:@"zypen-%@",self.bundleIdentifier];
		    		lsbitems[self.bundleIdentifier] = item;
		    }
	    }
		}
	}
}

- (void)setApplicationState:(NSUInteger)arg1 {
    %orig;

    if (!self.isRunning) {
    	[ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:ZYIconIndicatorViewInfoNone];
    	//SET_INFO_(self.bundleIdentifier, ZYIconIndicatorViewInfoNone);
    	[lsbitems removeObjectForKey:self.bundleIdentifier];
    } else {
    	if ([self respondsToSelector:@selector(ZY_addStatusBarIconForSelfIfOneDoesNotExist)]) {
				[self performSelector:@selector(ZY_addStatusBarIconForSelfIfOneDoesNotExist)];
			}
		[ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:[ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]];
		SET_INFO_(self.bundleIdentifier, [ZYBackgrounder.sharedInstance allAggregatedIndicatorInfoForIdentifier:self.bundleIdentifier]);
    }
}

%new + (void)ZY_clearAllStatusBarIcons {
	[lsbitems removeAllObjects];
}

- (void)didAnimateActivation {
	//[ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:ZYIconIndicatorViewInfoUninhibit];
	[ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:ZYIconIndicatorViewInfoTemporarilyInhibit];
	%orig;
}

- (void)willAnimateActivation {
	[ZYBackgrounder.sharedInstance updateIconIndicatorForIdentifier:self.bundleIdentifier withInfo:ZYIconIndicatorViewInfoInhibit];
	%orig;
}
%end

%hook SBIconViewMap
- (id)_iconViewForIcon:(unsafe_id)arg1 {
    SBIconView *iconView = %orig;
    [iconView ZY_updateIndicatorViewWithExistingInfo];
    return iconView;
}
%end

%group libstatusbar
@interface ZYAppIconStatusBarIconView : UIView
@property (nonatomic, retain) UIStatusBarItem *item;
@end

@interface UIStatusBarCustomItem : UIStatusBarItem
@end

inline NSString *getAppNameFromIndicatorName(NSString *indicatorName) {
	return [indicatorName substringFromIndex:(@"zypen-").length];
}

%subclass ZYAppIconStatusBarIconView : UIStatusBarCustomItemView
- (id)contentsImage {
	UIImage *img = [ALApplicationList.sharedApplicationList iconOfSize:15 forDisplayIdentifier:getAppNameFromIndicatorName(self.item.indicatorName)];
    return [_UILegibilityImageSet imageFromImage:img withShadowImage:img];
}
- (CGFloat)standardPadding {
	return 4;
}

%end
%hook UIStatusBarCustomItem
- (NSUInteger)leftOrder {
	if ([self.indicatorName hasPrefix:@"zypen-"]) {
		return 7; // Shows just after vpn, before the loading/sync indicator
	}
	return %orig;
}
%end
%end

%ctor {
	if ([%c(ZYSettings) isLibStatusBarInstalled]) {
		%init(libstatusbar);
	}
	%init;
}
