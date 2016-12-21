#import "ZYInsetLabel.h"

@implementation ZYInsetLabel
- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.textInset)];
}
@end
