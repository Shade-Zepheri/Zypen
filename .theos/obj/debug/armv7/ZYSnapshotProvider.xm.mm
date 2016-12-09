#line 1 "ZYSnapshotProvider.xm"
#import "headers.h"
#import "ZYSnapshotProvider.h"


#include <substrate.h>
#if defined(__clang__)
#if __has_feature(objc_arc)
#define _LOGOS_SELF_TYPE_NORMAL __unsafe_unretained
#define _LOGOS_SELF_TYPE_INIT __attribute__((ns_consumed))
#define _LOGOS_SELF_CONST const
#define _LOGOS_RETURN_RETAINED __attribute__((ns_returns_retained))
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif
#else
#define _LOGOS_SELF_TYPE_NORMAL
#define _LOGOS_SELF_TYPE_INIT
#define _LOGOS_SELF_CONST
#define _LOGOS_RETURN_RETAINED
#endif

@class SBDisplayItem; @class SBUIController; @class SBWallpaperController; @class SBApplicationController; 

static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBApplicationController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBApplicationController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBWallpaperController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBWallpaperController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBUIController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBUIController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBDisplayItem(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBDisplayItem"); } return _klass; }
#line 4 "ZYSnapshotProvider.xm"
@implementation ZYSnapshotProvider

+(id) sharedInstance {
	SHARED_INSTANCE2(ZYSnapshotProvider, sharedInstance->imageCache = [NSCache new]);
}


-(UIImage*) snapshotForIdentifier:(NSString*)identifier orientation:(UIInterfaceOrientation)orientation {
	










	@autoreleasepool {

		if ([imageCache objectForKey:identifier] != nil) return [imageCache objectForKey:identifier];

		UIImage *image = nil;

		SBDisplayItem *item = [_logos_static_class_lookup$SBDisplayItem() displayItemWithType:@"App" displayIdentifier:identifier];
		__block SBAppSwitcherSnapshotView *view = nil;

		ON_MAIN_THREAD(^{
			if ([_logos_static_class_lookup$SBUIController() respondsToSelector:@selector(switcherController)])
			{
				view = [[[_logos_static_class_lookup$SBUIController() sharedInstance] switcherController] performSelector:@selector(_snapshotViewForDisplayItem:) withObject:item];
				[view setOrientation:orientation orientationBehavior:0];
			}
			else
			{
				
				
			}
		});

		if (view)
		{
			[view performSelectorOnMainThread:@selector(_loadSnapshotSync) withObject:nil waitUntilDone:YES];
			image = MSHookIvar<UIImageView*>(view, "_snapshotImageView").image;
		}

		if (!image)
		{
			SBApplication *app = [[_logos_static_class_lookup$SBApplicationController() sharedInstance] ZY_applicationWithBundleIdentifier:identifier];

			if (app && app.mainSceneID)
			{
				@try
				{
					CGRect frame = CGRectMake(0, 0, 0, 0);
					UIView *view = [_logos_static_class_lookup$SBUIController() _zoomViewWithSplashboardLaunchImageForApplication:app sceneID:app.mainSceneID screen:UIScreen.mainScreen interfaceOrientation:0 includeStatusBar:YES snapshotFrame:&frame];

					if (view)
					{
						UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].bounds.size, YES, [UIScreen mainScreen].scale);
						CGContextRef c = UIGraphicsGetCurrentContext();
						
						[view.layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES];
						image = UIGraphicsGetImageFromCurrentImageContext();
						UIGraphicsEndImageContext();
						view.layer.contents = nil;
					}
				}
				@catch (NSException *ex)
				{
					HBLogDebug(@"[ReachApp] error generating snapshot: %@", ex);
				}
			}

			if (!image) 
				image = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"%@/Default.png", app.path]];
		}

		if (image)
		{
			[imageCache setObject:image forKey:identifier];
		}

		return image;
	}
}


-(UIImage*) snapshotForIdentifier:(NSString*)identifier {
	return [self snapshotForIdentifier:identifier orientation:UIApplication.sharedApplication.statusBarOrientation];
}


