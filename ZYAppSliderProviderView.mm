#import "ZYAppSliderProviderView.h"
#import "ZYHostedAppView.h"
#import "ZYGestureManager.h"
#import "ZYAppSliderProvider.h"
#include <execinfo.h>

@implementation ZYAppSliderProviderView
@synthesize swipeProvider;

-(void) goToTheLeft
{
	[swipeProvider goToTheLeft];
	[self updateCurrentView];
}

-(void) goToTheRight
{
	[swipeProvider goToTheRight];
	[self updateCurrentView];
}

-(void) load
{
	[currentView loadApp];
}

-(void) unload
{
	if (!currentView || !currentView.bundleIdentifier)
		return;

	[ZYGestureManager.sharedInstance removeGestureWithIdentifier:currentView.bundleIdentifier];
	[currentView unloadApp];
}

-(void) updateCurrentView
{
	[self unload];
	if (currentView)
		[currentView removeFromSuperview];
	currentView = [swipeProvider viewAtCurrentIndex];

	if (self.isSwipeable && self.swipeProvider)
    {
    	self.backgroundColor = [UIColor clearColor]; // redColor];
    	self.userInteractionEnabled = YES;

		[ZYGestureManager.sharedInstance addGestureRecognizerWithTarget:self forEdge:UIRectEdgeLeft | UIRectEdgeRight identifier:currentView.bundleIdentifier priority:ZYGesturePriorityHigh];
		//[ZYGestureManager.sharedInstance addGestureRecognizerWithTarget:self forEdge:UIRectEdgeRight identifier:currentView.bundleIdentifier priority:ZYGesturePriorityHigh];

    	currentView.frame = CGRectMake(0, 0, self.frame.size.width - 0, self.frame.size.height);
    }
    else
    	currentView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
    [self addSubview:currentView];
    [self load];
}

-(CGRect) clientFrame
{
	if (!currentView) return CGRectZero;

	CGRect frame = currentView.frame;
	frame.size.height = self.frame.size.height;
	return frame;
}

-(NSString*) currentBundleIdentifier
{
	return currentView ? currentView.bundleIdentifier : nil;
}

-(BOOL) ZYGestureCallback_canHandle:(CGPoint)point velocity:(CGPoint)velocity
{
	return point.y <= [self convertPoint:self.frame.origin toView:nil].y + self.frame.size.height;
}

-(ZYGestureCallbackResult) ZYGestureCallback_handle:(UIGestureRecognizerState)state withPoint:(CGPoint)location velocity:(CGPoint)velocity forEdge:(UIRectEdge)edge
{
	static BOOL didHandle = NO;
	if (state == UIGestureRecognizerStateEnded)
	{
		didHandle = NO;
		return ZYGestureCallbackResultSuccessAndStop;
	}
	if (didHandle) return ZYGestureCallbackResultSuccessAndStop;

	if (edge == UIRectEdgeLeft)
	{
		didHandle = YES;
		if (self.swipeProvider.canGoLeft)
		{
			[self unload];
			[self goToTheLeft];
		}
		return ZYGestureCallbackResultSuccessAndStop;
	}
	else if (edge == UIRectEdgeRight)
	{
		didHandle = YES;
		if (self.swipeProvider.canGoRight)
		{
			[self unload];
			[self goToTheRight];
		}
		return ZYGestureCallbackResultSuccessAndStop;
	}
	return ZYGestureCallbackResultFailure;
}
@end
