#import "headers.h"
#import "RAMessagingClient.h"

BOOL allowClosingReachabilityNatively = NO;

%hook UIApplication
- (void)_deactivateReachability
{
    if (!allowClosingReachabilityNatively)
    {
        HBLogDebug(@"[ReachApp] attempting to close reachability but not allowed to.");
        return;
    }

    if ([RAMessagingClient.sharedInstance isBeingHosted])
    {
        HBLogDebug(@"[ReachApp] stopping reachability from closing because hosted");
        return;
    }
    %orig;
}
%end
