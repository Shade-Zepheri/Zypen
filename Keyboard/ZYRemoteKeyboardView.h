#import "headers.h"

@interface CALayerHost : CALayer
@property (nonatomic, assign) unsigned int contextId;
@end

@interface ZYRemoteKeyboardView : UIView {
	BOOL update;
	NSString *_identifier;
}
@property (nonatomic, retain) CALayerHost *layerHost;
-(void) connectToKeyboardWindowForApp:(NSString*)identifier;
@end
