// Uofist | https://t.me/iOS6Great
#import "ChatListViewController.h"
#import "ChatViewController.h"
#import "SettingsViewController.h"
#import "ChatManager.h"
#import "G6BackgroundView.h"
#import "AppDelegate.h"
#import <QuartzCore/QuartzCore.h>

static NSString * const kChatListCellId = @"ChatListCell";

@interface ChatListCell : UITableViewCell
@property (nonatomic, strong) UIView   *cardView;
@property (nonatomic, strong) UIView   *dividerView;
@property (nonatomic, strong) UIView   *avatarView;
@property (nonatomic, strong) UIImageView *customAvatarView;
@property (nonatomic, strong) UILabel  *avatarLabel;
@property (nonatomic, strong) UILabel  *titleLabel;
@property (nonatomic, strong) UILabel  *previewLabel;
@end

@implementation ChatListCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)id {
    if (self = [super initWithStyle:style reuseIdentifier:id]) {
        self.backgroundColor = [UIColor clearColor];
        self.accessoryType   = UITableViewCellAccessoryDisclosureIndicator;

        _cardView = [[UIView alloc] init];
        [self.contentView addSubview:_cardView];

        _dividerView = [[UIView alloc] init];
        [self.contentView addSubview:_dividerView];

        _avatarView = [[UIView alloc] initWithFrame:CGRectMake(12, 10, 46, 46)];
        _avatarView.layer.cornerRadius  = 23;
        _avatarView.layer.masksToBounds = YES;
        _avatarView.layer.borderWidth   = 1.5;
        _avatarView.layer.borderColor   = [UIColor colorWithWhite:1 alpha:0.3].CGColor;
        [self.contentView addSubview:_avatarView];
        
        _avatarLabel = [[UILabel alloc] initWithFrame:_avatarView.bounds];
        _avatarLabel.textAlignment  = NSTextAlignmentCenter;
        _avatarLabel.font           = [UIFont boldSystemFontOfSize:20];
        _avatarLabel.textColor      = [UIColor whiteColor];
        _avatarLabel.shadowColor    = [UIColor colorWithWhite:0 alpha:0.4];
        _avatarLabel.shadowOffset   = CGSizeMake(0, 1);
        _avatarLabel.backgroundColor = [UIColor clearColor];
        [_avatarView addSubview:_avatarLabel];
        
        _customAvatarView = [[UIImageView alloc] initWithFrame:_avatarView.bounds];
        _customAvatarView.contentMode = UIViewContentModeScaleAspectFill;
        [_avatarView addSubview:_customAvatarView];
        
        _titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 12, 200, 22)];
        _titleLabel.font           = [UIFont boldSystemFontOfSize:16];
        _titleLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_titleLabel];
        
        _previewLabel = [[UILabel alloc] initWithFrame:CGRectMake(68, 36, 200, 18)];
        _previewLabel.font           = [UIFont systemFontOfSize:12];
        _previewLabel.backgroundColor = [UIColor clearColor];
        [self.contentView addSubview:_previewLabel];
    }
    return self;
}

