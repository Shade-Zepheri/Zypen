#line 1 "ZYHostedAppView.xm"
#import "ZYHostedAppView.h"
#import "ZYHostManager.h"
#import "Messaging/ZYMessagingServer.h"
#import "ZYSnapshotProvider.h"
#import "dispatch_after_cancel.h"

NSMutableDictionary *appsBeingHosted = [NSMutableDictionary dictionary];

@interface ZYHostedAppView () {
    
    BOOL isPreloading;
    FBWindowContextHostManager *contextHostManager;

    UIActivityIndicatorView *activityView;
    UIImageView *splashScreenImageView;

    UILabel *isForemostAppLabel;

    UILabel *authenticationDidFailLabel;
    UITapGestureRecognizer *authenticationFailedRetryTapGesture;

    int startTries;
    BOOL disablePreload;

    NSTimer *loadedTimer;
}
@end


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

@class SBReachabilityManager; @class SBApplicationController; @class FBProcessManager; 

static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$FBProcessManager(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("FBProcessManager"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBApplicationController(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBApplicationController"); } return _klass; }static __inline__ __attribute__((always_inline)) __attribute__((unused)) Class _logos_static_class_lookup$SBReachabilityManager(void) { static Class _klass; if(!_klass) { _klass = objc_getClass("SBReachabilityManager"); } return _klass; }
#line 29 "ZYHostedAppView.xm"
@implementation ZYHostedAppView

-(id) initWithBundleIdentifier:(NSString*)bundleIdentifier {
	if (self = [super init])
	{
		self.bundleIdentifier = bundleIdentifier;
        self.autosizesApp = NO;
        self.allowHidingStatusBar = YES;
        self.showSplashscreenInsteadOfSpinner = NO;
        startTries = 0;
        disablePreload = NO;
        self.renderWallpaper = NO;
        self.backgroundColor = [UIColor clearColor];
	}
	return self;
}


-(void) _preloadOrAttemptToUpdateReachabilityCounterpart {
    if (app)
    {
        if ([app mainScene])
        {
            isPreloading = NO;
            if (((SBReachabilityManager*)[_logos_static_class_lookup$SBReachabilityManager() sharedInstance]).reachabilityModeActive && [GET_SBWORKSPACE respondsToSelector:@selector(ZY_updateViewSizes)])
                [GET_SBWORKSPACE performSelector:@selector(ZY_updateViewSizes) withObject:nil afterDelay:0.5]; 
        }
        else if (![app mainScene])
        {
            if (disablePreload)
                disablePreload = NO;
            else
                [self preloadApp];
        }
    }
}


-(void) setBundleIdentifier:(NSString*)value {
    _orientation = UIInterfaceOrientationPortrait;
    _bundleIdentifier = value;
    app = [[_logos_static_class_lookup$SBApplicationController() sharedInstance] ZY_applicationWithBundleIdentifier:value];
}


-(void) setShouldUseExternalKeyboard:(BOOL)value {
    _shouldUseExternalKeyboard = value;
    [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:value forApp:self.bundleIdentifier completion:nil];
}


-(void) preloadApp {
    startTries++;
    if (startTries > 5)
    {
        isPreloading = NO;
        HBLogDebug(@"[ReachApp] maxed out preload attempts for app %@", app.bundleIdentifier);
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:LOCALIZE(@"MULTIPLEXER") message:[NSString stringWithFormat:@"Unable to start app %@", app.displayName] delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
        return;
    }

    if (app == nil)
        return;

    if (_isCurrentlyHosting)
        return;

    isPreloading = YES;
	FBScene *scene = [app mainScene];
    if (![app pid] || scene == nil)
    {
        [UIApplication.sharedApplication launchApplicationWithIdentifier:self.bundleIdentifier suspended:YES];
        [[_logos_static_class_lookup$FBProcessManager() sharedInstance] createApplicationProcessForBundleID:self.bundleIdentifier]; 
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self _preloadOrAttemptToUpdateReachabilityCounterpart]; });
    
    
}


-(void) _actualLoadApp {
    if (isPreloading)
    {
        [self performSelector:@selector(_actualLoadApp) withObject:nil afterDelay:0.3];
        return;
    }

    if (_isCurrentlyHosting)
        return;
    _isCurrentlyHosting = YES;

    appsBeingHosted[app.bundleIdentifier] = [appsBeingHosted objectForKey:app.bundleIdentifier] ? @([appsBeingHosted[app.bundleIdentifier] intValue] + 1) : @1;
    view = (FBWindowContextHostWrapperView*)[ZYHostManager enabledHostViewForApplication:app];
    contextHostManager = (FBWindowContextHostManager*)[ZYHostManager hostManagerForApp:app];
    view.backgroundColorWhileNotHosting = [UIColor clearColor];
    view.backgroundColorWhileHosting = [UIColor clearColor];

    view.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    

    [self addSubview:view];

    [ZYMessagingServer.sharedInstance setHosted:YES forIdentifier:app.bundleIdentifier completion:nil];
    
        [ZYHostedAppView iPad_iOS83_fixHosting];

    [ZYRunningAppsProvider.sharedInstance addTarget:self];

    loadedTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(verifyHostingAndRehostIfNecessary) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:loadedTimer forMode:NSRunLoopCommonModes];
}


