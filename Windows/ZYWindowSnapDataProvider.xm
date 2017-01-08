#import "ZYWindowSnapDataProvider.h"

@implementation ZYWindowSnapDataProvider
+ (BOOL)shouldSnapWindow:(ZYWindowBar*)bar {
	return [ZYWindowSnapDataProvider snapLocationForWindow:bar] != ZYWindowSnapLocationInvalid;
}

+ (ZYWindowSnapLocation)snapLocationForWindow:(ZYWindowBar*)windowBar {
	CGRect location = windowBar.frame;

	// Convienence values
	CGFloat width = UIScreen.mainScreen._referenceBounds.size.width;
	CGFloat height = UIScreen.mainScreen._referenceBounds.size.height;
	//CGFloat oneThirdsHeight = height / 4;
	CGFloat twoThirdsHeight = (height / 4) * 3;

	CGFloat leftXBuffer = 25;
	CGFloat rightXBuffer = width - 25;
	CGFloat bottomBuffer = height - 25;

	CGPoint topLeft = windowBar.center;
	topLeft.x -= location.size.width / 2;
	topLeft.y -= location.size.height / 2;
	topLeft = CGPointApplyAffineTransform(topLeft, windowBar.transform);

	CGPoint topRight = windowBar.center;
	topRight.x += location.size.width / 2;
	topRight.y -= location.size.height / 2;
	topRight = CGPointApplyAffineTransform(topRight, windowBar.transform);

	CGPoint bottomLeft = windowBar.center;
	bottomLeft.x -= location.size.width / 2;
	bottomLeft.y += location.size.height / 2;
	bottomLeft = CGPointApplyAffineTransform(bottomLeft, windowBar.transform);

	CGPoint bottomRight = windowBar.center;
	bottomRight.x += location.size.width / 2;
	bottomRight.y += location.size.height / 2;
	//bottomRight = CGPointApplyAffineTransform(bottomRight, theView.transform);

	// I am not proud of the below jumps, however i do believe it is the best solution to the problem apart from making weird blocks, which would be a considerable amount of work.

	BOOL didLeft = NO;
	BOOL didRight = NO;

	if (topLeft.x > bottomLeft.x)
		goto try_right;

	if (topLeft.y > bottomLeft.y)
		goto try_bottom;

try_left:
	didLeft = YES;
	// Left
	if (location.origin.x < leftXBuffer && location.origin.y < height / 8)
		return ZYWindowSnapLocationLeftTop;
	if (location.origin.x < leftXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return ZYWindowSnapLocationLeftBottom;
	if (location.origin.x < leftXBuffer && location.origin.y >= height / 8 && location.origin.y < twoThirdsHeight)
		return ZYWindowSnapLocationLeftMiddle;

try_right:
	didRight = YES;
	// Right
	if (location.origin.x + location.size.width > rightXBuffer && location.origin.y < height / 8)
		return ZYWindowSnapLocationRightTop;
	if (location.origin.x + location.size.width > rightXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return ZYWindowSnapLocationRightBottom;
	if (location.origin.x + location.size.width > rightXBuffer && location.origin.y >= height / 8 && location.origin.y < twoThirdsHeight)
		return ZYWindowSnapLocationRightMiddle;

	if (!didLeft)
		goto try_left;
	else if (!didRight)
		goto try_right;

try_bottom:

	// Jumps through this off slightly, so we re-check (which may or may not actually be needed, depending on the path it takes)
	if (location.origin.x + location.size.width > rightXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return ZYWindowSnapLocationRightBottom;
	if (location.origin.x < leftXBuffer && (location.origin.y >= twoThirdsHeight || location.origin.y + location.size.height > height))
		return ZYWindowSnapLocationLeftBottom;

	if (location.origin.y + location.size.height > bottomBuffer)
		return ZYWindowSnapLocationBottom;

//try_top:

	if (location.origin.y < 20 + 25)
		return ZYWindowSnapLocationTop;

	// Second time possible verify
	if (!didLeft)
		goto try_left;
	else if (!didRight)
		goto try_right;

	return ZYWindowSnapLocationNone;
}

+ (CGPoint)snapCenterForWindow:(ZYWindowBar*)window toLocation:(ZYWindowSnapLocation)location {
	// Convienence values
	CGFloat width = UIScreen.mainScreen._referenceBounds.size.width;
	CGFloat height = UIScreen.mainScreen._referenceBounds.size.height;

	// Target frame values
	CGRect frame = window.frame;
	CGPoint newCenter = window.center;

	BOOL adjustStatusBar = NO;

	switch (location) {
		case ZYWindowSnapLocationLeftTop:
			newCenter = CGPointMake(frame.size.width / 2, (frame.size.height / 2) + 20);
			adjustStatusBar = YES;
			break;
		case ZYWindowSnapLocationLeftMiddle:
			newCenter.x = frame.size.width / 2;
			break;
		case ZYWindowSnapLocationLeftBottom:
			newCenter = CGPointMake(frame.size.width / 2, height - (frame.size.height / 2));
			break;

		case ZYWindowSnapLocationRightTop:
			newCenter = CGPointMake(width - (frame.size.width / 2), (frame.size.height / 2) + 20);
			adjustStatusBar = YES;
			break;
		case ZYWindowSnapLocationRightMiddle:
			newCenter.x = width - (frame.size.width / 2);
			break;
		case ZYWindowSnapLocationRightBottom:
			newCenter = CGPointMake(width - (frame.size.width / 2), height - (frame.size.height / 2));
			break;

		case ZYWindowSnapLocationTop:
			newCenter.y = (frame.size.height / 2) + 20;
			adjustStatusBar = YES;
			break;
		case ZYWindowSnapLocationBottom:
			newCenter.y = height - (frame.size.height / 2);
			break;

		case ZYWindowSnapLocationBottomCenter:
			newCenter.x = width / 2.0;
			newCenter.y = height - (frame.size.height / 2);
			break;

		case ZYWindowSnapLocationInvalid:
		default:
			break;
	}

	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight && adjustStatusBar) {
		newCenter.y -= 20;
	}
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight && (location == ZYWindowSnapLocationRightMiddle || location == ZYWindowSnapLocationRightBottom || location == ZYWindowSnapLocationRightTop)) {
		newCenter.x -= 20;
	} else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft && adjustStatusBar) {
		newCenter.y -= 20;
	}
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft && (location == ZYWindowSnapLocationLeftMiddle || location == ZYWindowSnapLocationLeftBottom || location == ZYWindowSnapLocationLeftTop)) {
		newCenter.x += 20;
	}

	return newCenter;
}

