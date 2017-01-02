#import <dlfcn.h>
#import <Foundation/Foundation.h>

%hookf(int, "_BSAuditTokenTaskHasEntitlement", int unknownFlag, NSString *entitlement) {
	if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
		return 1;
	}
	return %orig;
}
