@class SBWorkspace;

@interface ZYSBWorkspaceFetcher : NSObject
+(Class) SBWorkspaceClass;
+(SBWorkspace*) getCurrentSBWorkspaceImplementationInstanceForThisOS;
@end
