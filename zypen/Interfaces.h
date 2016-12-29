#import <Preferences/PSListController.h>
#import <Preferences/PSListItemsController.h>

@interface PSListItemsController (tableView)
- (void)tableView:(id)arg1 didSelectRowAtIndexPath:(id)arg2;
- (void)listItemSelected:(id)arg1;
- (id)tableView:(id)arg1 cellForRowAtIndexPath:(id)arg2;
@end

@interface ZYPRootListController : PSListController

@end

@interface ZYPAuraController : PSListController

@end

@interface ZYPOptionsController : PSListController

@end

@interface ZYPEmpoleonController : PSListController

@end

@interface ZYPAboutController : PSListController

@end

@interface ZYPAppChooserOptionsListController : PSListController

@end

@interface ZYBackgrounderIconIndicatorOptionsListController : PSListController

@end

@interface ZYBackgrounderStatusbarOptionsListController : PSListController

@end

@interface ZYPPerAppController : PSListController

@end
