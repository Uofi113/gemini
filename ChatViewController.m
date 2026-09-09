// Uofist | https://t.me/iOS6Great
#import "ChatViewController.h"
#import "ChatBubbleCell.h"
#import "ChatMessageParser.h"
#import "G6BackgroundView.h"
#import <QuartzCore/QuartzCore.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>
#import <SystemConfiguration/SystemConfiguration.h>
#import <netinet/in.h>

static NSString * const kBubbleCellId = @"BubbleCell";
static const CGFloat kContextBarH = 16.0;
static const NSInteger kSoftTokenLimit = 32000;

@interface ChatViewController () <UITableViewDelegate, UITableViewDataSource,
                                   UITextFieldDelegate, ChatBubbleCellDelegate>
@property (nonatomic, strong) ChatSession    *session;
@property (nonatomic, strong) UITableView   *tableView;
@property (nonatomic, strong) UILabel       *contextLabel;
@property (nonatomic, strong) UIView        *inputContainer;
@property (nonatomic, strong) UITextField   *inputField;
@property (nonatomic, strong) UIButton      *sendButton;
@property (nonatomic, strong) UIButton      *attachButton;
@property (nonatomic, strong) UIButton      *micButton;

@property (nonatomic, strong) NSMutableDictionary *segmentCache;
@property (nonatomic, strong) NSMutableDictionary *heightCache;
@property (nonatomic, strong) NSMutableSet *expandedCodeBlocks;

@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, strong) ChatMessage *currentStreamingMessage;
@property (nonatomic, strong) AVAudioRecorder *audioRecorder;
@property (nonatomic, assign) BOOL isRecording;
@property (nonatomic, strong) UIPopoverController *popover;
@end

#define L(ru, en) ([[[NSUserDefaults standardUserDefaults] stringForKey:@"AppLang"] isEqualToString:@"en"] ? (en) : (ru))

@implementation ChatViewController

- (instancetype)initWithSession:(ChatSession *)session {
    if (self = [super init]) {
        self.session            = session;
        self.segmentCache       = [NSMutableDictionary dictionary];
        self.heightCache        = [NSMutableDictionary dictionary];
        self.expandedCodeBlocks = [NSMutableSet set];
    }
    return self;
}

- (NSArray *)segmentsForMessageAtIndex:(NSInteger)idx {
    NSNumber *key = @(idx);
    NSArray  *cached = self.segmentCache[key];
    if (cached) return cached;
    
    if (idx >= (NSInteger)self.session.messages.count) return @[];
    ChatMessage *msg = self.session.messages[idx];
    NSArray *segs;
    if (msg.isUser) {
        MessageSegment *seg = [MessageSegment new];
        seg.type    = MessageSegmentTypeText;
        seg.content = [msg.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        segs = @[seg];
    } else {
        segs = [ChatMessageParser parseMessage:msg.text];
    }
    self.segmentCache[key] = segs;
    return segs;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.title = self.session.title;
    
    BOOL isDark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    G6BackgroundView *bg = [[G6BackgroundView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:bg];
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, kContextBarH, self.view.bounds.size.width, self.view.bounds.size.height - 48 - kContextBarH) style:UITableViewStylePlain];
    self.tableView.delegate         = self;
    self.tableView.dataSource       = self;
    self.tableView.backgroundColor  = [UIColor clearColor];
    self.tableView.separatorStyle   = UITableViewCellSeparatorStyleNone;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.tableView registerClass:[ChatBubbleCell class] forCellReuseIdentifier:kBubbleCellId];
    [self.view addSubview:self.tableView];

    self.contextLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, kContextBarH)];
    self.contextLabel.font = [UIFont systemFontOfSize:10];
    self.contextLabel.textAlignment = NSTextAlignmentCenter;
    self.contextLabel.backgroundColor = isDark ? [UIColor colorWithWhite:1.0 alpha:0.06] : [UIColor colorWithWhite:0.0 alpha:0.04];
    self.contextLabel.textColor = [UIColor grayColor];
    self.contextLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.view addSubview:self.contextLabel];
    [self updateContextLabel];

    [self buildInputBar:isDark];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
        initWithTitle:@"Меню" style:UIBarButtonItemStyleBordered
        target:self action:@selector(showMenu)];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    
    [self setupAudioSession];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self scrollToBottom:NO];
}

