#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>

#define RedColor [UIColor colorWithRed:248/255.0f green:73/255.0f blue:88/255.0f alpha:1.0f];
#define DarkRedColor [UIColor colorWithRed:255/255.0f green:111/255.0f blue:124/255.0f alpha:1.0f];
#define PurpleColor [UIColor colorWithRed:0.40 green:0.23 blue:0.72 alpha:1.0];
#define DarkPurpleColor [UIColor colorWithRed:0.19 green:0.11 blue:0.57 alpha:1.0];
#define OrangeColor [UIColor colorWithRed:255/255.0f green:94/255.0f blue:58/255.0f alpha:1.0f];
#define DarkOrangeColor [UIColor colorWithRed:255/255.0f green:149/255.0f blue:0/255.0f alpha:1.0f];

@interface PSListItemsController (tableView)
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
- (void)listItemSelected:(id)arg1;
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
@end

@interface ZYPRootListController : PSListController {
	UIStatusBarStyle prevStatusStyle;
}

@end

@interface ZYPAuraController : PSListController {
	UIStatusBarStyle prevStatusStyle;
}

@end

@interface ZYPOptionsController : PSListController {
	UIStatusBarStyle prevStatusStyle;
}

@end

@interface ZYPEmpoleonController : PSListController {
	UIStatusBarStyle prevStatusStyle;
}

@end

@interface ZYPAboutController : PSListController

@end

@interface ZYPAppChooserOptionsListController : PSListController

@end

@interface ZYBackgrounderIconIndicatorOptionsListController : PSListController

@end

@interface ZYBackgrounderStatusbarOptionsListController : PSListController

@end