-(void) loadApp {
    startTries = 0;
    disablePreload = NO;
	[self preloadApp];
    if (!app)
        return;

    if (_isCurrentlyHosting)
        return;

    if ([UIApplication.sharedApplication._accessibilityFrontMostApplication isEqual:app])
    {
        isForemostAppLabel = [[UILabel alloc] initWithFrame:self.bounds];
        isForemostAppLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        isForemostAppLabel.textColor = [UIColor whiteColor];
        isForemostAppLabel.textAlignment = NSTextAlignmentCenter;
        isForemostAppLabel.font = [UIFont systemFontOfSize:36];
        isForemostAppLabel.numberOfLines = 0;
        isForemostAppLabel.lineBreakMode = NSLineBreakByWordWrapping;
        isForemostAppLabel.text = [NSString stringWithFormat:LOCALIZE(@"ACTIVE_APP_WARNING"),self.app.displayName];
        [self addSubview:isForemostAppLabel];
        return;
    }

    IF_BIOLOCKDOWN {
        id failedBlock = ^{
            [self removeLoadingIndicator];
            if (!authenticationDidFailLabel)
            {
                authenticationDidFailLabel = [[UILabel alloc] initWithFrame:self.bounds];
                authenticationDidFailLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                authenticationDidFailLabel.textColor = [UIColor whiteColor];
                authenticationDidFailLabel.textAlignment = NSTextAlignmentCenter;
                authenticationDidFailLabel.font = [UIFont systemFontOfSize:36];
                authenticationDidFailLabel.numberOfLines = 0;
                authenticationDidFailLabel.lineBreakMode = NSLineBreakByWordWrapping;
                authenticationDidFailLabel.text = [NSString stringWithFormat:LOCALIZE(@"BIOLOCKDOWN_AUTH_FAILED"),self.app.displayName];
                [self addSubview:authenticationDidFailLabel];

                authenticationFailedRetryTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadApp)];
                [self addGestureRecognizer:authenticationFailedRetryTapGesture];
                self.userInteractionEnabled = YES;
            }
        };

        BIOLOCKDOWN_AUTHENTICATE_APP(app.bundleIdentifier, ^{
            [self _actualLoadApp];
        }, failedBlock );
    }
    else
    {
        IF_ASPHALEIA2 {
            void (^failedBlock)() = ^{
                [self removeLoadingIndicator];
                if (!authenticationDidFailLabel)
                {
                    authenticationDidFailLabel = [[UILabel alloc] initWithFrame:self.bounds];
                    authenticationDidFailLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
                    authenticationDidFailLabel.textColor = [UIColor whiteColor];
                    authenticationDidFailLabel.textAlignment = NSTextAlignmentCenter;
                    authenticationDidFailLabel.font = [UIFont systemFontOfSize:36];
                    authenticationDidFailLabel.numberOfLines = 0;
                    authenticationDidFailLabel.lineBreakMode = NSLineBreakByWordWrapping;
                    authenticationDidFailLabel.text = [NSString stringWithFormat:LOCALIZE(@"ASPHALEIA2_AUTH_FAILED"),self.app.displayName];
                    [self addSubview:authenticationDidFailLabel];

                    authenticationFailedRetryTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(loadApp)];
                    [self addGestureRecognizer:authenticationFailedRetryTapGesture];
                    self.userInteractionEnabled = YES;
                }
            };

            ASPHALEIA2_AUTHENTICATE_APP(app.bundleIdentifier, ^{
                [self _actualLoadApp];
            }, failedBlock);
        }
        else
            [self _actualLoadApp];
    }

    if (self.showSplashscreenInsteadOfSpinner)
    {
        if (splashScreenImageView)
        {
            [splashScreenImageView removeFromSuperview];
            splashScreenImageView = nil;
        }
        UIImage *img = [ZYSnapshotProvider.sharedInstance snapshotForIdentifier:self.bundleIdentifier];
        splashScreenImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        splashScreenImageView.image = img;
        [self insertSubview:splashScreenImageView atIndex:0];
    }
    else
    {
        if (!activityView)
        {
            activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [self addSubview:activityView];
        }

        CGFloat size = 50;
        activityView.frame = CGRectMake((self.bounds.size.width - size) / 2, (self.bounds.size.height - size) / 2, size, size);

        [activityView startAnimating];
    }
}