- (void)buildInputBar:(BOOL)isDark {
    CGFloat sw = self.view.bounds.size.width;
    CGFloat sh = self.view.bounds.size.height;
    
    self.inputContainer = [[UIView alloc] initWithFrame:CGRectMake(0, sh - 48, sw, 48)];
    self.inputContainer.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
    
    CAGradientLayer *barGrad       = [CAGradientLayer layer];
    barGrad.frame = CGRectMake(0, 0, sw, 48);
    barGrad.colors = isDark
        ? @[(id)[UIColor colorWithWhite:0.18 alpha:1.0].CGColor, (id)[UIColor colorWithWhite:0.06 alpha:1.0].CGColor]
        : @[(id)[UIColor colorWithWhite:0.88 alpha:1.0].CGColor, (id)[UIColor colorWithWhite:0.70 alpha:1.0].CGColor];
    [self.inputContainer.layer addSublayer:barGrad];
    
    self.attachButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.attachButton.frame = CGRectMake(5, 9, 30, 30);
    [self.attachButton setTitle:@"📷" forState:UIControlStateNormal];
    [self.attachButton addTarget:self action:@selector(attachMedia) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainer addSubview:self.attachButton];

    self.micButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.micButton.frame = CGRectMake(35, 9, 30, 30);
    [self.micButton setTitle:@"🎤" forState:UIControlStateNormal];
    [self.micButton addTarget:self action:@selector(toggleRecord) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainer addSubview:self.micButton];
    
    self.inputField = [[UITextField alloc] initWithFrame:CGRectMake(70, 9, sw - 140, 30)];
    self.inputField.borderStyle         = UITextBorderStyleRoundedRect;
    self.inputField.delegate            = self;
    self.inputField.autoresizingMask    = UIViewAutoresizingFlexibleWidth;
    self.inputField.font                = [UIFont systemFontOfSize:14];
    self.inputField.returnKeyType       = UIReturnKeySend;
    [self.inputContainer addSubview:self.inputField];
    
    self.sendButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.sendButton.frame = CGRectMake(sw - 65, 9, 60, 30);
    self.sendButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin;

    CAGradientLayer *btnGrad = [CAGradientLayer layer];
    btnGrad.frame        = self.sendButton.bounds;
    btnGrad.colors       = @[(id)[UIColor colorWithRed:0.2 green:0.5 blue:0.9 alpha:1.0].CGColor,
                              (id)[UIColor colorWithRed:0.06 green:0.28 blue:0.7 alpha:1.0].CGColor];
    btnGrad.cornerRadius = 7;
    [self.sendButton.layer insertSublayer:btnGrad atIndex:0];
    self.sendButton.layer.cornerRadius  = 7;
    self.sendButton.layer.masksToBounds = YES;
    [self.sendButton setTitle:@"→" forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.sendButton.titleLabel.font = [UIFont boldSystemFontOfSize:20];

    [self.sendButton addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.inputContainer addSubview:self.sendButton];

    [self.view addSubview:self.inputContainer];

    for (UIButton *btn in @[self.attachButton, self.micButton, self.sendButton]) {
        [self addPressAnimationToButton:btn];
    }
}

- (void)addPressAnimationToButton:(UIButton *)btn {
    [btn addTarget:self action:@selector(buttonTouchDown:) forControlEvents:UIControlEventTouchDown];
    [btn addTarget:self action:@selector(buttonTouchUp:) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside | UIControlEventTouchCancel)];
}

- (void)buttonTouchDown:(UIButton *)sender {
    [UIView animateWithDuration:0.1 animations:^{
        sender.transform = CGAffineTransformMakeScale(0.88, 0.88);
    }];
}

- (void)buttonTouchUp:(UIButton *)sender {
    [UIView animateWithDuration:0.15 animations:^{
        sender.transform = CGAffineTransformIdentity;
    }];
}

- (BOOL)isNetworkReachable {
    struct sockaddr_in zeroAddress;
    bzero(&zeroAddress, sizeof(zeroAddress));
    zeroAddress.sin_len = sizeof(zeroAddress);
    zeroAddress.sin_family = AF_INET;

    SCNetworkReachabilityRef reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr *)&zeroAddress);
    if (!reachability) return YES;

    SCNetworkReachabilityFlags flags = 0;
    BOOL success = SCNetworkReachabilityGetFlags(reachability, &flags);
    CFRelease(reachability);
    if (!success) return YES;

    BOOL isReachable = (flags & kSCNetworkReachabilityFlagsReachable) != 0;
    BOOL needsConnection = (flags & kSCNetworkReachabilityFlagsConnectionRequired) != 0;
    return isReachable && !needsConnection;
}

