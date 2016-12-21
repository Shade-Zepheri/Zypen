#include "Interfaces.h"

@implementation ZYPRootListController

- (NSArray *)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiersFromPlistName:@"Zypen" target:self] retain];
	}

	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];

	CGRect frame = CGRectMake(0, 0, self.table.bounds.size.width, 127);

	UIImage *headerImage = [[UIImage alloc]
		initWithContentsOfFile:[[NSBundle bundleWithPath:@"/Library/PreferenceBundles/zypen.bundle"] pathForResource:@"zypenHeader" ofType:@"png"]];

	UIImageView *headerView = [[UIImageView alloc] initWithFrame:frame];
	[headerView setImage:headerImage];
	headerView.backgroundColor = [UIColor blackColor];
	[headerView setContentMode:UIViewContentModeScaleAspectFit];
	[headerView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];

	self.table.tableHeaderView = headerView;
}

- (void)viewDidLayoutSubviews {
	[super viewDidLayoutSubviews];

	CGRect wrapperFrame = ((UIView *)self.table.subviews[0]).frame; // UITableViewWrapperView
	CGRect frame = CGRectMake(wrapperFrame.origin.x, self.table.tableHeaderView.frame.origin.y, wrapperFrame.size.width, self.table.tableHeaderView.frame.size.height);

	self.table.tableHeaderView.frame = frame;
}

@end
