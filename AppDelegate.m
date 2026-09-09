// Uofist | https://t.me/iOS6Great
#import "AppDelegate.h"

#import "ChatListViewController.h"
#import "SettingsViewController.h"

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    [self rebuildRootViewController];
    [self.window makeKeyAndVisible];
    return YES;
}

- (void)rebuildRootViewController {
    ChatListViewController *listVC = [[ChatListViewController alloc] init];
    UIViewController *newRoot = nil;

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        UINavigationController *masterNav = [[UINavigationController alloc] initWithRootViewController:listVC];
        masterNav.navigationBar.tintColor = [UIColor blackColor];

        UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:[self makePlaceholderDetailViewController]];
        detailNav.navigationBar.tintColor = [UIColor blackColor];

        self.splitViewController = [[UISplitViewController alloc] init];
        self.splitViewController.delegate = self;
        self.splitViewController.viewControllers = @[masterNav, detailNav];

        newRoot = self.splitViewController;
    } else if ([[NSUserDefaults standardUserDefaults] integerForKey:@"NavStyle"] == 1) {
        self.navController = [[UINavigationController alloc] initWithRootViewController:listVC];
        self.navController.navigationBar.tintColor = [UIColor blackColor];
        newRoot = self.navController;
    } else {
        BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];

        UINavigationController *chatsNav = [[UINavigationController alloc] initWithRootViewController:listVC];
        chatsNav.navigationBar.tintColor = [UIColor blackColor];
        chatsNav.title = isEn ? @"Chats" : @"Чаты";
        chatsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:(isEn ? @"Chats" : @"Чаты") image:[self chatsTabIcon] tag:0];

        UINavigationController *settingsNav = [[UINavigationController alloc] initWithRootViewController:[[SettingsViewController alloc] init]];
        settingsNav.navigationBar.tintColor = [UIColor blackColor];
        settingsNav.title = isEn ? @"Settings" : @"Настройки";
        settingsNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:(isEn ? @"Settings" : @"Настройки") image:[self settingsTabIcon] tag:1];

        UITabBarController *tabController = [[UITabBarController alloc] init];
        tabController.viewControllers = @[chatsNav, settingsNav];
        newRoot = tabController;
    }

    [UIView transitionWithView:self.window duration:0.3 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
        self.window.rootViewController = newRoot;
    } completion:nil];
}

- (UIImage *)chatsTabIcon {
    CGSize size = CGSizeMake(25, 25);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    UIBezierPath *bubble = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(2, 3, 21, 14) cornerRadius:4];
    [bubble moveToPoint:CGPointMake(9, 17)];
    [bubble addLineToPoint:CGPointMake(6, 22)];
    [bubble addLineToPoint:CGPointMake(13, 17)];
    [bubble closePath];
    [[UIColor blackColor] setFill];
    [bubble fill];
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIImage *)settingsTabIcon {
    CGSize size = CGSizeMake(25, 25);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGFloat cx = 12.5, cy = 12.5, radius = 6.0, toothLen = 4.0, toothW = 3.0;
    UIBezierPath *ring = [UIBezierPath bezierPathWithArcCenter:CGPointMake(cx, cy) radius:radius startAngle:0 endAngle:M_PI * 2 clockwise:YES];
    ring.lineWidth = 2.5;
    [[UIColor blackColor] setStroke];
    [ring stroke];
    [[UIColor blackColor] setFill];
    UIRectFill(CGRectMake(cx - toothW / 2, cy - radius - toothLen, toothW, toothLen));
    UIRectFill(CGRectMake(cx - toothW / 2, cy + radius, toothW, toothLen));
    UIRectFill(CGRectMake(cx - radius - toothLen, cy - toothW / 2, toothLen, toothW));
    UIRectFill(CGRectMake(cx + radius, cy - toothW / 2, toothLen, toothW));
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return img;
}

- (UIViewController *)makePlaceholderDetailViewController {
    BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];
    UIViewController *vc = [[UIViewController alloc] init];
    vc.view.backgroundColor = [UIColor colorWithWhite:0.95 alpha:1.0];
    UILabel *lbl = [[UILabel alloc] initWithFrame:vc.view.bounds];
    lbl.text = isEn ? @"Select a chat" : @"Выберите чат";
    lbl.textAlignment = NSTextAlignmentCenter;
    lbl.textColor = [UIColor grayColor];
    lbl.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [vc.view addSubview:lbl];
    return vc;
}

- (void)configureDetailViewController:(UIViewController *)vc {
    if (self.masterPopoverController) {
        vc.navigationItem.leftBarButtonItem = self.masterButtonItem;
        [self.masterPopoverController dismissPopoverAnimated:YES];
    }
}

- (void)splitViewController:(UISplitViewController *)svc willHideViewController:(UIViewController *)aViewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)pc {
    BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];
    barButtonItem.title = isEn ? @"Chats" : @"Чаты";
    self.masterButtonItem = barButtonItem;
    self.masterPopoverController = pc;
    UINavigationController *detailNav = svc.viewControllers.lastObject;
    detailNav.topViewController.navigationItem.leftBarButtonItem = barButtonItem;
}

- (void)splitViewController:(UISplitViewController *)svc willShowViewController:(UIViewController *)aViewController invalidatingBarButtonItem:(UIBarButtonItem *)button {
    UINavigationController *detailNav = svc.viewControllers.lastObject;
    detailNav.topViewController.navigationItem.leftBarButtonItem = nil;
    self.masterPopoverController = nil;
    self.masterButtonItem = nil;
}
@end