- (void)keyboardWillShow:(NSNotification *)note {
    CGRect kbFrame = [note.userInfo[UIKeyboardFrameEndUserInfoKey] CGRectValue];
    NSTimeInterval dur = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[note.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:dur delay:0 options:(curve << 16) animations:^{
        CGFloat avail = self.view.bounds.size.height - kbFrame.size.height;
        self.tableView.frame        = CGRectMake(0, kContextBarH, self.view.bounds.size.width, avail - 48 - kContextBarH);
        self.inputContainer.frame   = CGRectMake(0, avail - 48, self.view.bounds.size.width, 48);
    } completion:nil];
    [self scrollToBottom:YES];
}

- (void)keyboardWillHide:(NSNotification *)note {
    NSTimeInterval dur = [note.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    UIViewAnimationCurve curve = (UIViewAnimationCurve)[note.userInfo[UIKeyboardAnimationCurveUserInfoKey] integerValue];
    [UIView animateWithDuration:dur delay:0 options:(curve << 16) animations:^{
        CGFloat sh = self.view.bounds.size.height;
        self.tableView.frame        = CGRectMake(0, kContextBarH, self.view.bounds.size.width, sh - 48 - kContextBarH);
        self.inputContainer.frame   = CGRectMake(0, sh - 48, self.view.bounds.size.width, 48);
    } completion:nil];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf {
    [self sendMessage];
    return YES;
}

- (void)showMenu {
    if (self.popover && self.popover.isPopoverVisible) {
        [self.popover dismissPopoverAnimated:YES];
        return;
    }
    UIActionSheet *sheet = [[UIActionSheet alloc] initWithTitle:@"Меню чата"
        delegate:self cancelButtonTitle:@"Отмена" destructiveButtonTitle:nil
        otherButtonTitles:@"Изменить имя", @"Поделиться диалогом", @"Перегенерировать ответ", nil];
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        [sheet showFromBarButtonItem:self.navigationItem.rightBarButtonItem animated:YES];
    } else {
        [sheet showInView:self.view];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 0) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Название чата" message:nil delegate:self cancelButtonTitle:@"Отмена" otherButtonTitles:@"ОК", nil];
        alert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [alert textFieldAtIndex:0].text = self.session.title;
        [alert show];
    } else if (buttonIndex == 1) {
        NSMutableString *export = [NSMutableString string];
        for (ChatMessage *m in self.session.messages) {
            [export appendFormat:@"%@: %@\n\n", m.isUser ? @"Я" : @"G6mini", m.text];
        }
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[export] applicationActivities:nil];
        if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
            self.popover = [[UIPopoverController alloc] initWithContentViewController:avc];
            [self.popover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        } else {
            [self presentViewController:avc animated:YES completion:nil];
        }
    } else if (buttonIndex == 2) {
        [self regenerateLastResponse];
    }
}

- (void)regenerateLastResponse {
    if (self.session.messages.count == 0) return;
    ChatMessage *last = self.session.messages.lastObject;
    if (last.isUser) return;
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"APIKey"];
    if (apiKey.length == 0) return;

    NSInteger lastIdx = self.session.messages.count - 1;
    [self.session.messages removeLastObject];
    [self.heightCache removeObjectForKey:@(lastIdx)];
    [self.segmentCache removeObjectForKey:@(lastIdx)];
    [[ChatManager sharedManager] save];
    [self.tableView reloadData];
    [self updateContextLabel];

    [self executeGeminiRequest:apiKey];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (alertView.tag == 101) {
        if (buttonIndex == 1) {
            NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"APIKey"];
            if (apiKey.length > 0) [self executeGeminiRequest:apiKey];
        }
        return;
    }
    if (buttonIndex == 1) {
        NSString *newTitle = [[alertView textFieldAtIndex:0].text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (newTitle.length > 0) {
            self.session.title = newTitle;
            self.title = newTitle;
            [[ChatManager sharedManager] save];
        }
    }
}

