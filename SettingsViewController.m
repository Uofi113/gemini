// Uofist | https://t.me/iOS6Great
#import "SettingsViewController.h"
#import "G6BackgroundView.h"
#import "AppDelegate.h"

@interface SettingsViewController ()
@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextField *apiKeyField;
@property (nonatomic, strong) UISegmentedControl *modelControl;
@property (nonatomic, strong) UISwitch *themeSwitch;
@property (nonatomic, strong) UISegmentedControl *langControl;
@property (nonatomic, strong) UISegmentedControl *navStyleControl;
@property (nonatomic, strong) UISwitch *avatarSwitch;
@property (nonatomic, strong) UISegmentedControl *listStyleControl;
@property (nonatomic, strong) UISegmentedControl *fontSizeControl;
@property (nonatomic, strong) UIButton *presetButton;
@property (nonatomic, strong) UIButton *deletePresetButton;
@property (nonatomic, strong) UITextView *personalContextView;
@property (nonatomic, strong) NSMutableArray *contextPresets;
@property (nonatomic, copy) NSString *activePresetName;
@end

@implementation SettingsViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    BOOL isDark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    if (isDark) {
        self.navigationController.navigationBar.tintColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        self.navigationController.navigationBar.titleTextAttributes = @{ UITextAttributeTextColor: [UIColor whiteColor] };
    } else {
        self.navigationController.navigationBar.tintColor = nil;
        self.navigationController.navigationBar.titleTextAttributes = nil;
    }
}