-(void) verifyHostingAndRehostIfNecessary {
    if (!isPreloading && _isCurrentlyHosting && (app.isRunning == NO || view.contextHosted == NO)) 
    {
        
        [self unloadApp];
        [self loadApp];
    }
    else
    {
        [self removeLoadingIndicator];
        [loadedTimer invalidate];
        loadedTimer = nil;
    }
}


-(void) appDidDie:(SBApplication*)app_ {
    if (app_ == self.app)
    {
        [self verifyHostingAndRehostIfNecessary];
    }
}


-(void) removeLoadingIndicator {
    if (self.showSplashscreenInsteadOfSpinner)
    {
        [splashScreenImageView removeFromSuperview];
        splashScreenImageView = nil;
    }
    else if (activityView)
        [activityView stopAnimating];
}


-(void) drawRect:(CGRect)rect {
    if (_renderWallpaper)
        [[ZYSnapshotProvider.sharedInstance wallpaperImage] drawInRect:rect];
}


-(void) setFrame:(CGRect)frame {
    [super setFrame:frame];
    [view setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

    if (self.autosizesApp)
    {
        ZYMessageAppData data = [ZYMessagingServer.sharedInstance getDataForIdentifier:self.bundleIdentifier];
        data.canHideStatusBarIfWanted = self.allowHidingStatusBar;
        [ZYMessagingServer.sharedInstance setData:data forIdentifier:self.bundleIdentifier];
        [ZYMessagingServer.sharedInstance resizeApp:self.bundleIdentifier toSize:CGSizeMake(frame.size.width, frame.size.height) completion:nil];

    }
    else if (self.bundleIdentifier)
    {
        [ZYMessagingServer.sharedInstance endResizingApp:self.bundleIdentifier completion:nil];
    }
}


-(void) setHideStatusBar:(BOOL)value {
    _hideStatusBar = value;

    if (!self.bundleIdentifier)
        return;

    if (value)
        [ZYMessagingServer.sharedInstance forceStatusBarVisibility:!value forApp:self.bundleIdentifier completion:nil];
    else
        [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:nil];
}


-(void) unloadApp {
    [self unloadApp:NO];
}


-(void) unloadApp:(BOOL)forceImmediate {
    
    
    [self removeLoadingIndicator];
    [loadedTimer invalidate];
    loadedTimer = nil;

    [ZYRunningAppsProvider.sharedInstance removeTarget:self];

    disablePreload = YES;

    if (_isCurrentlyHosting == NO)
        return;

    _isCurrentlyHosting = NO;

    FBScene *scene = [app mainScene];

    if (authenticationDidFailLabel)
    {
        [authenticationDidFailLabel removeFromSuperview];
        authenticationDidFailLabel = nil;

        [self removeGestureRecognizer:authenticationFailedRetryTapGesture];
        self.userInteractionEnabled = NO;
    }

    if (isForemostAppLabel)
    {
        [isForemostAppLabel removeFromSuperview];
        isForemostAppLabel = nil;
    }

    if ([ZYSpringBoardKeyboardActivation.sharedInstance.currentIdentifier isEqual:self.bundleIdentifier])
        [ZYSpringBoardKeyboardActivation.sharedInstance hideKeyboard];

    if (contextHostManager)
    {
        [contextHostManager disableHostingForRequester:@"reachapp"];
        contextHostManager = nil;
    }

    
    

    __weak ZYHostedAppView *weakSelf = self;
    __block BOOL didRun = NO;
    ZYMessageCompletionCallback block = ^(BOOL success) {
        if (didRun || (weakSelf && [UIApplication.sharedApplication._accessibilityFrontMostApplication isEqual:weakSelf.app]))
            return;
        if (!scene)
            return;

        appsBeingHosted[app.bundleIdentifier] = [appsBeingHosted objectForKey:app.bundleIdentifier] ? @([appsBeingHosted[app.bundleIdentifier] intValue] - 1) : @0;

        if ([appsBeingHosted[app.bundleIdentifier] intValue] > 0)
            return;

        FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
        SET_BACKGROUNDED(settings, YES);
        [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
        
        didRun = YES;
    };

    [ZYMessagingServer.sharedInstance setHosted:NO forIdentifier:app.bundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance unRotateApp:self.bundleIdentifier completion:nil];
    if (forceImmediate)
    {
        [ZYMessagingServer.sharedInstance endResizingApp:self.bundleIdentifier completion:nil];
        block(YES);
    }
    else
    {
        
        
        
        
        

        [ZYMessagingServer.sharedInstance endResizingApp:self.bundleIdentifier completion:block];
    }
}


-(void) rotateToOrientation:(UIInterfaceOrientation)o {
    _orientation = o;

    [ZYMessagingServer.sharedInstance rotateApp:self.bundleIdentifier toOrientation:o completion:nil];
}


+(void) iPad_iOS83_fixHosting {
    for (NSString *bundleIdentifier in appsBeingHosted.allKeys)
    {
        NSNumber *num = appsBeingHosted[bundleIdentifier];
        if (num.intValue > 0)
        {
            SBApplication *app_ = [[_logos_static_class_lookup$SBApplicationController() sharedInstance] ZY_applicationWithBundleIdentifier:bundleIdentifier];
            FBWindowContextHostManager *manager = (FBWindowContextHostManager*)[ZYHostManager hostManagerForApp:app_];
            if (manager)
            {
                HBLogDebug(@"[ReachApp] rehosting for iPad: %@", bundleIdentifier);
                [manager enableHostingForRequester:@"reachapp" priority:1];
            }
        }
    }

}



- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL isContained = NO;
    for (UIView *subview in self.subviews)
    {
        if (CGRectContainsPoint(subview.frame, point)) 
            isContained = YES;
    }
    return isContained;
}

-(SBApplication*) app { return app; }
-(NSString*) displayName { return app.displayName; }
@end
#line 455 "ZYHostedAppView.xm"