+ (void)snapWindow:(ZYWindowBar*)window toLocation:(ZYWindowSnapLocation)location animated:(BOOL)animated {
	/*
	// Convienence values
	CGFloat width = UIScreen.mainScreen.bounds.size.width;
	CGFloat height = UIScreen.mainScreen.bounds.size.height;
	// Target frame values
	CGRect frame = window.frame;
	CGPoint adjustedOrigin = window.frame.origin;
	switch (location)
	{
		case ZYWindowSnapLocationLeftTop:
			adjustedOrigin = CGPointMake(0, 20);
			break;
		case ZYWindowSnapLocationLeftMiddle:
			adjustedOrigin.x = 0;
			break;
		case ZYWindowSnapLocationLeftBottom:
			adjustedOrigin = CGPointMake(0, height - frame.size.height);
			break;
		case ZYWindowSnapLocationRightTop:
			adjustedOrigin = CGPointMake(width - frame.size.width, 20);
			break;
		case ZYWindowSnapLocationRightMiddle:
			adjustedOrigin.x = width - frame.size.width;
			break;
		case ZYWindowSnapLocationRightBottom:
			adjustedOrigin = CGPointMake(width - frame.size.width, height - frame.size.height);
			break;
		case ZYWindowSnapLocationTop:
			adjustedOrigin.y = 20;
			break;
		case ZYWindowSnapLocationBottom:
			adjustedOrigin.y = height - frame.size.height;
			break;
		case ZYWindowSnapLocationInvalid:
		default:
			break;
	}
	if (animated)
	{
		[UIView animateWithDuration:0.2 animations:^{
			window.frame = (CGRect) { adjustedOrigin, frame.size };
		}];
	}
	else
		window.frame = (CGRect) { adjustedOrigin, frame.size };
	*/

	[self snapWindow:window toLocation:location animated:animated completion:nil];
}

+ (void)snapWindow:(ZYWindowBar*)window toLocation:(ZYWindowSnapLocation)location animated:(BOOL)animated completion:(dispatch_block_t)completionBlock {
	CGPoint newCenter = [ZYWindowSnapDataProvider snapCenterForWindow:window toLocation:location];

	if (animated) {
		[UIView animateWithDuration:0.2 animations:^{
			window.center = newCenter;
		} completion:^(BOOL _) {
			if (completionBlock)
				completionBlock();
		}];
	} else {
		window.center = newCenter;
		if (completionBlock)
			completionBlock();
	}
}
@end

ZYWindowSnapLocation ZYWindowSnapLocationGetLeftOfScreen() {
	switch (UIApplication.sharedApplication.statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
			return ZYWindowSnapLocationLeft;
		case UIInterfaceOrientationLandscapeRight:
			return ZYWindowSnapLocationTop;
		case UIInterfaceOrientationLandscapeLeft:
			return ZYWindowSnapLocationBottom;
		case UIInterfaceOrientationPortraitUpsideDown:
			return ZYWindowSnapLocationRight;
	}
	return ZYWindowSnapLocationLeft;
}

ZYWindowSnapLocation ZYWindowSnapLocationGetRightOfScreen() {
	switch (UIApplication.sharedApplication.statusBarOrientation) {
		case UIInterfaceOrientationPortrait:
			return ZYWindowSnapLocationRight;
		case UIInterfaceOrientationLandscapeRight:
			return ZYWindowSnapLocationBottom;
		case UIInterfaceOrientationLandscapeLeft:
			return ZYWindowSnapLocationTop;
		case UIInterfaceOrientationPortraitUpsideDown:
			return ZYWindowSnapLocationLeft;
	}
	return ZYWindowSnapLocationRight;
}
