// Uofist | https://t.me/iOS6Great
#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate, UISplitViewControllerDelegate>
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) UINavigationController *navController;
@property (strong, nonatomic) UISplitViewController *splitViewController;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;
@property (strong, nonatomic) UIBarButtonItem *masterButtonItem;
- (void)configureDetailViewController:(UIViewController *)vc;
- (void)rebuildRootViewController;
@end
