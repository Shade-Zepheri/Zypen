#import "ZYWindowBar.h"
#import "ZYDesktopWindow.h"

typedef NS_ENUM(NSInteger, ZYWindowSnapLocation) {
	ZYWindowSnapLocationInvalid = 0,

	ZYWindowSnapLocationLeftTop,
	ZYWindowSnapLocationLeftMiddle,
	ZYWindowSnapLocationLeftBottom,

	ZYWindowSnapLocationRightTop,
	ZYWindowSnapLocationRightMiddle,
	ZYWindowSnapLocationRightBottom,

	ZYWindowSnapLocationBottom,
	ZYWindowSnapLocationTop,
	ZYWindowSnapLocationBottomCenter,

	ZYWindowSnapLocationBottomLeft = ZYWindowSnapLocationLeftBottom,
	ZYWindowSnapLocationBottomRight = ZYWindowSnapLocationRightBottom,

	ZYWindowSnapLocationRight = ZYWindowSnapLocationRightMiddle,
	ZYWindowSnapLocationLeft = ZYWindowSnapLocationLeftMiddle,
	ZYWindowSnapLocationNone = ZYWindowSnapLocationInvalid,
};

@interface ZYWindowSnapDataProvider : NSObject
+ (BOOL)shouldSnapWindow:(ZYWindowBar*)bar;
+ (ZYWindowSnapLocation)snapLocationForWindow:(ZYWindowBar*)windowBar;
+ (CGPoint)snapCenterForWindow:(ZYWindowBar*)window toLocation:(ZYWindowSnapLocation)location;
+ (void)snapWindow:(ZYWindowBar*)window toLocation:(ZYWindowSnapLocation)location animated:(BOOL)animated;
+ (void)snapWindow:(ZYWindowBar*)window toLocation:(ZYWindowSnapLocation)location animated:(BOOL)animated completion:(dispatch_block_t)completionBlock;
@end

ZYWindowSnapLocation ZYWindowSnapLocationGetLeftOfScreen();
ZYWindowSnapLocation ZYWindowSnapLocationGetRightOfScreen();
