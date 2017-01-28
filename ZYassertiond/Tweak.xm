#import <dlfcn.h>
#import <substrate.h>
#import <Foundation/Foundation.h>

extern const char *__progname;

static int (*orig_BSAuditTokenTaskHasEntitlement)(id connection, NSString *entitlement);
static int hax_BSAuditTokenTaskHasEntitlement(__unsafe_unretained id connection, __unsafe_unretained NSString *entitlement) {
    if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
        return true;
    }

    return orig_BSAuditTokenTaskHasEntitlement(connection, entitlement);
}

static int (*orig_BSXPCConnectionHasEntitlement)(id connection, NSString *entitlement);
static int hax_BSXPCConnectionHasEntitlement(__unsafe_unretained id connection, __unsafe_unretained NSString *entitlement) {
    if ([entitlement isEqualToString:@"com.apple.multitasking.unlimitedassertions"]) {
        return true;
    }

    return orig_BSXPCConnectionHasEntitlement(connection, entitlement);
}

%ctor {
    // We can never be too sure
	if (strcmp(__progname, "assertiond") == 0)  {
        HBLogDebug(@"Is assertiond");
        dlopen("/System/Library/PrivateFrameworks/XPCObjects.framework/XPCObjects", RTLD_LAZY);
        void *BSAuditFunction = MSFindSymbol(NULL, "_BSAuditTokenTaskHasEntitlement");
        void *xpcFunction = MSFindSymbol(NULL, "_BSXPCConnectionHasEntitlement");
        MSHookFunction(BSAuditFunction, (void *)hax_BSAuditTokenTaskHasEntitlement, (void **)&orig_BSAuditTokenTaskHasEntitlement);
        MSHookFunction(xpcFunction, (void *)hax_BSXPCConnectionHasEntitlement, (void **)&orig_BSXPCConnectionHasEntitlement);
    }
}
