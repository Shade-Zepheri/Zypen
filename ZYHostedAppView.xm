#import "ZYHostedAppView.h"
#import "ZYHostManager.h"
#import "ZYMessagingServer.h"
#import "ZYSnapshotProvider.h"
#import "dispatch_after_cancel.h"
#import "headers.h"

NSMutableDictionary *appsBeingHosted = [NSMutableDictionary dictionary];

@interface ZYHostedAppView () {
    //NSTimer *verifyTimer;
    BOOL isPreloading;
    FBWindowContextHostManager *contextHostManager;

    UIActivityIndicatorView *activityView;
    UIImageView *splashScreenImageView;

    UILabel *isForemostAppLabel;

    UILabel *authenticationDidFailLabel;
    UITapGestureRecognizer *authenticationFailedRetryTapGesture;

    NSInteger startTries;
    BOOL disablePreload;

    NSTimer *loadedTimer;
}
@end

@implementation ZYHostedAppView
- (id)initWithBundleIdentifier:(NSString*)bundleIdentifier {
	if (self = [super init]) {
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

- (void)_preloadOrAttemptToUpdateReachabilityCounterpart {
    if (app) {
        if ([app mainScene]) {
            isPreloading = NO;
            if (((SBReachabilityManager*)[%c(SBReachabilityManager) sharedInstance]).reachabilityModeActive && [GET_SBWORKSPACE respondsToSelector:@selector(ZY_updateViewSizes)]) {
                [GET_SBWORKSPACE performSelector:@selector(ZY_updateViewSizes) withObject:nil afterDelay:0.5]; // App is launched using ReachApp - animations commence. We have to wait for those animations to finish or this won't work.
            }
        } else if (![app mainScene]) {
            if (disablePreload) {
                disablePreload = NO;
            } else {
                [self preloadApp];
            }
        }
    }
}

- (void)setBundleIdentifier:(NSString*)value {
    _orientation = UIInterfaceOrientationPortrait;
    _bundleIdentifier = value;
    app = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:value];
}

- (void)setShouldUseExternalKeyboard:(BOOL)value {
    _shouldUseExternalKeyboard = value;
    [ZYMessagingServer.sharedInstance setShouldUseExternalKeyboard:value forApp:self.bundleIdentifier completion:nil];
}

- (void)preloadApp {
    startTries++;
    if (startTries > 5) {
        isPreloading = NO;
        HBLogDebug(@"[ReachApp] maxed out preload attempts for app %@", app.bundleIdentifier);
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Zypen"
                               message:[NSString stringWithFormat:@"Unable to start app %@", app.displayName]
                               preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                          handler:^(UIAlertAction * action) {}];
        [alert addAction:defaultAction];
        [self.inputViewController presentViewController:alert animated:YES completion:nil];
        return;
    }

    if (app == nil) {
        return;
    }
    if (_isCurrentlyHosting) {
        return;
    }

    isPreloading = YES;
	  FBScene *scene = [app mainScene];
    if (![app pid] || scene == nil) {
        [UIApplication.sharedApplication launchApplicationWithIdentifier:self.bundleIdentifier suspended:YES];
        [[%c(FBProcessManager) sharedInstance] createApplicationProcessForBundleID:self.bundleIdentifier]; // ummm...?
    }
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{ [self _preloadOrAttemptToUpdateReachabilityCounterpart]; });
    // this ^ runs either way. when _preloadOrAttemptToUpdateReachabilityCounterpart runs, if the app is "loaded" it will not call preloadApp again, otherwise
    // it will call it again.
}

- (void)_actualLoadApp {
    if (isPreloading) {
        [self performSelector:@selector(_actualLoadApp) withObject:nil afterDelay:0.3];
        return;
    }

    if (_isCurrentlyHosting) {
        return;
    }
    _isCurrentlyHosting = YES;

    appsBeingHosted[app.bundleIdentifier] = [appsBeingHosted objectForKey:app.bundleIdentifier] ? @([appsBeingHosted[app.bundleIdentifier] intValue] + 1) : @1;
    view = (FBWindowContextHostWrapperView*)[ZYHostManager enabledHostViewForApplication:app];
    contextHostManager = (FBWindowContextHostManager*)[ZYHostManager hostManagerForApp:app];
    view.backgroundColorWhileNotHosting = [UIColor clearColor];
    view.backgroundColorWhileHosting = [UIColor clearColor];

    view.frame = CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height);
    //view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self addSubview:view];

    [ZYMessagingServer.sharedInstance setHosted:YES forIdentifier:app.bundleIdentifier completion:nil];
    //if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
        [ZYHostedAppView iPad_iOS83_fixHosting];
    //}

    [ZYRunningAppsProvider.sharedInstance addTarget:self];

    loadedTimer = [NSTimer timerWithTimeInterval:1 target:self selector:@selector(verifyHostingAndRehostIfNecessary) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:loadedTimer forMode:NSRunLoopCommonModes];
}

