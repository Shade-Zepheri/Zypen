#import "ZYWindowBar.h"
#import "ZYDesktopManager.h"
#import "ZYWindowOverlayView.h"
#import "ZYWindowSnapDataProvider.h"
#import "ZYSettings.h"
#import "ZYWindowStatePreservationSystemManager.h"
#import "ZYResourceImageProvider.h"
#import "ZYInsetLabel.h"
#import "ZYMessagingServer.h"
#import "ZYFakePhoneMode.h"
#import "ZYSnapshotProvider.h"

@interface ZYWindowBarIconInfo : NSObject
@property (nonatomic) NSInteger alignment;
@property (nonatomic) NSInteger priority;
@property (nonatomic, retain) id item;
@end
@implementation ZYWindowBarIconInfo
@end

extern BOOL allowOpenApp;

@interface ZYWindowBar () {
	CGPoint initialPoint;
	BOOL enableDrag, enableLongPress;
	BOOL sizingLocked, appRotationLocked;
	BOOL isSnapped;
	BOOL isBeingTouched; // the windows like being touched

	CGFloat height, buttonSize, spacing;

	UIPanGestureRecognizer *panGesture;
	UIPinchGestureRecognizer *scaleGesture;
	UILongPressGestureRecognizer *longPressGesture;
	UITapGestureRecognizer *tapGesture, *doubleTapGesture, *tripleTapGesture;
	UIRotationGestureRecognizer *rotateGesture;

	ZYInsetLabel *titleLabel;
	UIButton *closeButton, *maximizeButton, *minimizeButton, *sizingLockButton;

	UIView *snapShadowView;
	UIColor *barBackgroundColor;
}
@end