-(void) forceReloadOfSnapshotForIdentifier:(NSString*)identifier {
	[imageCache removeObjectForKey:identifier];
}


-(UIImage*) storedSnapshotOfMissionControl {
	return [imageCache objectForKey:@"missioncontrol"];
}


-(void) storeSnapshotOfMissionControl:(UIWindow*)window {
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
		UIGraphicsBeginImageContextWithOptions([UIScreen mainScreen].ZY_interfaceOrientedBounds.size, YES, [UIScreen mainScreen].scale);
		
		
		

		ON_MAIN_THREAD(^{
			[window drawViewHierarchyInRect:window.bounds afterScreenUpdates:YES];
		});

		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		window.layer.contents = nil;

		if (image)
			[imageCache setObject:image forKey:@"missioncontrol"];
	});

}


-(NSString*) createKeyForDesktop:(ZYDesktopWindow*)desktop {
	return [NSString stringWithFormat:@"desktop-%lu", (unsigned long)desktop.hash];
}


-(UIImage*) snapshotForDesktop:(ZYDesktopWindow*)desktop {
	NSString *key = [self createKeyForDesktop:desktop];
	if ([imageCache objectForKey:key] != nil) return [imageCache objectForKey:key];

	UIImage *img = [self renderPreviewForDesktop:desktop];
	if (img)
		[imageCache setObject:img forKey:key];
	return img;
}


-(void) forceReloadSnapshotOfDesktop:(ZYDesktopWindow*)desktop {
	[imageCache removeObjectForKey:[self createKeyForDesktop:desktop]];
}


- (UIImage*)rotateImageToMatchOrientation:(UIImage*)oldImage {
	CGFloat degrees = 0;
	if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeRight)
		degrees = 270;
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationLandscapeLeft)
		degrees = 90;
	else if (UIApplication.sharedApplication.statusBarOrientation == UIInterfaceOrientationPortraitUpsideDown)
		degrees = 180;

	

	__block CGSize rotatedSize;

	ON_MAIN_THREAD(^{
		
		static UIView *rotatedViewBox = [[UIView alloc] init];
		rotatedViewBox.frame = CGRectMake(0,0,oldImage.size.width, oldImage.size.height);
		CGAffineTransform t = CGAffineTransformMakeRotation(DEGREES_TO_ZYDIANS(degrees));
		rotatedViewBox.transform = t;
		rotatedSize = rotatedViewBox.frame.size;
	});

	
	

	
	UIGraphicsBeginImageContext(rotatedSize);
	CGContextRef bitmap = UIGraphicsGetCurrentContext();

	
	CGContextTranslateCTM(bitmap, rotatedSize.width/2, rotatedSize.height/2);

	
	CGContextRotateCTM(bitmap, (degrees * M_PI / 180));

	
	CGContextScaleCTM(bitmap, 1.0, -1.0);
	CGContextDrawImage(bitmap, CGRectMake(-oldImage.size.width / 2, -oldImage.size.height / 2, oldImage.size.width, oldImage.size.height), [oldImage CGImage]);

	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return newImage;
}