- (void)configureWithSession:(ChatSession *)session isDark:(BOOL)isDark screenWidth:(CGFloat)sw isFirstRow:(BOOL)isFirst isLastRow:(BOOL)isLast {
    BOOL showAvatars = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowAvatars"];
    BOOL blockStyle = [[NSUserDefaults standardUserDefaults] integerForKey:@"ChatListStyle"] == 1;
    CGFloat margin = blockStyle ? 10.0 : 0.0;
    CGFloat rowH = 66.0;
    _avatarView.hidden = !showAvatars;
    _avatarView.frame = CGRectMake(margin + 12, 10, 46, 46);
    _avatarView.layer.cornerRadius = blockStyle ? 8 : 23;

    if (showAvatars && session.avatarData) {
        _customAvatarView.image = [UIImage imageWithData:session.avatarData];
        _customAvatarView.hidden = NO;
        _avatarLabel.hidden = YES;
    } else if (showAvatars) {
        _customAvatarView.hidden = YES;
        _avatarLabel.hidden = NO;
        NSUInteger hash = 0;
        for (NSUInteger i = 0; i < session.title.length; i++) {
            hash = hash * 31 + [session.title characterAtIndex:i];
        }
        NSArray *avatarColors = @[
            @[@0.2f, @0.55f, @0.9f],
            @[@0.25f, @0.78f, @0.45f],
            @[@0.9f, @0.45f, @0.2f],
            @[@0.65f, @0.25f, @0.88f],
            @[@0.88f, @0.22f, @0.35f],
            @[@0.15f, @0.65f, @0.75f],
        ];
        NSArray *ac = avatarColors[hash % avatarColors.count];
        UIColor *avatarTop = [UIColor colorWithRed:[ac[0] floatValue] green:[ac[1] floatValue] blue:[ac[2] floatValue] alpha:1.0];
        UIColor *avatarBot = [UIColor colorWithRed:[ac[0] floatValue] * 0.6f green:[ac[1] floatValue] * 0.6f blue:[ac[2] floatValue] * 0.6f alpha:1.0];
        
        for (CALayer *layer in [_avatarView.layer.sublayers copy]) {
            if ([layer isKindOfClass:[CAGradientLayer class]]) {
                [layer removeFromSuperlayer];
            }
        }
        CAGradientLayer *gl = [CAGradientLayer layer];
        gl.frame  = _avatarView.bounds;
        gl.colors = @[(id)avatarTop.CGColor, (id)avatarBot.CGColor];
        [_avatarView.layer insertSublayer:gl atIndex:0];
        
        NSString *letter = session.title.length ? [session.title substringToIndex:1] : @"G";
        _avatarLabel.text = [letter uppercaseString];
        [_avatarView bringSubviewToFront:_avatarLabel];
    }
    
    UIColor *titleColor   = isDark ? [UIColor whiteColor] : [UIColor colorWithWhite:0.1 alpha:1.0];
    UIColor *previewColor = isDark ? [UIColor colorWithWhite:0.65 alpha:1.0] : [UIColor colorWithWhite:0.45 alpha:1.0];
    
    _titleLabel.textColor   = titleColor;
    _previewLabel.textColor = previewColor;
    _titleLabel.text        = session.title;
    
    ChatMessage *last = session.messages.lastObject;
    BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];
    NSString *preview = last ? last.text : (isEn ? @"No messages" : @"Нет сообщений");
    if (last.mediaData) {
        preview = [last.mediaType hasPrefix:@"image"] ? (isEn ? @"[Photo]" : @"[Фотография]") : (isEn ? @"[Voice message]" : @"[Голосовое сообщение]");
    } else {
        preview = [preview stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
        if (preview.length > 60) {
            preview = [[preview substringToIndex:60] stringByAppendingString:@"…"];
        }
    }
    _previewLabel.text = preview;

    CGFloat contentX = margin + (showAvatars ? 68 : 16);
    CGFloat labelW = sw - contentX - 44 - margin;
    _titleLabel.frame   = CGRectMake(contentX, 12, labelW, 22);
    _previewLabel.frame = CGRectMake(contentX, 36, labelW, 18);

    if (blockStyle) {
        self.selectionStyle = UITableViewCellSelectionStyleNone;
        self.accessoryType = UITableViewCellAccessoryNone;
        self.backgroundView = nil;
        self.selectedBackgroundView = nil;

        CGFloat radius = 6.0;
        _cardView.hidden = NO;
        _cardView.backgroundColor = isDark ? [UIColor colorWithWhite:0.18 alpha:1.0] : [UIColor whiteColor];
        _cardView.frame = CGRectMake(margin, 0, sw - margin * 2, rowH);
        _cardView.layer.shadowColor = [UIColor blackColor].CGColor;
        _cardView.layer.shadowOffset = CGSizeMake(0, 1.5);
        _cardView.layer.shadowOpacity = isDark ? 0.5 : 0.18;
        _cardView.layer.shadowRadius = 3.0;
        _cardView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:_cardView.bounds cornerRadius:radius].CGPath;

        for (CALayer *layer in [_cardView.layer.sublayers copy]) {
            [layer removeFromSuperlayer];
        }

        UIRectCorner corners = 0;
        if (isFirst) corners |= UIRectCornerTopLeft | UIRectCornerTopRight;
        if (isLast)  corners |= UIRectCornerBottomLeft | UIRectCornerBottomRight;
        if (corners == 0) {
            _cardView.layer.mask = nil;
        } else {
            UIBezierPath *maskPath = [UIBezierPath bezierPathWithRoundedRect:_cardView.bounds byRoundingCorners:corners cornerRadii:CGSizeMake(radius, radius)];
            CAShapeLayer *maskLayer = [CAShapeLayer layer];
            maskLayer.path = maskPath.CGPath;
            _cardView.layer.mask = maskLayer;
        }

        CAGradientLayer *gloss = [CAGradientLayer layer];
        gloss.frame = _cardView.bounds;
        gloss.colors = isDark
            ? @[(id)[UIColor colorWithWhite:1.0 alpha:0.07].CGColor, (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor]
            : @[(id)[UIColor colorWithWhite:1.0 alpha:0.7].CGColor, (id)[UIColor colorWithWhite:1.0 alpha:0.0].CGColor];
        gloss.locations = @[@0.0, @0.4];
        [_cardView.layer addSublayer:gloss];

        CGFloat cw = _cardView.bounds.size.width;
        CGFloat cvSize = 14;
        CGRect chevronRect = CGRectMake(cw - 14 - cvSize, (rowH - cvSize) / 2.0, cvSize, cvSize);
        UIBezierPath *chevronPath = [UIBezierPath bezierPath];
        [chevronPath moveToPoint:CGPointMake(chevronRect.origin.x + chevronRect.size.width * 0.30, chevronRect.origin.y + chevronRect.size.height * 0.12)];
        [chevronPath addLineToPoint:CGPointMake(chevronRect.origin.x + chevronRect.size.width * 0.75, chevronRect.origin.y + chevronRect.size.height * 0.5)];
        [chevronPath addLineToPoint:CGPointMake(chevronRect.origin.x + chevronRect.size.width * 0.30, chevronRect.origin.y + chevronRect.size.height * 0.88)];
        CAShapeLayer *chevron = [CAShapeLayer layer];
        chevron.path = chevronPath.CGPath;
        chevron.strokeColor = (isDark ? [UIColor colorWithWhite:0.55 alpha:1.0] : [UIColor colorWithWhite:0.65 alpha:1.0]).CGColor;
        chevron.fillColor = [UIColor clearColor].CGColor;
        chevron.lineWidth = 2.0;
        chevron.lineCap = kCALineCapRound;
        chevron.lineJoin = kCALineJoinRound;
        [_cardView.layer addSublayer:chevron];

        _dividerView.hidden = isLast;
        _dividerView.backgroundColor = isDark ? [UIColor colorWithWhite:0.3 alpha:1.0] : [UIColor colorWithWhite:0.85 alpha:1.0];
        _dividerView.frame = CGRectMake(margin, rowH - 1, sw - margin * 2, 1);
    } else {
        self.selectionStyle = UITableViewCellSelectionStyleDefault;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        _cardView.hidden = YES;
        _cardView.layer.shadowOpacity = 0;
        _dividerView.hidden = YES;

        UIView *bgView = [[UIView alloc] init];
        bgView.backgroundColor = isDark ? [UIColor colorWithWhite:0.16 alpha:0.9] : [UIColor colorWithWhite:1.0 alpha:0.75];
        self.backgroundView = bgView;

        UIView *selView = [[UIView alloc] init];
        selView.backgroundColor = isDark ? [UIColor colorWithWhite:0.25 alpha:1.0] : [UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:0.15];
        self.selectedBackgroundView = selView;
    }
}
@end