- (void)loadApp {
    startTries = 0;
    disablePreload = NO;
	  [self preloadApp];
    if (!app) {
      return;
    }

    if (_isCurrentlyHosting) {
      return;
    }

    if ([UIApplication.sharedApplication._accessibilityFrontMostApplication isEqual:app]) {
        isForemostAppLabel = [[UILabel alloc] initWithFrame:self.bounds];
        isForemostAppLabel.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.8];
        isForemostAppLabel.textColor = [UIColor whiteColor];
        isForemostAppLabel.textAlignment = NSTextAlignmentCenter;
        isForemostAppLabel.font = [UIFont systemFontOfSize:36];
        isForemostAppLabel.numberOfLines = 0;
        isForemostAppLabel.lineBreakMode = NSLineBreakByWordWrapping;
        isForemostAppLabel.text = [NSString stringWithFormat:@"%@\n is currently open",self.app.displayName];
        [self addSubview:isForemostAppLabel];
        return;
    }

    [self _actualLoadApp];

    if (self.showSplashscreenInsteadOfSpinner) {
        if (splashScreenImageView) {
            [splashScreenImageView removeFromSuperview];
            splashScreenImageView = nil;
        }
        UIImage *img = [ZYSnapshotProvider.sharedInstance snapshotForIdentifier:self.bundleIdentifier];
        splashScreenImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height)];
        splashScreenImageView.image = img;
        [self insertSubview:splashScreenImageView atIndex:0];
    } else {
        if (!activityView) {
            activityView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            [self addSubview:activityView];
        }

        CGFloat size = 50;
        activityView.frame = CGRectMake((self.bounds.size.width - size) / 2, (self.bounds.size.height - size) / 2, size, size);

        [activityView startAnimating];
    }
}

- (void)verifyHostingAndRehostIfNecessary {
    if (!isPreloading && _isCurrentlyHosting && (app.isRunning == NO || view.contextHosted == NO)) {
        //[activityView startAnimating];
        [self unloadApp];
        [self loadApp];
    } else {
        [self removeLoadingIndicator];
        [loadedTimer invalidate];
        loadedTimer = nil;
    }
}

- (void)appDidDie:(SBApplication*)app_ {
    if (app_ == self.app) {
        [self verifyHostingAndRehostIfNecessary];
    }
}

- (void)removeLoadingIndicator {
    if (self.showSplashscreenInsteadOfSpinner) {
        [splashScreenImageView removeFromSuperview];
        splashScreenImageView = nil;
    } else if (activityView) {
        [activityView stopAnimating];
    }
}

- (void)drawRect:(CGRect)rect {
    if (_renderWallpaper) {
        [[ZYSnapshotProvider.sharedInstance wallpaperImage] drawInRect:rect];
    }
}

- (void)setFrame:(CGRect)frame {
    [super setFrame:frame];
    [view setFrame:CGRectMake(0, 0, frame.size.width, frame.size.height)];

    if (self.autosizesApp) {
        ZYMessageAppData data = [ZYMessagingServer.sharedInstance getDataForIdentifier:self.bundleIdentifier];
        data.canHideStatusBarIfWanted = self.allowHidingStatusBar;
        [ZYMessagingServer.sharedInstance setData:data forIdentifier:self.bundleIdentifier];
        [ZYMessagingServer.sharedInstance resizeApp:self.bundleIdentifier toSize:CGSizeMake(frame.size.width, frame.size.height) completion:nil];

    } else if (self.bundleIdentifier) {
        [ZYMessagingServer.sharedInstance endResizingApp:self.bundleIdentifier completion:nil];
    }
}

- (void)setHideStatusBar:(BOOL)value {
    _hideStatusBar = value;

    if (!self.bundleIdentifier) {
        return;
    }

    if (value) {
        [ZYMessagingServer.sharedInstance forceStatusBarVisibility:!value forApp:self.bundleIdentifier completion:nil];
    } else {
        [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:nil];
    }
}