-(UIImage*) renderPreviewForDesktop:(ZYDesktopWindow*)desktop {
	@autoreleasepool {
		UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen.bounds.size, YES, UIScreen.mainScreen.scale);
		CGContextRef c = UIGraphicsGetCurrentContext();

	    [[_logos_static_class_lookup$SBWallpaperController() sharedInstance] beginRequiringWithReason:@"BeautifulAnimation"];

		ON_MAIN_THREAD(^{
		    [[_logos_static_class_lookup$SBUIController() sharedInstance] restoreContentAndUnscatterIconsAnimated:NO];
		

			[MSHookIvar<UIWindow*>([_logos_static_class_lookup$SBWallpaperController() sharedInstance], "_wallpaperWindow").layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; 
		
		
			

			[[[_logos_static_class_lookup$SBUIController() sharedInstance] window] drawViewHierarchyInRect:UIScreen.mainScreen.bounds afterScreenUpdates:YES];

			[desktop drawViewHierarchyInRect:UIScreen.mainScreen.bounds afterScreenUpdates:YES];
		});
		

		for (UIView *view in desktop.subviews) 
		{
			if ([view isKindOfClass:[ZYWindowBar class]])
			{
				ZYHostedAppView *hostedView = [((ZYWindowBar*)view) attachedView];

				UIImage *image = [self snapshotForIdentifier:hostedView.bundleIdentifier orientation:hostedView.orientation];
				CIImage *coreImage = image.CIImage;
				if (!coreImage)
				    coreImage = [CIImage imageWithCGImage:image.CGImage];

				
				CGFloat rotation = atan2(hostedView.transform.b, hostedView.transform.a);

				CGAffineTransform transform = CGAffineTransformMakeRotation(rotation);
				coreImage = [coreImage imageByApplyingTransform:transform];
				image = [UIImage imageWithCIImage:coreImage];
				[image drawInRect:view.frame]; 
			}
		}
		
		
		UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
		image = [self rotateImageToMatchOrientation:image];
		MSHookIvar<UIWindow*>([_logos_static_class_lookup$SBWallpaperController() sharedInstance], "_wallpaperWindow").layer.contents = nil;
		[[[_logos_static_class_lookup$SBUIController() sharedInstance] window] layer].contents = nil;
		desktop.layer.contents = nil;
		[[_logos_static_class_lookup$SBWallpaperController() sharedInstance] endRequiringWithReason:@"BeautifulAnimation"];
		return image;
	}
}


-(UIImage*) wallpaperImage {
	return [self wallpaperImage:YES];
}


-(UIImage*) wallpaperImage:(BOOL)blurred {
	NSString *key = blurred ? @"wallpaperImageBlurred" : @"wallpaperImage";
	if ([imageCache objectForKey:key])
		return [imageCache objectForKey:key];

	UIGraphicsBeginImageContextWithOptions(UIScreen.mainScreen.bounds.size, YES, UIScreen.mainScreen.scale);
	CGContextRef c = UIGraphicsGetCurrentContext();

    [[_logos_static_class_lookup$SBWallpaperController() sharedInstance] beginRequiringWithReason:@"ZYWallpaperSnapshot"];

    [MSHookIvar<UIWindow*>([_logos_static_class_lookup$SBWallpaperController() sharedInstance], "_wallpaperWindow").layer performSelectorOnMainThread:@selector(renderInContext:) withObject:(__bridge id)c waitUntilDone:YES]; 

	UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	MSHookIvar<UIWindow*>([_logos_static_class_lookup$SBWallpaperController() sharedInstance], "_wallpaperWindow").layer.contents = nil;
	[[_logos_static_class_lookup$SBWallpaperController() sharedInstance] endRequiringWithReason:@"ZYWallpaperSnapshot"];

	
	

	if (blurred)
	{
		CIFilter *gaussianBlurFilter = [CIFilter filterWithName:@"CIGaussianBlur"];
		[gaussianBlurFilter setDefaults];
		CIImage *inputImage = [CIImage imageWithCGImage:[image CGImage]];
		[gaussianBlurFilter setValue:inputImage forKey:kCIInputImageKey];
		[gaussianBlurFilter setValue:@25 forKey:kCIInputRadiusKey];

		CIImage *outputImage = [gaussianBlurFilter outputImage];
		outputImage = [outputImage imageByCroppingToRect:CGRectMake(0, 0, image.size.width * UIScreen.mainScreen.scale, image.size.height * UIScreen.mainScreen.scale)];
		CIContext *context = [CIContext contextWithOptions:nil];
		CGImageRef cgimg = [context createCGImage:outputImage fromRect:[inputImage extent]];  
		image = [UIImage imageWithCGImage:cgimg];
		CGImageRelease(cgimg);
	}

	[imageCache setObject:image forKey:key];

	return image;
}


-(void) forceReloadEverything {
	[imageCache removeAllObjects];
}
@end
#line 303 "ZYSnapshotProvider.xm"