@interface ChatListViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIActionSheetDelegate>
@property (nonatomic, strong) ChatSession *sessionToEdit;
@property (nonatomic, strong) UIPopoverController *popover;
@end

@implementation ChatListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = @"G6mini";
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithBarButtonSystemItem:UIBarButtonSystemItemCompose
        target:self action:@selector(addChat)];
    self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    BOOL usesTabBar = !isPad && ([[NSUserDefaults standardUserDefaults] integerForKey:@"NavStyle"] != 1);
    if (!usesTabBar) {
        UIBarButtonItem *flexLeft = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *flexRight = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
        UIBarButtonItem *settingsBtn = [[UIBarButtonItem alloc] initWithTitle:@"⚙ Настройки" style:UIBarButtonItemStyleBordered target:self action:@selector(openSettings)];
        self.toolbarItems = @[flexLeft, settingsBtn, flexRight];
    }
    
    self.tableView.rowHeight = 66;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    [self.tableView registerClass:[ChatListCell class] forCellReuseIdentifier:kChatListCellId];
    
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(handleRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    [self.tableView addGestureRecognizer:lp];
}

- (void)handleRefresh {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        [self.refreshControl endRefreshing];
    });
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state == UIGestureRecognizerStateBegan) {
        CGPoint p = [gesture locationInView:self.tableView];
        NSIndexPath *ip = [self.tableView indexPathForRowAtPoint:p];
        if (ip) {
            self.sessionToEdit = [ChatManager sharedManager].sessions[ip.row];
            NSString *pinTitle = self.sessionToEdit.pinned ? @"Открепить" : @"Закрепить наверху";
            UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:self.sessionToEdit.title delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil otherButtonTitles:@"Изменить аватарку чата", pinTitle, nil];
            if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
                UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
                [sheet showFromRect:cell.bounds inView:cell animated:YES];
            } else {
                [sheet showInView:self.view];
            }
        }
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0 && self.sessionToEdit) {
        UIImagePickerController *picker = [[UIImagePickerController alloc] init];
        picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        picker.delegate = self;
        picker.allowsEditing = YES;
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
            
            [self.popover presentPopoverFromRect:CGRectMake(self.view.bounds.size.width/2, self.view.bounds.size.height/2, 1, 1) inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            [self presentViewController:picker animated:YES completion:nil];
        }
    } else if (buttonIndex == 1 && self.sessionToEdit) {
        [[ChatManager sharedManager] togglePinForSession:self.sessionToEdit];
        self.sessionToEdit = nil;
        [self.tableView reloadData];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *img = info[UIImagePickerControllerEditedImage] ?: info[UIImagePickerControllerOriginalImage];
    if (self.sessionToEdit && img) {
        self.sessionToEdit.avatarData = UIImageJPEGRepresentation(img, 0.7);
        [[ChatManager sharedManager] save];
        [self.tableView reloadData];
    }
    self.sessionToEdit = nil;
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    self.sessionToEdit = nil;
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    BOOL usesTabBar = !isPad && ([[NSUserDefaults standardUserDefaults] integerForKey:@"NavStyle"] != 1);
    self.navigationController.toolbarHidden = usesTabBar;
    [self applyTheme];
    [self.tableView reloadData];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    self.navigationController.toolbarHidden = YES;
}

