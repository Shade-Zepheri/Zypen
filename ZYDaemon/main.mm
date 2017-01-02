#include <dlfcn.h>
#include <notify.h>
#include <stdio.h>
#include <stdlib.h>
#import <Foundation/Foundation.h>
#import "headers.h"
#import <objc/runtime.h>

int main(int argc, char **argv, char **envp) {
	@autoreleasepool {

    NSString *filePath = @"/var/mobile/Library/.zypen.uiappexitsonsuspend.wantstochangerootapp";
      if ([NSFileManager.defaultManager fileExistsAtPath:filePath] == NO) {
          HBLogDebug(@"[ReachApp] FS Daemon: plist does not exist");
          return 0;
      }

  	NSDictionary *contents = [NSDictionary dictionaryWithContentsOfFile:filePath];

      LSApplicationProxy *appInfo = [objc_getClass("LSApplicationProxy") applicationProxyForIdentifier:contents[@"bundleIdentifier"]];
      NSString *path = [NSString stringWithFormat:@"%@/Info.plist",appInfo.bundleURL.absoluteString];
      NSMutableDictionary *infoPlist = [NSMutableDictionary dictionaryWithContentsOfURL:[NSURL URLWithString:path]];
      infoPlist[@"UIApplicationExitsOnSuspend"] = contents[@"UIApplicationExitsOnSuspend"];
      BOOL success = [infoPlist writeToURL:[NSURL URLWithString:path] atomically:YES];

      if (!success) {
        HBLogDebug(@"[ReachApp] FS Daemon: error writing to plist: %@", path);
      } else {
				HBLogDebug(@"Wrote to Plist and Removing");
        [NSFileManager.defaultManager removeItemAtPath:filePath error:nil];
      }

  }
	return 0;
}