- (void)unloadApp {
    [self unloadApp:NO];
}

- (void)unloadApp:(BOOL)forceImmediate {
    loadedTimer = nil;

    [ZYRunningAppsProvider.sharedInstance removeTarget:self];

    disablePreload = YES;

    if (_isCurrentlyHosting == NO) {
        return;
    }

    _isCurrentlyHosting = NO;

    FBScene *scene = [app mainScene];

    if (authenticationDidFailLabel) {
        [authenticationDidFailLabel removeFromSuperview];
        authenticationDidFailLabel = nil;

        [self removeGestureRecognizer:authenticationFailedRetryTapGesture];
        self.userInteractionEnabled = NO;
    }

    if (isForemostAppLabel) {
        [isForemostAppLabel removeFromSuperview];
        isForemostAppLabel = nil;
    }

    if (contextHostManager) {
        [contextHostManager disableHostingForRequester:@"Zypen"];
        contextHostManager = nil;
    }

    //if ([UIApplication.sharedApplication._accessibilityFrontMostApplication isEqual:app])
    //    return;

    __weak ZYHostedAppView *weakSelf = self;
    __block BOOL didRun = NO;
    ZYMessageCompletionCallback block = ^(BOOL success) {
        if (didRun || (weakSelf && [UIApplication.sharedApplication._accessibilityFrontMostApplication isEqual:weakSelf.app])) {
            return;
        }
        if (!scene) {
            return;
        }

        appsBeingHosted[app.bundleIdentifier] = [appsBeingHosted objectForKey:app.bundleIdentifier] ? @([appsBeingHosted[app.bundleIdentifier] intValue] - 1) : @0;

        if ([appsBeingHosted[app.bundleIdentifier] intValue] > 0) {
            return;
        }
        FBSMutableSceneSettings *settings = [[scene mutableSettings] mutableCopy];
        [settings setBackgrounded:YES];
        [scene _applyMutableSettings:settings withTransitionContext:nil completion:nil];
        didRun = YES;
    };

    [ZYMessagingServer.sharedInstance setHosted:NO forIdentifier:app.bundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:nil];
    [ZYMessagingServer.sharedInstance unRotateApp:self.bundleIdentifier completion:nil];
    if (forceImmediate) {
        [ZYMessagingServer.sharedInstance endResizingApp:self.bundleIdentifier completion:nil];
        block(YES);
    } else {
        // >Somewhere in the messaging server, the block is being removed from the waitingCompletions dictionary without being called.
        // >This is a large issue (probably to do with asynchronous code) TODO: FIXME
        // lol im retarded, it's the default empty callback the messaging server made
        //[ZYMessagingServer.sharedInstance unforceStatusBarVisibilityForApp:self.bundleIdentifier completion:block];
        //[ZYMessagingServer.sharedInstance unRotateApp:self.bundleIdentifier completion:block];

        [ZYMessagingServer.sharedInstance endResizingApp:self.bundleIdentifier completion:block];
    }
}

- (void)rotateToOrientation:(UIInterfaceOrientation)o {
    _orientation = o;

    [ZYMessagingServer.sharedInstance rotateApp:self.bundleIdentifier toOrientation:o completion:nil];
}

+ (void)iPad_iOS83_fixHosting {
    for (NSString *bundleIdentifier in appsBeingHosted.allKeys) {
        NSNumber *num = appsBeingHosted[bundleIdentifier];
        if (num.intValue > 0) {
            SBApplication *app_ = [[%c(SBApplicationController) sharedInstance] ZY_applicationWithBundleIdentifier:bundleIdentifier];
            FBWindowContextHostManager *manager = (FBWindowContextHostManager*)[ZYHostManager hostManagerForApp:app_];
            if (manager) {
                HBLogDebug(@"[ReachApp] rehosting for iPad: %@", bundleIdentifier);
                [manager enableHostingForRequester:@"Zypen" priority:1];
            }
        }
    }

}

// This allows for any subviews (with gestures) (e.g. the SwipeOver bar with a negative y origin) to recieve touch events.
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
    BOOL isContained = NO;
    for (UIView *subview in self.subviews) {
        if (CGRectContainsPoint(subview.frame, point)) {
            isContained = YES;
        }
    }
    return isContained;
}

- (SBApplication*)app {
  return app;
}

- (NSString*)displayName {
  return app.displayName;
}

@end