- (void)applyTheme {
    BOOL isDark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    if (isDark) {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.navigationController.toolbar.tintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.navigationController.navigationBar.titleTextAttributes = @{
            UITextAttributeTextColor: [UIColor whiteColor]
        };
    } else {
        self.navigationController.navigationBar.tintColor = nil;
        self.navigationController.toolbar.tintColor = nil;
    }
    
    G6BackgroundView *bg = [[G6BackgroundView alloc] initWithFrame:self.tableView.bounds];
    self.tableView.backgroundView = bg;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
}

- (void)addChat {
    ChatSession *sess = [[ChatSession alloc] init];
    [[ChatManager sharedManager] addSession:sess];
    [self presentChatViewController:[[ChatViewController alloc] initWithSession:sess]];
}

- (void)presentChatViewController:(ChatViewController *)vc {
    AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    if (appDelegate.splitViewController) {
        UINavigationController *detailNav = [[UINavigationController alloc] initWithRootViewController:vc];
        appDelegate.splitViewController.viewControllers = @[appDelegate.splitViewController.viewControllers[0], detailNav];
        [appDelegate configureDetailViewController:vc];
    } else {
        [self.navigationController pushViewController:vc animated:YES];
    }
}

- (void)openSettings {
    [self.navigationController pushViewController:[[SettingsViewController alloc] init] animated:YES];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return [ChatManager sharedManager].sessions.count;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    return 66;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    ChatListCell *cell = [tv dequeueReusableCellWithIdentifier:kChatListCellId forIndexPath:ip];
    ChatSession *sess  = [ChatManager sharedManager].sessions[ip.row];
    BOOL isDark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    NSInteger total = [ChatManager sharedManager].sessions.count;
    [cell configureWithSession:sess isDark:isDark screenWidth:tv.bounds.size.width isFirstRow:(ip.row == 0) isLastRow:(ip.row == total - 1)];
    return cell;
}

- (BOOL)tableView:(UITableView *)tv canEditRowAtIndexPath:(NSIndexPath *)ip {
    return YES;
}

- (void)tableView:(UITableView *)tv commitEditingStyle:(UITableViewCellEditingStyle)style forRowAtIndexPath:(NSIndexPath *)ip {
    if (style == UITableViewCellEditingStyleDelete) {
        [[ChatManager sharedManager] removeSessionAtIndex:ip.row];
        [tv deleteRowsAtIndexPaths:@[ip] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)tableView:(UITableView *)tv didSelectRowAtIndexPath:(NSIndexPath *)ip {
    [tv deselectRowAtIndexPath:ip animated:YES];
    ChatSession *sess = [ChatManager sharedManager].sessions[ip.row];
    [self presentChatViewController:[[ChatViewController alloc] initWithSession:sess]];
}

- (CGFloat)tableView:(UITableView *)tv heightForHeaderInSection:(NSInteger)section {
    return 8;
}

- (UIView *)tableView:(UITableView *)tv viewForHeaderInSection:(NSInteger)section {
    UIView *v = [[UIView alloc] init];
    v.backgroundColor = [UIColor clearColor];
    return v;
}
@end