- (void)attachMedia {
    [self.view endEditing:YES];
    if (self.popover && self.popover.isPopoverVisible) {
        [self.popover dismissPopoverAnimated:YES];
        return;
    }
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        self.popover = [[UIPopoverController alloc] initWithContentViewController:picker];
        [self.popover presentPopoverFromRect:self.attachButton.bounds inView:self.attachButton permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self presentViewController:picker animated:YES completion:nil];
    }
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *img = info[UIImagePickerControllerOriginalImage];
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
    if (img) {
        NSData *jpeg = UIImageJPEGRepresentation(img, 0.7);
        NSString *txt = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (txt.length == 0) txt = L(@"Фотография", @"Photo");
        self.inputField.text = @"";
        [self.inputField resignFirstResponder];
        [self sendMediaMessageWithData:jpeg type:@"image/jpeg" text:txt];
    }
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    if (self.popover) {
        [self.popover dismissPopoverAnimated:YES];
        self.popover = nil;
    } else {
        [picker dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)setupAudioSession {
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
}

- (void)toggleRecord {
    if (self.isRecording) {
        [self.audioRecorder stop];
        self.isRecording = NO;
        [self.micButton setTitle:@"🎤" forState:UIControlStateNormal];
        self.micButton.backgroundColor = [UIColor clearColor];

        NSData *audioData = [NSData dataWithContentsOfURL:self.audioRecorder.url];
        if (audioData) {
            NSString *txt = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            if (txt.length == 0) txt = L(@"Голосовое сообщение", @"Voice message");
            self.inputField.text = @"";
            [self.inputField resignFirstResponder];
            [self sendMediaMessageWithData:audioData type:@"audio/m4a" text:txt];
        }
    } else {
        NSString *tmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"voice.m4a"];
        NSURL *url = [NSURL fileURLWithPath:tmp];
        NSDictionary *settings = @{
            AVFormatIDKey: @(kAudioFormatMPEG4AAC),
            AVSampleRateKey: @(16000.0),
            AVNumberOfChannelsKey: @(1)
        };
        self.audioRecorder = [[AVAudioRecorder alloc] initWithURL:url settings:settings error:nil];
        self.audioRecorder.delegate = self;
        [self.audioRecorder record];
        self.isRecording = YES;
        [self.micButton setTitle:@"⏹" forState:UIControlStateNormal];
        self.micButton.backgroundColor = [UIColor redColor];
        self.micButton.layer.cornerRadius = 15;
    }
}

- (void)sendMediaMessageWithData:(NSData *)data type:(NSString *)type text:(NSString *)text {
    ChatMessage *msg = [ChatMessage new];
    msg.text = text;
    msg.mediaData = data;
    msg.mediaType = type;
    msg.isUser = YES;
    [self sendUserMessage:msg];
}

- (void)sendMessage {
    NSString *text = [self.inputField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 0) return;
    ChatMessage *msg = [ChatMessage new];
    msg.text = text;
    msg.isUser = YES;
    self.inputField.text = @"";
    [self.inputField resignFirstResponder];
    [self sendUserMessage:msg];
}