- (CGFloat)addSectionHeader:(NSString *)text x:(CGFloat)x width:(CGFloat)w y:(CGFloat)y isDark:(BOOL)isDark {
    UILabel *header = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 16)];
    header.text = text;
    header.font = [UIFont boldSystemFontOfSize:12];
    header.textColor = isDark ? [UIColor colorWithWhite:0.55 alpha:1.0] : [UIColor colorWithWhite:0.4 alpha:1.0];
    header.backgroundColor = [UIColor clearColor];
    header.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:header];

    UIView *divider = [[UIView alloc] initWithFrame:CGRectMake(x, y + 20, w, 1)];
    divider.backgroundColor = isDark ? [UIColor colorWithWhite:1.0 alpha:0.15] : [UIColor colorWithWhite:0.0 alpha:0.12];
    divider.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:divider];

    return y + 32;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    NSString *lang = [[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] ?: @"ru";
    BOOL isEn = [lang isEqualToString:@"en"];

    self.title = isEn ? @"Settings" : @"Настройки";

    BOOL isDark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    G6BackgroundView *bg = [[G6BackgroundView alloc] initWithFrame:self.view.bounds];
    [self.view insertSubview:bg atIndex:0];

    self.scrollView = [[UIScrollView alloc] initWithFrame:self.view.bounds];
    self.scrollView.backgroundColor = [UIColor clearColor];
    self.scrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.scrollView];

    BOOL isPad = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGFloat w = isPad ? 400 : self.view.bounds.size.width - 40;
    CGFloat x = (self.view.bounds.size.width - w) / 2.0;
    CGFloat gap = 10;
    CGFloat y = 16;

    y = [self addSectionHeader:(isEn ? @"API & MODEL" : @"API И МОДЕЛЬ") x:x width:w y:y isDark:isDark];

    UILabel *apiLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 22)];
    apiLabel.text = @"API Key:";
    apiLabel.backgroundColor = [UIColor clearColor];
    apiLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    apiLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:apiLabel];
    y += 22 + 4;

    self.apiKeyField = [[UITextField alloc] initWithFrame:CGRectMake(x, y, w, 32)];
    self.apiKeyField.borderStyle = UITextBorderStyleRoundedRect;
    self.apiKeyField.text = [[NSUserDefaults standardUserDefaults] stringForKey:@"APIKey"];
    self.apiKeyField.autocorrectionType = UITextAutocorrectionTypeNo;
    self.apiKeyField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.apiKeyField.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.apiKeyField];
    y += 32 + 4;

    UIButton *getBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    getBtn.frame = CGRectMake(x, y, w, 22);
    [getBtn setTitle:(isEn ? @"Where to get API key?" : @"Где взять API ключ?") forState:UIControlStateNormal];
    [getBtn setTitleColor:[UIColor colorWithRed:0.0 green:0.47 blue:1.0 alpha:1.0] forState:UIControlStateNormal];
    getBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    getBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    getBtn.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [getBtn addTarget:self action:@selector(openApiKeyLink) forControlEvents:UIControlEventTouchUpInside];
    [self.scrollView addSubview:getBtn];
    y += 22 + gap;

    UILabel *modelLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 20)];
    modelLabel.text = isEn ? @"Model:" : @"Модель:";
    modelLabel.font = [UIFont systemFontOfSize:14];
    modelLabel.backgroundColor = [UIColor clearColor];
    modelLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    modelLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:modelLabel];
    y += 20 + 4;

    self.modelControl = [[UISegmentedControl alloc] initWithItems:@[@"Flash-Lite", @"Flash", @"Pro"]];
    self.modelControl.frame = CGRectMake(x, y, w, 38);
    self.modelControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.modelControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedModel"];
    self.modelControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.modelControl];
    y += 38 + gap * 2;

    y = [self addSectionHeader:(isEn ? @"DESIGN" : @"ДИЗАЙН") x:x width:w y:y isDark:isDark];

    UILabel *themeLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w - 90, 30)];
    themeLabel.text = isEn ? @"Dark Theme:" : @"Темная тема:";
    themeLabel.backgroundColor = [UIColor clearColor];
    themeLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    themeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:themeLabel];

    self.themeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(x + w - 80, y, 80, 30)];
    self.themeSwitch.on = isDark;
    self.themeSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.themeSwitch];
    y += 30 + gap;

    UILabel *navStyleLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 18)];
    navStyleLabel.text = isEn ? @"Navigation:" : @"Навигация:";
    navStyleLabel.font = [UIFont systemFontOfSize:14];
    navStyleLabel.backgroundColor = [UIColor clearColor];
    navStyleLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    navStyleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:navStyleLabel];
    y += 18 + 4;

    self.navStyleControl = [[UISegmentedControl alloc] initWithItems:@[isEn ? @"Tab bar" : @"Таб-бар", isEn ? @"Button" : @"Кнопка"]];
    self.navStyleControl.frame = CGRectMake(x, y, w, 34);
    self.navStyleControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.navStyleControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"NavStyle"];
    self.navStyleControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.navStyleControl];
    y += 34 + gap;

    UILabel *avatarLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w - 90, 30)];
    avatarLabel.text = isEn ? @"Show chat avatars:" : @"Показывать аватарки:";
    avatarLabel.backgroundColor = [UIColor clearColor];
    avatarLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    avatarLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:avatarLabel];

    self.avatarSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(x + w - 80, y, 80, 30)];
    self.avatarSwitch.on = [[NSUserDefaults standardUserDefaults] boolForKey:@"ShowAvatars"];
    self.avatarSwitch.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.avatarSwitch];
    y += 30 + gap;

    UILabel *listStyleLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 18)];
    listStyleLabel.text = isEn ? @"Chat list style:" : @"Стиль списка чатов:";
    listStyleLabel.font = [UIFont systemFontOfSize:14];
    listStyleLabel.backgroundColor = [UIColor clearColor];
    listStyleLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    listStyleLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:listStyleLabel];
    y += 18 + 4;

    self.listStyleControl = [[UISegmentedControl alloc] initWithItems:@[isEn ? @"Classic" : @"Классический", isEn ? @"Blocks" : @"Блоки"]];
    self.listStyleControl.frame = CGRectMake(x, y, w, 34);
    self.listStyleControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.listStyleControl.selectedSegmentIndex = [[NSUserDefaults standardUserDefaults] integerForKey:@"ChatListStyle"];
    self.listStyleControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.listStyleControl];
    y += 34 + gap;

    UILabel *fontSizeLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 18)];
    fontSizeLabel.text = isEn ? @"Text size:" : @"Размер текста:";
    fontSizeLabel.font = [UIFont systemFontOfSize:14];
    fontSizeLabel.backgroundColor = [UIColor clearColor];
    fontSizeLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    fontSizeLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:fontSizeLabel];
    y += 18 + 4;

    NSInteger storedFontSize = [[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    NSInteger fontSizeIdx = 1;
    if (storedFontSize == 13) fontSizeIdx = 0;
    else if (storedFontSize == 18) fontSizeIdx = 2;
    self.fontSizeControl = [[UISegmentedControl alloc] initWithItems:@[(isEn ? @"Small" : @"Мелкий"), (isEn ? @"Normal" : @"Обычный"), (isEn ? @"Large" : @"Крупный")]];
    self.fontSizeControl.frame = CGRectMake(x, y, w, 34);
    self.fontSizeControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.fontSizeControl.selectedSegmentIndex = fontSizeIdx;
    self.fontSizeControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.fontSizeControl];
    y += 34 + gap * 2;

    y = [self addSectionHeader:(isEn ? @"CONVERSATION" : @"ДИАЛОГ") x:x width:w y:y isDark:isDark];

    UILabel *langLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w - 130, 30)];
    langLabel.text = isEn ? @"Language:" : @"Язык (Language):";
    langLabel.backgroundColor = [UIColor clearColor];
    langLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    langLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:langLabel];

    self.langControl = [[UISegmentedControl alloc] initWithItems:@[@"RU", @"EN"]];
    self.langControl.frame = CGRectMake(x + w - 120, y - 3, 120, 36);
    self.langControl.segmentedControlStyle = UISegmentedControlStyleBar;
    self.langControl.selectedSegmentIndex = isEn ? 1 : 0;
    self.langControl.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.langControl];
    y += 33 + gap;

    UILabel *personalLabel = [[UILabel alloc] initWithFrame:CGRectMake(x, y, w, 18)];
    personalLabel.text = isEn ? @"Personal context — preset:" : @"Личный контекст — пресет:";
    personalLabel.font = [UIFont systemFontOfSize:13];
    personalLabel.backgroundColor = [UIColor clearColor];
    personalLabel.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    personalLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:personalLabel];
    y += 18 + 6;

    [self loadContextPresets];

    self.presetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.presetButton.frame = CGRectMake(x, y, w - 44, 32);
    [self.presetButton setTitle:self.activePresetName forState:UIControlStateNormal];
    self.presetButton.titleLabel.font = [UIFont systemFontOfSize:14];
    [self.presetButton addTarget:self action:@selector(showPresetMenu) forControlEvents:UIControlEventTouchUpInside];
    self.presetButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [self.scrollView addSubview:self.presetButton];

    self.deletePresetButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    self.deletePresetButton.frame = CGRectMake(x + w - 36, y, 36, 32);
    [self.deletePresetButton setTitle:@"✕" forState:UIControlStateNormal];
    [self.deletePresetButton addTarget:self action:@selector(deleteActivePreset) forControlEvents:UIControlEventTouchUpInside];
    self.deletePresetButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;
    [self.scrollView addSubview:self.deletePresetButton];
    y += 32 + 6;

    self.personalContextView = [[UITextView alloc] initWithFrame:CGRectMake(x, y, w, 70)];
    self.personalContextView.font = [UIFont systemFontOfSize:14];
    self.personalContextView.text = [self textForActivePreset];
    self.personalContextView.backgroundColor = isDark ? [UIColor colorWithWhite:0.15 alpha:1.0] : [UIColor whiteColor];
    self.personalContextView.textColor = isDark ? [UIColor whiteColor] : [UIColor blackColor];
    self.personalContextView.layer.borderColor = [UIColor colorWithWhite:0.6 alpha:1.0].CGColor;
    self.personalContextView.layer.borderWidth = 1.0;
    self.personalContextView.layer.cornerRadius = 6.0;
    self.personalContextView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;

    UIToolbar *doneBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
    UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem *doneBtn = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(dismissPersonalContextKeyboard)];
    doneBar.items = @[flex, doneBtn];
    self.personalContextView.inputAccessoryView = doneBar;

    [self.scrollView addSubview:self.personalContextView];
    y += 70 + gap * 2;

    UILabel *footer = [[UILabel alloc] initWithFrame:CGRectMake(0, y, self.view.bounds.size.width, 30)];
    footer.text = isEn ? @"Developed by Uofist" : @"Разработано Uofist";
    footer.font = [UIFont systemFontOfSize:12];
    footer.textColor = [UIColor grayColor];
    footer.textAlignment = NSTextAlignmentCenter;
    footer.backgroundColor = [UIColor clearColor];
    footer.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.scrollView addSubview:footer];
    y += 30 + gap;

    self.scrollView.contentSize = CGSizeMake(self.view.bounds.size.width, MAX(y, self.view.bounds.size.height));

    NSString *btnTitle = isEn ? @"Save" : @"Сохранить";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:btnTitle style:UIBarButtonItemStyleDone target:self action:@selector(saveSettings)];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)dismissPersonalContextKeyboard {
    [self.personalContextView resignFirstResponder];
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGRect kbFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    UIEdgeInsets insets = UIEdgeInsetsMake(0, 0, kbFrame.size.height, 0);
    self.scrollView.contentInset = insets;
    self.scrollView.scrollIndicatorInsets = insets;
}