@implementation ZYWindowBar
- (void)attachView:(ZYHostedAppView*)view {
	height = 40;
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
	    height = 45;
	}

	self.backgroundColor = [UIColor clearColor];
	barBackgroundColor = THEMED(windowedMultitaskingWindowBarBackgroundColor);
	attachedView = view;

	CGRect myFrame = view.frame;
	self.frame = myFrame;
	view.frame = CGRectMake(0, height, self.frame.size.width, self.frame.size.height);
	myFrame.size.height += height;
	self.frame = myFrame;
	view.hideStatusBar = YES;
	[self addSubview:view];

    panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handlePan:)];
    panGesture.delegate = self;
    [self addGestureRecognizer:panGesture];

	scaleGesture = [[UIPinchGestureRecognizer alloc] initWithTarget:self action:@selector(handlePinch:)];
	scaleGesture.delegate = self;
	[self addGestureRecognizer:scaleGesture];

	longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
	longPressGesture.delegate = self;
	longPressGesture.minimumPressDuration = 0.7;
	[self addGestureRecognizer:longPressGesture];

	rotateGesture = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotate:)];
	rotateGesture.delegate = self;
	[self addGestureRecognizer:rotateGesture];

	tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)];
	tapGesture.numberOfTapsRequired = 1;
	//tapGesture.delegate = self;
	[self addGestureRecognizer:tapGesture];

	doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap:)];
	doubleTapGesture.numberOfTapsRequired = 2;
	doubleTapGesture.delegate = self;
	[self addGestureRecognizer:doubleTapGesture];

	tripleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTripleTap:)];
	tripleTapGesture.numberOfTapsRequired = 3;
	tripleTapGesture.delegate = self;
	[self addGestureRecognizer:tripleTapGesture];

	[tapGesture requireGestureRecognizerToFail:tripleTapGesture];
	[tapGesture requireGestureRecognizerToFail:doubleTapGesture];
	[tapGesture requireGestureRecognizerToFail:scaleGesture];
	[tapGesture requireGestureRecognizerToFail:rotateGesture];
	[tapGesture requireGestureRecognizerToFail:panGesture];

	[doubleTapGesture requireGestureRecognizerToFail:tripleTapGesture];

    self.userInteractionEnabled = YES;
    enableDrag = YES;
    enableLongPress = YES;

    titleLabel = [[ZYInsetLabel alloc] initWithFrame:CGRectMake(0, 0, myFrame.size.width, height)];
    titleLabel.textInset = UIEdgeInsetsMake(0, THEMED(windowedMultitaskingBarTitleTextInset) ?: 5, 0, THEMED(windowedMultitaskingBarTitleTextInset) ?: 5);
    titleLabel.textAlignment = THEMED(windowedMultaskingBarTitleTextAlignment);
    titleLabel.font = [UIFont systemFontOfSize:18];
    titleLabel.textColor = THEMED(windowedMultitaskingBarTitleColor);
		titleLabel.text = [view displayName];
    [self addSubview:titleLabel];

    CGFloat tmp = 16;
    while (tmp + 16 < height) {
			tmp += 16;
		}
    buttonSize = tmp;
    spacing = (height - buttonSize) / 2.0;

    if (![ZYSettings.sharedSettings onlyShowWindowBarIconsOnOverlay]) {
	    /*
	        alignment:
			0 = left
			1 = right
	    */

	    // This is terribly inefficient.... plz send help

	    static id closeItemIdentifier = [[NSObject alloc] init],
	    	maxItemIdentifier = [[NSObject alloc] init],
	    	minItemIdentifier = [[NSObject alloc] init],
	    	rotationItemIdentifier = [[NSObject alloc] init];

	    NSMutableArray *infos = [NSMutableArray array];

	    NSInteger closeAlignment = THEMED(windowedMultitaskingCloseButtonAlignment);
	    NSInteger maxAlignment = THEMED(windowedMultitaskingMaxButtonAlignment);
	    NSInteger minAlignment = THEMED(windowedMultitaskingMinButtonAlignment);
	    NSInteger rotationAlignment = THEMED(windowedMultitaskingRotationAlignment);

	    NSInteger closePriority = THEMED(windowedMultitaskingCloseButtonPriority);
	    NSInteger maxPriority = THEMED(windowedMultitaskingMaxButtonPriority);
	    NSInteger minPriority = THEMED(windowedMultitaskingMinButtonPriority);
	    NSInteger rotationPriority = THEMED(windowedMultitaskingRotationPriority);

	    ZYWindowBarIconInfo *tmpItem = [[ZYWindowBarIconInfo alloc] init];
	    tmpItem.alignment = closeAlignment;
	    tmpItem.priority = closePriority;
	    tmpItem.item = closeItemIdentifier;
	    [infos addObject:tmpItem];

		tmpItem = [[ZYWindowBarIconInfo alloc] init];
	    tmpItem.alignment = maxAlignment;
	    tmpItem.priority = maxPriority;
	    tmpItem.item = maxItemIdentifier;
	    [infos addObject:tmpItem];

	    tmpItem = [[ZYWindowBarIconInfo alloc] init];
	    tmpItem.alignment = minAlignment;
	    tmpItem.priority = minPriority;
	    tmpItem.item = minItemIdentifier;
	    [infos addObject:tmpItem];

	    tmpItem = [[ZYWindowBarIconInfo alloc] init];
	    tmpItem.alignment = rotationAlignment;
	    tmpItem.priority = rotationPriority;
	    tmpItem.item = rotationItemIdentifier;
	    [infos addObject:tmpItem];

	    NSMutableArray *leftIconOrder = [NSMutableArray array];
	    NSMutableArray *rightIconOrder = [NSMutableArray array];

	    for (int i = 0; i < infos.count; i++) {
			ZYWindowBarIconInfo *info = infos[i];
			if (info.alignment == 0) {
				[leftIconOrder addObject:info];
			} else {
				[rightIconOrder addObject:info];
			}
		}

		[leftIconOrder sortUsingComparator:^(ZYWindowBarIconInfo *a, ZYWindowBarIconInfo *b) {
			if (a.priority > b.priority) {
				return (NSComparisonResult)NSOrderedDescending;
			} else if (a.priority < b.priority) {
				return (NSComparisonResult)NSOrderedAscending;
			}
		    return (NSComparisonResult)NSOrderedSame;
		}];

		[rightIconOrder sortUsingComparator:^(ZYWindowBarIconInfo *a, ZYWindowBarIconInfo *b) {
			if (a.priority > b.priority) {
				return (NSComparisonResult)NSOrderedDescending;
			} else if (a.priority < b.priority) {
				return (NSComparisonResult)NSOrderedAscending;
			}
		    return (NSComparisonResult)NSOrderedSame;
		}];


		CGFloat leftSpace = (THEMED(windowedMultitaskingBarTitleTextInset) ?: 5);
		CGFloat rightSpace = self.frame.size.width - buttonSize - (THEMED(windowedMultitaskingBarTitleTextInset) ?: 5);

		UIButton *(^createCloseButton)() = ^{
			closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
			closeButton.frame = CGRectMake(5, spacing, buttonSize, buttonSize);
			[closeButton setImage:[ZYResourceImageProvider imageForFilename:@"Close" size:CGSizeMake(16, 16) tintedTo:THEMED(windowedMultitaskingCloseIconTint)] forState:UIControlStateNormal];
			closeButton.clipsToBounds = YES;
			[closeButton addTarget:self action:@selector(closeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
			closeButton.backgroundColor = THEMED(windowedMultitaskingCloseIconBackgroundColor);
			closeButton.layer.cornerRadius = THEMED(windowedMultitaskingBarButtonCornerRadius) == 0 ? 0 : closeButton.frame.size.width / 2;
			[self addSubview:closeButton];
			return closeButton;
		};

		UIButton *(^createMaxButton)() = ^{
			maximizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
			maximizeButton.frame = CGRectMake(closeButton.frame.origin.x + closeButton.frame.size.width + 5, spacing, buttonSize, buttonSize);
			[maximizeButton setImage:[ZYResourceImageProvider imageForFilename:@"Plus" size:CGSizeMake(16, 16) tintedTo:THEMED(windowedMultitaskingMaxIconTint)] forState:UIControlStateNormal];
			maximizeButton.clipsToBounds = YES;
			[maximizeButton addTarget:self action:@selector(maximizeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
			maximizeButton.backgroundColor = THEMED(windowedMultitaskingMaxIconBackgroundColor);
			maximizeButton.layer.cornerRadius = THEMED(windowedMultitaskingBarButtonCornerRadius) == 0 ? 0 : maximizeButton.frame.size.width / 2;
			[self addSubview:maximizeButton];
			return maximizeButton;
		};

		UIButton *(^createMinButton)() = ^{
			minimizeButton = [UIButton buttonWithType:UIButtonTypeCustom];
			minimizeButton.frame = CGRectMake(maximizeButton.frame.origin.x + maximizeButton.frame.size.width + 5, spacing, buttonSize, buttonSize);
			[minimizeButton setImage:[ZYResourceImageProvider imageForFilename:@"Minus" size:CGSizeMake(16, 16) tintedTo:THEMED(windowedMultitaskingMinIconTint)] forState:UIControlStateNormal];
			minimizeButton.clipsToBounds = YES;
			[minimizeButton addTarget:self action:@selector(minimizeButtonTap:) forControlEvents:UIControlEventTouchUpInside];
			minimizeButton.backgroundColor = THEMED(windowedMultitaskingMinIconBackgroundColor);
			minimizeButton.layer.cornerRadius = THEMED(windowedMultitaskingBarButtonCornerRadius) == 0 ? 0 : minimizeButton.frame.size.width / 2;
			[self addSubview:minimizeButton];
			return minimizeButton;
		};

		UIButton *(^createRotationButton)() = ^{
			sizingLockButton = [UIButton buttonWithType:UIButtonTypeCustom];
			sizingLockButton.frame = CGRectMake(self.frame.size.width - (buttonSize + 5), spacing, buttonSize, buttonSize);
			sizingLockButton.titleLabel.font = [UIFont systemFontOfSize:13];
			[sizingLockButton setImage:[ZYResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(16, 16) tintedTo:THEMED(windowedMultitaskingRotationIconTint)] forState:UIControlStateNormal];
			sizingLockButton.clipsToBounds = YES;
			[sizingLockButton addTarget:self action:@selector(sizingLockButtonTap:) forControlEvents:UIControlEventTouchUpInside];
			sizingLockButton.backgroundColor = THEMED(windowedMultitaskingRotationIconBackgroundColor);
			sizingLockButton.layer.cornerRadius = THEMED(windowedMultitaskingBarButtonCornerRadius) == 0 ? 0 : sizingLockButton.frame.size.width / 2;
			[self addSubview:sizingLockButton];
			return sizingLockButton;
		};

		for (ZYWindowBarIconInfo *item in leftIconOrder) {
			UIButton *button = nil;
			if (item.item == closeItemIdentifier) {
				button = createCloseButton();
			} else if (item.item == maxItemIdentifier) {
				button = createMaxButton();
			} else if (item.item == minItemIdentifier) {
				button = createMinButton();
			} else if (item.item == rotationItemIdentifier) {
				button = createRotationButton();
			}

			if (button) {
				button.frame = CGRectMake(leftSpace, spacing, buttonSize, buttonSize);
				leftSpace += button.frame.size.width + (THEMED(windowedMultitaskingBarTitleTextInset) ?: 5);
			}
		}

		for (ZYWindowBarIconInfo *item in rightIconOrder) {
			UIButton *button = nil;
			if (item.item == closeItemIdentifier) {
				button = createCloseButton();
			} else if (item.item == maxItemIdentifier) {
				button = createMaxButton();
			} else if (item.item == minItemIdentifier) {
				button = createMinButton();
			} else if (item.item == rotationItemIdentifier) {
				button = createRotationButton();
			}
			if (button) {
				button.frame = CGRectMake(rightSpace, spacing, buttonSize, buttonSize);
				rightSpace -= button.frame.size.width + (THEMED(windowedMultitaskingBarTitleTextInset) ?: 5);
			}
		}
	}

	sizingLocked = NO;
	appRotationLocked = NO;

	CAShapeLayer *maskLayer = [CAShapeLayer layer];
	maskLayer.path = [UIBezierPath bezierPathWithRoundedRect:self.bounds byRoundingCorners:UIRectCornerTopLeft | UIRectCornerTopRight cornerRadii:(CGSize){6.0, 6.0}].CGPath;
	self.layer.mask = maskLayer;
}

- (void)drawRect:(CGRect)rect {
    CGRect topRect = CGRectMake(0, 0, rect.size.width, height);
    // Fill the rectangle with grey
    [barBackgroundColor setFill];
    UIRectFill(topRect);

    [super drawRect:rect];
}

- (void)close {
	[ZYDesktopManager.sharedInstance removeAppWithIdentifier:self.attachedView.bundleIdentifier animated:YES];
}

- (void)maximize {
	allowOpenApp = YES;
	if ([%c(SBUIController) respondsToSelector:@selector(activateApplicationAnimated:)]) {
		[[%c(SBUIController) sharedInstance] activateApplicationAnimated:attachedView.app];
	} else {
		[[%c(SBUIController) sharedInstance] activateApplication:attachedView.app];
	}
	allowOpenApp = NO;
}

- (void)minimize {
	[attachedView rotateToOrientation:UIInterfaceOrientationPortrait];
	[UIView animateWithDuration:0.7 animations:^{
		self.transform = CGAffineTransformMakeScale(0.25, 0.25);
	}];
}

- (void)closeButtonTap:(id)arg1 {
	[self close];
}

- (void)maximizeButtonTap:(id)arg1 {
	[self maximize];
}

- (void)minimizeButtonTap:(id)arg1 {
	[self minimize];
}

- (void)saveWindowInfo {
	[ZYWindowStatePreservationSystemManager.sharedInstance saveWindowInformation:self];
	if (self.desktop) {
		[self.desktop saveInfo];
	}
}

- (BOOL)isLocked {
	if ([ZYSettings.sharedSettings windowRotationLockMode] == 0) {
		return sizingLocked;
	} else {
		return appRotationLocked;
	}
}

- (void)sizingLockButtonTap:(id)arg1 {
	if ([ZYSettings.sharedSettings windowRotationLockMode] == 0) {
		sizingLocked = !sizingLocked;
	} else {
		appRotationLocked = !appRotationLocked;
	}

	if (sizingLocked || appRotationLocked) {
		[sizingLockButton setImage:[ZYResourceImageProvider imageForFilename:@"Lock" size:CGSizeMake(16, 16) tintedTo:THEMED(windowedMultitaskingRotationIconTint)] forState:UIControlStateNormal];
	} else {
		[sizingLockButton setImage:[ZYResourceImageProvider imageForFilename:@"Unlocked" size:CGSizeMake(16, 16) tintedTo:THEMED(windowedMultitaskingRotationIconTint)] forState:UIControlStateNormal];
		[self updateClientRotation];
	}
}

- (void)scaleTo:(CGFloat)scale animated:(BOOL)animate {
	[self scaleTo:scale animated:animate derotate:NO];
}

- (void)scaleTo:(CGFloat)scale animated:(BOOL)animate derotate:(BOOL)derotate {
	CGFloat rotation = atan2(self.transform.b, self.transform.a);

	CGAffineTransform transform = CGAffineTransformMakeScale(scale, scale);
	if (!derotate) {
		transform = CGAffineTransformRotate(transform, rotation);
	}

	if (animate) {
		[UIView animateWithDuration:0.2 animations:^{
				[self setTransform:transform];
			}];
	} else {
		[self setTransform:transform];
	}
	[self saveWindowInfo];
}

- (void)addRotation:(CGFloat)rads updateApp:(BOOL)update {
	if (sizingLocked) {
		return;
	}

	if (rads != 0) {
		self.transform = CGAffineTransformRotate(self.transform, rads);
	}

  if (update) {
  	CGFloat currentRotation = RADIANS_TO_DEGREES(atan2(self.transform.b, self.transform.a));
  	CGFloat rotateSnapDegrees = 0;

  	if (currentRotation < 0) {
			currentRotation = 360 + currentRotation;
		}

  	if (currentRotation >= 315 || currentRotation <= 45) {
			rotateSnapDegrees = 360 - currentRotation;
		} else if (currentRotation > 45 && currentRotation <= 135) {
			rotateSnapDegrees = 90 - currentRotation;
		} else if (currentRotation > 135 && currentRotation <= 215) {
			rotateSnapDegrees = 180 - currentRotation;
		} else {
			rotateSnapDegrees = 270 - currentRotation;
		}

  	if ([ZYSettings.sharedSettings snapRotation]) {
			[UIView animateWithDuration:0.2 animations:^{
				self.transform = CGAffineTransformRotate(self.transform, DEGREES_TO_RADIANS(rotateSnapDegrees));
			}];
		}

		if (!appRotationLocked) {
			[attachedView rotateToOrientation:[self.desktop appOrientationRelativeToThisOrientation:currentRotation]];
		}

		if ([ZYSettings.sharedSettings snapWindows] && [ZYWindowSnapDataProvider shouldSnapWindow:self]) {
			[ZYWindowSnapDataProvider snapWindow:self toLocation:[ZYWindowSnapDataProvider snapLocationForWindow:self] animated:YES];
			isSnapped = YES;
		}

		[self saveWindowInfo];
  }
}

- (void)updateClientRotation {
	if (!appRotationLocked) {
    	CGFloat currentRotation = RADIANS_TO_DEGREES(atan2(self.transform.b, self.transform.a));
    	[self updateClientRotation:[self.desktop appOrientationRelativeToThisOrientation:currentRotation]];
	}
}

- (void)updateClientRotation:(UIInterfaceOrientation)orientation {
	if (!appRotationLocked) {
    	CGFloat currentRotation = RADIANS_TO_DEGREES(atan2(self.transform.b, self.transform.a));
	    [attachedView rotateToOrientation:[self.desktop appOrientationRelativeToThisOrientation:currentRotation]];
	}
}

- (void)disableLongPress {
	enableLongPress = NO;
	longPressGesture.enabled = NO;
	longPressGesture.enabled = YES;
}

- (void)enableLongPress {
	enableLongPress = YES;
}

- (void)swapOrientationButtonTap:(id)arg1 {
	[self addRotation:DEGREES_TO_RADIANS(90) updateApp:YES];
}

- (void)handleRotate:(UIRotationGestureRecognizer *)gesture {
	if (![ZYSettings.sharedSettings alwaysEnableGestures] && !self.isOverlayShowing) {
		return;
	}

  if (gesture.state == UIGestureRecognizerStateChanged) {
		[self addRotation:gesture.rotation updateApp:NO];
    //[self setTransform:CGAffineTransformRotate(self.transform, gesture.rotation)];
    gesture.rotation = 0.0;
  } else if (gesture.state == UIGestureRecognizerStateEnded) {
  	[self addRotation:0 updateApp:YES];
  }
}

- (void)handleLongPress:(UILongPressGestureRecognizer*)sender {
	if (!enableLongPress) {
		return;
	}

	[self close];
}

- (void)showOverlay {
	ZYWindowOverlayView *overlay = [[ZYWindowOverlayView alloc] initWithFrame:CGRectMake(0, height, self.bounds.size.width, self.bounds.size.height - height)];
	overlay.alpha = 0;
	overlay.tag = 465982;
	overlay.appWindow = self;
	[self addSubview:overlay];
	[overlay show];

	[UIView animateWithDuration:0.4 animations:^{
		closeButton.alpha = 0;
		maximizeButton.alpha = 0;
		minimizeButton.alpha = 0;
		sizingLockButton.alpha = 0;
		overlay.alpha = 1;
	}];
}

- (void)hideOverlay {
	[(ZYWindowOverlayView*)[self viewWithTag:465982] dismiss];
	[UIView animateWithDuration:0.5 animations:^{
		closeButton.alpha = 1;
		maximizeButton.alpha = 1;
		minimizeButton.alpha = 1;
		sizingLockButton.alpha = 1;
	}];
}

- (BOOL)isOverlayShowing {
	return [self viewWithTag:465982] != nil;
}

- (void)handleTap:(UITapGestureRecognizer*)tap {
	if (!self.isOverlayShowing) {
		[self showOverlay];
	}
}

- (void)handleDoubleTap:(UITapGestureRecognizer*)tap {
	[attachedView rotateToOrientation:UIInterfaceOrientationPortrait];
	[UIView animateWithDuration:0.7 animations:^{
		self.transform = CGAffineTransformMakeScale(0.6, 0.6);
	}];
}

- (void)handleTripleTap:(UITapGestureRecognizer*)tap{
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[ZYMessagingServer.sharedInstance forcePhoneMode:![ZYFakePhoneMode shouldFakeForAppWithIdentifier:attachedView.app.bundleIdentifier] forIdentifier:attachedView.app.bundleIdentifier andRelaunchApp:YES];
	}
}

- (void)handlePan:(UIPanGestureRecognizer*)sender {
	if (!enableDrag) {
		[self removePotentialSnapShadow];
		return;
	}

	if (sender.state == UIGestureRecognizerStateBegan) {
		[self.superview bringSubviewToFront:self];
		initialPoint = sender.view.center;
	} else if (sender.state == UIGestureRecognizerStateChanged) {
		enableLongPress = NO;
	} else if (sender.state == UIGestureRecognizerStateEnded) {
		enableLongPress = YES;
		[self saveWindowInfo];

		if ([ZYSettings.sharedSettings snapWindows] && [ZYWindowSnapDataProvider shouldSnapWindow:self]) {
			[ZYWindowSnapDataProvider snapWindow:self toLocation:[ZYWindowSnapDataProvider snapLocationForWindow:self] animated:YES completion:^{
				[self removePotentialSnapShadow];
				[self saveWindowInfo];
			}];
			isSnapped = YES;
			// Force tap to fail
			tapGesture.enabled = NO;
			tapGesture.enabled = YES;
			return;
		} else {
			[self removePotentialSnapShadow];
		}
		return;
	}

	isSnapped = NO;
    UIView *view = sender.view;
    CGPoint point = [sender translationInView:view.superview];

    CGPoint translatedPoint = CGPointMake(initialPoint.x + point.x, initialPoint.y + point.y);
    view.center = translatedPoint;

    [self updatePotentialSnapShadow];
}

- (void)handlePinch:(UIPinchGestureRecognizer *)gesture {
	if (![ZYSettings.sharedSettings alwaysEnableGestures] && !self.isOverlayShowing) {
		return;
	}

    switch (gesture.state) {
	    case UIGestureRecognizerStateBegan: {
				enableDrag = NO; enableLongPress = NO;
				break;
			}
	    case UIGestureRecognizerStateChanged: {
				[self setTransform:CGAffineTransformScale(self.transform, gesture.scale, gesture.scale)];
				//self.bounds = (CGRect){ self.bounds.origin, {self.bounds.size.width * gesture.scale, self.bounds.size.height * gesture.scale} };
				gesture.scale = 1.0;
				break;
			}
	    case UIGestureRecognizerStateEnded: {
				enableDrag = YES; enableLongPress = YES;

				if ([ZYWindowSnapDataProvider shouldSnapWindow:self]) {
					[ZYWindowSnapDataProvider snapWindow:self toLocation:[ZYWindowSnapDataProvider snapLocationForWindow:self] animated:YES];
					isSnapped = YES;
					// Force tap to fail
					tapGesture.enabled = NO;
					tapGesture.enabled = YES;
					return;
				}
				[self saveWindowInfo];
				break;
			}
	    default:
	        break;
    }
}

- (void)setTransform:(CGAffineTransform)trans {
	CGFloat scale = sqrt(trans.a * trans.a + trans.c * trans.c);
	CGFloat max = 1.0;
	scale = MIN(max, MAX(0.15, scale));

	trans = CGAffineTransformRotate(CGAffineTransformMakeScale(scale, scale), atan2(trans.b, trans.a));

	[super setTransform:trans];

	if (!isBeingTouched) {
		if ([ZYWindowSnapDataProvider shouldSnapWindow:self]) {
			[ZYWindowSnapDataProvider snapWindow:self toLocation:[ZYWindowSnapDataProvider snapLocationForWindow:self] animated:YES];
		}

		/*CGPoint origin = self.frame.origin;
		CGPoint endPoint = CGPointMake(origin.x + self.frame.size.width, origin.y + self.frame.size.height);
		if (endPoint.x > self.desktop.frame.size.width)
			origin.x -= (endPoint.x - self.desktop.frame.size.width);
		if (endPoint.y > self.desktop.frame.size.height)
			origin.y -= (endPoint.y - self.desktop.frame.size.height);
		if (origin.x < 0)
			origin.x = 0;
		if (origin.y < 0)
			origin.y = 0;
		CGRect adjustedFrame = CGRectMake(origin.x, origin.y, self.frame.size.width, self.frame.size.height);
		self.frame = adjustedFrame;*/

	}
}

- (void)updatePotentialSnapShadow {
	if (![ZYSettings.sharedSettings snapWindows]) {
		return;
	}

	if (![ZYSettings.sharedSettings showSnapHelper]) {
		return;
	}

	if (!snapShadowView) {
		snapShadowView = [[UIView alloc] initWithFrame:self.bounds];
		snapShadowView.backgroundColor = [UIColor.blackColor colorWithAlphaComponent:0.1]; // [UIColor.blackColor colorWithAlphaComponent:0.5];
		snapShadowView.layer.borderColor = [UIColor whiteColor].CGColor;
		snapShadowView.layer.shadowRadius = 20;
		snapShadowView.layer.shadowOpacity = 0.8;
		snapShadowView.layer.shadowOffset = CGSizeMake(0, 0);
		snapShadowView.layer.borderWidth = 1.5f;
		snapShadowView.layer.cornerRadius = 6;
		snapShadowView.clipsToBounds = YES;
		snapShadowView.layer.masksToBounds = YES;

		[self.superview insertSubview:snapShadowView belowSubview:self];
	}

	if ([ZYWindowSnapDataProvider shouldSnapWindow:self]) {
		snapShadowView.hidden = NO;
		snapShadowView.transform = self.transform;
		snapShadowView.center = [ZYWindowSnapDataProvider snapCenterForWindow:self toLocation:[ZYWindowSnapDataProvider snapLocationForWindow:self]];
	} else {
		snapShadowView.hidden = YES;
	}
}

- (void)removePotentialSnapShadow {
	[snapShadowView removeFromSuperview];
	snapShadowView = nil;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
	isBeingTouched = YES;
	ZYDesktopManager.sharedInstance.lastUsedWindow = self;
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	isBeingTouched = NO;
}

- (void)resignForemostApp {
    titleLabel.font = [UIFont systemFontOfSize:18];
}

- (void)becomeForemostApp {
    titleLabel.font = [UIFont boldSystemFontOfSize:20];
	[self.superview bringSubviewToFront:self];
}

- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
    NSEnumerator *objects = [self.subviews reverseObjectEnumerator];
    UIView *subview;
    while ((subview = [objects nextObject])) {
        UIView *success = [subview hitTest:[self convertPoint:point toView:subview] withEvent:event];
        if (success) {
					return success;
				}
    }
    return [super hitTest:point withEvent:event];
}

- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
	BOOL isContained = NO;
	for (UIView *view in self.subviews) {
		if (CGRectContainsPoint(view.frame, point) || CGRectContainsPoint(view.frame, [view convertPoint:point fromView:self])) {
			isContained = YES;
		}
	}
	return isContained || [super pointInside:point withEvent:event];
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	if ([gestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]] && [otherGestureRecognizer isKindOfClass:[UIPanGestureRecognizer class]]) {
		return NO;
	}
	return YES;
}
- (ZYHostedAppView*)attachedView {
	return attachedView;
}

@end