- (void)sendUserMessage:(ChatMessage *)msg {
    NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"APIKey"];
    if (apiKey.length == 0) return;
    
    AudioServicesPlaySystemSound(1004); 
    [self.session.messages addObject:msg];
    if ([self.session.title isEqualToString:@"New Chat"]) {
        self.session.title = [msg.text substringToIndex:MIN((NSUInteger)28, msg.text.length)];
        self.title = self.session.title;
    }
    [[ChatManager sharedManager] save];
    [self.tableView reloadData];
    [self scrollToBottom:YES];
    [self updateContextLabel];

    if (![self isNetworkReachable]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:L(@"Нет сети", @"No Connection") message:L(@"Проверьте подключение к интернету.", @"Check your internet connection.") delegate:self cancelButtonTitle:L(@"Отмена", @"Cancel") otherButtonTitles:L(@"Повторить", @"Retry"), nil];
        alert.tag = 101;
        [alert show];
        return;
    }

    [self executeGeminiRequest:apiKey];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (void)executeGeminiRequest:(NSString *)apiKey {
    NSInteger modelIdx = [[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedModel"];
    NSString *modelId  = @"gemini-3.5-flash-lite";
    if (modelIdx == 1) modelId = @"gemini-3.8-flash";
    else if (modelIdx == 2) modelId = @"gemini-3.1-pro-preview";

    NSString *urlStr = [NSString stringWithFormat:@"https://generativelanguage.googleapis.com/v1beta/models/%@:streamGenerateContent?alt=sse&key=%@", modelId, apiKey];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    req.HTTPMethod  = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    
    NSMutableArray *contents = [NSMutableArray array];
    for (ChatMessage *m in self.session.messages) {
        NSMutableDictionary *content = [NSMutableDictionary dictionary];
        content[@"role"] = m.isUser ? @"user" : @"model";
        NSMutableArray *parts = [NSMutableArray array];
        if (m.text.length > 0) {
            [parts addObject:@{@"text": m.text}];
        }
        if (m.mediaData) {
            NSString *b64 = [m.mediaData respondsToSelector:@selector(base64EncodedStringWithOptions:)] ? [m.mediaData base64EncodedStringWithOptions:0] : [m.mediaData performSelector:@selector(base64Encoding)];
            if (b64) {
                [parts addObject:@{@"inlineData": @{@"mimeType": m.mediaType, @"data": b64}}];
            }
        }
        content[@"parts"] = parts;
        [contents addObject:content];
    }

    NSString *baseInstr = L(@"Всегда отвечай на русском языке.", @"Always reply in English.");
    NSString *personalCtx = [[self activeContextPresetText] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString *fullInstr = personalCtx.length > 0 ? [NSString stringWithFormat:@"%@\n\n%@", baseInstr, personalCtx] : baseInstr;
    NSDictionary *sysInstr = @{ @"parts": @[ @{ @"text": fullInstr } ] };
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"contents": contents, @"systemInstruction": sysInstr} options:0 error:nil];
    self.responseData = [NSMutableData data];

    self.currentStreamingMessage = [ChatMessage new];
    self.currentStreamingMessage.text = @"";
    self.currentStreamingMessage.isUser = NO;
    [self.session.messages addObject:self.currentStreamingMessage];
    [self.tableView reloadData];
    [self scrollToBottom:YES];

    [NSURLConnection connectionWithRequest:req delegate:self];
}
#pragma clang diagnostic pop

- (NSString *)activeContextPresetText {
    NSArray *presets = [[NSUserDefaults standardUserDefaults] arrayForKey:@"ContextPresets"];
    NSString *activeName = [[NSUserDefaults standardUserDefaults] stringForKey:@"ActiveContextPreset"];
    if (activeName.length == 0) return @"";
    for (NSDictionary *p in presets) {
        if ([p[@"name"] isEqualToString:activeName]) return p[@"text"] ?: @"";
    }
    return @"";
}

- (void)generateTitleForFirstMessage:(NSString *)userText apiKey:(NSString *)apiKey {
    NSInteger modelIdx = [[NSUserDefaults standardUserDefaults] integerForKey:@"SelectedModel"];
    NSString *modelId  = @"gemini-3.5-flash-lite";
    if (modelIdx == 1) modelId = @"gemini-3.8-flash";
    else if (modelIdx == 2) modelId = @"gemini-3.1-pro-preview";

    NSString *urlStr = [NSString stringWithFormat:@"https://generativelanguage.googleapis.com/v1beta/models/%@:generateContent?key=%@", modelId, apiKey];
    NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:urlStr]];
    req.HTTPMethod = @"POST";
    [req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

    NSDictionary *sysInstr = @{ @"parts": @[ @{ @"text": L(@"Придумай короткое название для чата (2-4 слова, без кавычек и точки в конце) по первому сообщению пользователя. Ответь только названием, ничего больше.", @"Come up with a short chat title (2-4 words, no quotes or trailing period) based on the user's first message. Reply with only the title, nothing else.") } ] };
    NSDictionary *content = @{ @"role": @"user", @"parts": @[ @{ @"text": userText } ] };
    req.HTTPBody = [NSJSONSerialization dataWithJSONObject:@{@"contents": @[content], @"systemInstruction": sysInstr} options:0 error:nil];

    ChatSession *session = self.session;
    __weak typeof(self) weakSelf = self;
    [NSURLConnection sendAsynchronousRequest:req queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
        if (error || !data) return;
        NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
        if (![json isKindOfClass:[NSDictionary class]]) return;
        NSArray *cands = json[@"candidates"];
        if (![cands isKindOfClass:[NSArray class]] || cands.count == 0) return;
        NSArray *parts = cands[0][@"content"][@"parts"];
        if (![parts isKindOfClass:[NSArray class]] || parts.count == 0) return;
        NSString *title = parts[0][@"text"];
        if (![title isKindOfClass:[NSString class]]) return;
        title = [title stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (title.length == 0) return;
        if (title.length > 40) title = [title substringToIndex:40];

        session.title = title;
        [[ChatManager sharedManager] save];
        typeof(self) strongSelf = weakSelf;
        if (strongSelf && strongSelf.session == session) {
            strongSelf.title = title;
        }
    }];
}