- (void)keyboardWillHide:(NSNotification *)note {
    self.scrollView.contentInset = UIEdgeInsetsZero;
    self.scrollView.scrollIndicatorInsets = UIEdgeInsetsZero;
}

- (void)openApiKeyLink {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"API Key" message:@"Для работы приложения нужен API ключ Google Gemini. Получите его бесплатно на сайте: aistudio.google.com/app/apikey (откройте с компьютера или смартфона)." delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
    [alert show];
}

- (void)loadContextPresets {
    NSArray *stored = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ContextPresets"];
    NSMutableArray *presets = [NSMutableArray array];
    for (NSDictionary *p in stored) {
        [presets addObject:[p mutableCopy]];
    }
    self.contextPresets = presets;

    if (self.contextPresets.count == 0) {
        BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];
        NSString *legacy = [[NSUserDefaults standardUserDefaults] stringForKey:@"PersonalContext"] ?: @"";
        [self.contextPresets addObject:[@{@"name": (isEn ? @"Default" : @"По умолчанию"), @"text": legacy} mutableCopy]];
    }

    self.activePresetName = [[NSUserDefaults standardUserDefaults] stringForKey:@"ActiveContextPreset"];
    BOOL found = NO;
    for (NSDictionary *p in self.contextPresets) {
        if ([p[@"name"] isEqualToString:self.activePresetName]) { found = YES; break; }
    }
    if (!found) self.activePresetName = self.contextPresets.firstObject[@"name"];
}

