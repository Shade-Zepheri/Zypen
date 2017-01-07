#import "headers.h"
#import "ZYBackgrounder.h"
#include <execinfo.h>
#include <stdio.h>
#include <stdlib.h>

@interface FBApplicationInfo : NSObject
@property (nonatomic, copy) NSString *bundleIdentifier;
- (BOOL)isExitsOnSuspend;
@end

%hook FBApplicationInfo
- (BOOL)supportsBackgroundMode:(__unsafe_unretained NSString *)mode {
	NSInteger override = [ZYBackgrounder.sharedInstance application:self.bundleIdentifier overrideBackgroundMode:mode];
    if (override == -1) {
      return %orig;
    }
	return override;
}
%end