- (void)connection:(NSURLConnection *)conn didReceiveData:(NSData *)data {
    [self.responseData appendData:data];

    NSData *delimiter = [@"\n" dataUsingEncoding:NSUTF8StringEncoding];
    NSUInteger searchFrom = 0;
    while (YES) {
        NSRange searchRange = NSMakeRange(searchFrom, self.responseData.length - searchFrom);
        NSRange found = [self.responseData rangeOfData:delimiter options:0 range:searchRange];
        if (found.location == NSNotFound) break;

        NSRange lineRange = NSMakeRange(searchFrom, found.location - searchFrom);
        [self processSSEEventData:[self.responseData subdataWithRange:lineRange]];
        searchFrom = found.location + found.length;
    }

    if (searchFrom > 0) {
        self.responseData = [[self.responseData subdataWithRange:NSMakeRange(searchFrom, self.responseData.length - searchFrom)] mutableCopy];
    }
}

- (void)processSSEEventData:(NSData *)eventData {
    if (!self.currentStreamingMessage || eventData.length == 0) return;
    NSString *eventStr = [[NSString alloc] initWithData:eventData encoding:NSUTF8StringEncoding];
    if (!eventStr) return;
    eventStr = [eventStr stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (![eventStr hasPrefix:@"data:"]) return;
    NSString *jsonStr = [[eventStr substringFromIndex:5] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (jsonStr.length == 0) return;
    NSData *jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    if (!jsonData) return;
    NSDictionary *json = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    if (![json isKindOfClass:[NSDictionary class]]) return;

    @try {
        if (json[@"error"]) {
            self.currentStreamingMessage.text = [NSString stringWithFormat:@"API Error: %@", json[@"error"][@"message"]];
        } else {
            NSArray *cands = json[@"candidates"];
            if ([cands isKindOfClass:[NSArray class]] && cands.count > 0) {
                NSDictionary *cand = cands[0];
                NSArray *parts = cand[@"content"][@"parts"];
                if ([parts isKindOfClass:[NSArray class]] && parts.count > 0) {
                    NSString *chunk = parts[0][@"text"];
                    if ([chunk isKindOfClass:[NSString class]]) {
                        self.currentStreamingMessage.text = [self.currentStreamingMessage.text stringByAppendingString:chunk];
                    }
                } else if (cand[@"finishReason"] && ![cand[@"finishReason"] isEqual:@"STOP"]) {
                    self.currentStreamingMessage.text = [NSString stringWithFormat:@"%@: %@", L(@"Заблокировано", @"Blocked"), cand[@"finishReason"]];
                }
            }
        }
    } @catch (NSException *e) { return; }

    NSInteger idx = self.session.messages.count - 1;
    [self.segmentCache removeObjectForKey:@(idx)];
    [self.heightCache removeObjectForKey:@(idx)];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:idx inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    [self scrollToBottom:NO];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)conn {
    if (self.responseData.length > 0 && self.currentStreamingMessage) {
        [self processSSEEventData:self.responseData];
    }
    if (self.currentStreamingMessage && self.currentStreamingMessage.text.length == 0) {
        self.currentStreamingMessage.text = L(@"Пустой ответ", @"Empty response");
    }
    self.currentStreamingMessage = nil;
    [[ChatManager sharedManager] save];

    AudioServicesPlaySystemSound(1003);

    [self.tableView reloadData];
    [self scrollToBottom:YES];
    [self updateContextLabel];

    if (self.session.messages.count == 2) {
        NSString *apiKey = [[NSUserDefaults standardUserDefaults] stringForKey:@"APIKey"];
        ChatMessage *firstMsg = self.session.messages.firstObject;
        if (apiKey.length > 0 && firstMsg.text.length > 0) {
            [self generateTitleForFirstMessage:firstMsg.text apiKey:apiKey];
        }
    }
}

- (void)connection:(NSURLConnection *)conn didFailWithError:(NSError *)error {
    if (self.currentStreamingMessage.text.length == 0) {
        [self.session.messages removeObject:self.currentStreamingMessage];
        [self.tableView reloadData];
        [self updateContextLabel];
    }
    self.currentStreamingMessage = nil;

    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:L(@"Ошибка сети", @"Network Error") message:error.localizedDescription delegate:self cancelButtonTitle:L(@"Отмена", @"Cancel") otherButtonTitles:L(@"Повторить", @"Retry"), nil];
    alert.tag = 101;
    [alert show];
}

- (void)chatBubbleCell:(ChatBubbleCell *)cell toggleCodeAtIndex:(NSInteger)msgIndex {
    NSNumber *key = @(msgIndex);
    if ([self.expandedCodeBlocks containsObject:key]) {
        [self.expandedCodeBlocks removeObject:key];
    } else {
        [self.expandedCodeBlocks addObject:key];
    }
    [self.heightCache removeObjectForKey:key];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:msgIndex inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (NSInteger)tableView:(UITableView *)tv numberOfRowsInSection:(NSInteger)section {
    return self.session.messages.count;
}

- (CGFloat)tableView:(UITableView *)tv heightForRowAtIndexPath:(NSIndexPath *)ip {
    NSNumber *cached = self.heightCache[@(ip.row)];
    if (cached) return cached.floatValue;
    ChatMessage *msg = self.session.messages[ip.row];
    NSArray *segs    = [self segmentsForMessageAtIndex:ip.row];
    BOOL expanded    = [self.expandedCodeBlocks containsObject:@(ip.row)];
    CGFloat h = [ChatBubbleCell heightForSegments:segs isUser:msg.isUser maxWidth:tv.bounds.size.width isExpanded:expanded mediaData:msg.mediaData mediaType:msg.mediaType];
    self.heightCache[@(ip.row)] = @(h);
    return h;
}

- (UITableViewCell *)tableView:(UITableView *)tv cellForRowAtIndexPath:(NSIndexPath *)ip {
    ChatBubbleCell *cell = [tv dequeueReusableCellWithIdentifier:kBubbleCellId forIndexPath:ip];
    ChatMessage *msg = self.session.messages[ip.row];
    NSArray *segs    = [self segmentsForMessageAtIndex:ip.row];
    BOOL isDark      = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    BOOL expanded    = [self.expandedCodeBlocks containsObject:@(ip.row)];
    cell.messageIndex = ip.row;
    cell.delegate     = self;
    cell.rawText      = msg.text;
    [cell configureWithSegments:segs isUser:msg.isUser isDark:isDark isExpanded:expanded mediaData:msg.mediaData mediaType:msg.mediaType];
    return cell;
}

- (NSInteger)estimatedTokenCount {
    NSInteger ascii = 0, other = 0;
    for (ChatMessage *m in self.session.messages) {
        for (NSUInteger i = 0; i < m.text.length; i++) {
            unichar c = [m.text characterAtIndex:i];
            if (c < 128) ascii++; else other++;
        }
    }
    return (ascii / 4) + (other / 2);
}

- (void)updateContextLabel {
    NSInteger tokens = [self estimatedTokenCount];
    NSString *countStr = tokens >= 1000 ? [NSString stringWithFormat:@"%.1fk", tokens / 1000.0] : [NSString stringWithFormat:@"%ld", (long)tokens];
    self.contextLabel.text = [NSString stringWithFormat:@"≈%@ / %ldk %@", countStr, (long)(kSoftTokenLimit / 1000), L(@"токенов", @"tokens")];
    self.contextLabel.textColor = tokens > kSoftTokenLimit ? [UIColor colorWithRed:0.9 green:0.3 blue:0.2 alpha:1.0] : [UIColor grayColor];
}

- (void)scrollToBottom:(BOOL)animated {
    NSInteger cnt = self.session.messages.count;
    if (cnt > 0) {
        NSIndexPath *last = [NSIndexPath indexPathForRow:cnt - 1 inSection:0];
        [self.tableView scrollToRowAtIndexPath:last atScrollPosition:UITableViewScrollPositionBottom animated:animated];
    }
}

- (void)dealloc {
    self.inputField.delegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