- (NSString *)textForActivePreset {
    for (NSDictionary *p in self.contextPresets) {
        if ([p[@"name"] isEqualToString:self.activePresetName]) return p[@"text"] ?: @"";
    }
    return @"";
}

- (void)persistCurrentPresetText {
    for (NSInteger i = 0; i < (NSInteger)self.contextPresets.count; i++) {
        NSMutableDictionary *p = self.contextPresets[i];
        if ([p[@"name"] isEqualToString:self.activePresetName]) {
            p[@"text"] = self.personalContextView.text ?: @"";
            break;
        }
    }
}

- (void)showPresetMenu {
    [self persistCurrentPresetText];
    BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];

    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    for (NSDictionary *p in self.contextPresets) {
        [sheet addButtonWithTitle:p[@"name"]];
    }
    [sheet addButtonWithTitle:(isEn ? @"+ New preset" : @"+ Новый пресет")];
    sheet.cancelButtonIndex = [sheet addButtonWithTitle:(isEn ? @"Cancel" : @"Отмена")];

    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [sheet showFromRect:self.presetButton.bounds inView:self.presetButton animated:YES];
    } else {
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == actionSheet.cancelButtonIndex) return;
    BOOL isEn = [[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"];

    if (buttonIndex == (NSInteger)self.contextPresets.count) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:(isEn ? @"New preset" : @"Новый пресет") message:nil delegate:self cancelButtonTitle:(isEn ? @"Cancel" : @"Отмена") otherButtonTitles:(isEn ? @"Create" : @"Создать"), nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        alert.tag = 202;
        [alert show];
        return;
    }

    NSDictionary *chosen = self.contextPresets[buttonIndex];
    self.activePresetName = chosen[@"name"];
    [self.presetButton setTitle:self.activePresetName forState:UIControlStateNormal];
    self.personalContextView.text = chosen[@"text"] ?: @"";
}

