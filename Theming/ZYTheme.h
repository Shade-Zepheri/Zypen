#import <UIKit/UIKit.h>

@interface ZYTheme : NSObject

@property (nonatomic, retain) NSString *themeIdentifier;
@property (nonatomic, retain) NSString *themeName;

// Backgrounder
@property (nonatomic, retain) UIColor *backgroundingIndicatorBackgroundColor;
@property (nonatomic, retain) UIColor *backgroundingIndicatorTextColor;

// Mission Control
@property (nonatomic) NSInteger missionControlBlurStyle;
@property (nonatomic, retain) UIColor *missionControlScrollViewBackgroundColor;
@property (nonatomic) CGFloat missionControlScrollViewOpacity;
@property (nonatomic) CGFloat missionControlIconPreviewShadowRadius;

// Windowed Multitasking
@property (nonatomic, retain) UIColor *windowedMultitaskingWindowBarBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingCloseIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingCloseIconTint;
@property (nonatomic, retain) UIColor *windowedMultitaskingMaxIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingMaxIconTint;
@property (nonatomic, retain) UIColor *windowedMultitaskingMinIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingMinIconTint;
@property (nonatomic, retain) UIColor *windowedMultitaskingRotationIconBackgroundColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingRotationIconTint;

@property (nonatomic) NSUInteger windowedMultitaskingBarButtonCornerRadius;

@property (nonatomic, retain) UIColor *windowedMultitaskingCloseIconOverlayColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingMaxIconOverlayColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingMinIconOverlayColor;
@property (nonatomic, retain) UIColor *windowedMultitaskingRotationIconOverlayColor;

@property (nonatomic, retain) UIColor *windowedMultitaskingBarTitleColor;
@property (nonatomic) NSTextAlignment windowedMultaskingBarTitleTextAlignment;
@property (nonatomic) NSInteger windowedMultitaskingBarTitleTextInset;

@property (nonatomic) NSInteger windowedMultitaskingCloseButtonAlignment;
@property (nonatomic) NSInteger windowedMultitaskingCloseButtonPriority;
@property (nonatomic) NSInteger windowedMultitaskingMaxButtonAlignment;
@property (nonatomic) NSInteger windowedMultitaskingMaxButtonPriority;
@property (nonatomic) NSInteger windowedMultitaskingMinButtonAlignment;
@property (nonatomic) NSInteger windowedMultitaskingMinButtonPriority;
@property (nonatomic) NSInteger windowedMultitaskingRotationAlignment;
@property (nonatomic) NSInteger windowedMultitaskingRotationPriority;

@property (nonatomic) NSInteger windowedMultitaskingBlurStyle;
@property (nonatomic, retain) UIColor *windowedMultitaskingOverlayColor;

// Quick Access
@property (nonatomic) BOOL quickAccessUseGenericTabLabel;

// SwipeOver

@property (nonatomic, retain) UIColor *swipeOverDetachBarColor;
@property (nonatomic, retain) UIColor *swipeOverDetachImageColor;
@end