- (void)deleteActivePreset {
    if (self.contextPresets.count <= 1) return;
    NSMutableArray *updated = [NSMutableArray array];
    for (NSDictionary *p in self.contextPresets) {
        if (![p[@"name"] isEqualToString:self.activePresetName]) [updated addObject:p];
    }
    self.contextPresets = updated;
    self.activePresetName = self.contextPresets.firstObject[@"name"];
    [self.presetButton setTitle:self.activePresetName forState:UIControlStateNormal];
    self.personalContextView.text = [self textForActivePreset];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 202 && buttonIndex == 1) {
        NSString *name = [[alertView textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (name.length == 0) return;
        for (NSDictionary *p in self.contextPresets) {
            if ([p[@"name"] isEqualToString:name]) return;
        }
        [self.contextPresets addObject:[@{@"name": name, @"text": @""} mutableCopy]];
        self.activePresetName = name;
        [self.presetButton setTitle:name forState:UIControlStateNormal];
        self.personalContextView.text = @"";
    }
}

- (void)saveSettings {
    [self.view endEditing:YES];
    [self persistCurrentPresetText];

    NSArray *sizes = @[@13, @15, @18];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSInteger oldNavStyle = [defaults integerForKey:@"NavStyle"];
    NSInteger newNavStyle = self.navStyleControl.selectedSegmentIndex;

    [defaults setObject:self.apiKeyField.text ?: @"" forKey:@"APIKey"];
    [defaults setInteger:self.modelControl.selectedSegmentIndex forKey:@"SelectedModel"];
    [defaults setBool:self.themeSwitch.isOn forKey:@"DarkTheme"];
    [defaults setObject:(self.langControl.selectedSegmentIndex == 1 ? @"en" : @"ru") forKey:@"AppLang"];
    [defaults setInteger:newNavStyle forKey:@"NavStyle"];
    [defaults setBool:self.avatarSwitch.isOn forKey:@"ShowAvatars"];
    [defaults setInteger:self.listStyleControl.selectedSegmentIndex forKey:@"ChatListStyle"];
    [defaults setInteger:[sizes[self.fontSizeControl.selectedSegmentIndex] integerValue] forKey:@"FontSize"];
    [defaults setObject:self.contextPresets forKey:@"ContextPresets"];
    [defaults setObject:self.activePresetName ?: @"" forKey:@"ActiveContextPreset"];
    [defaults synchronize];

    BOOL isPad = ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad);
    if (!isPad && oldNavStyle != newNavStyle) {
        AppDelegate *appDelegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
        [appDelegate rebuildRootViewController];
        return;
    }

    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
    } else {
        [self viewWillAppear:NO];
        BOOL isEn = [self.langControl selectedSegmentIndex] == 1;
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:nil message:(isEn ? @"Settings saved" : @"Настройки сохранены") delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
        [alert show];
    }
}

- (void)dealloc {
    self.apiKeyField.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
