// Uofist | https://t.me/iOS6Great
#import "ChatBubbleCell.h"
#import <QuartzCore/QuartzCore.h>

static const CGFloat kPadH        = 12.0;
static const CGFloat kPadV        = 10.0;
static const CGFloat kCodeHdrH    = 36.0;
static const CGFloat kCodeMaxH    = 180.0;
static const CGFloat kSegSpacing  = 8.0;

@interface ChatBubbleCell ()
@property (nonatomic, strong) UIImageView *bubbleView;
@property (nonatomic, strong) UIImageView *mediaImageView;
@property (nonatomic, strong) UILabel     *mediaLabel;

@property (nonatomic, strong) UILabel     *textLabel2;
@property (nonatomic, strong) UIButton    *codeButton;
@property (nonatomic, strong) UIScrollView *codeScroll;
@property (nonatomic, strong) UILabel     *codeLabel;
@property (nonatomic, strong) UILabel     *postLabel;
@property (nonatomic, strong) UILabel     *typingLabel;
@end

@implementation ChatBubbleCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = [UIColor clearColor];
        self.selectionStyle  = UITableViewCellSelectionStyleNone;
        
        _bubbleView = [[UIImageView alloc] init];
        _bubbleView.userInteractionEnabled = YES;
        [self.contentView addSubview:_bubbleView];

        UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        [_bubbleView addGestureRecognizer:lp];
        
        _mediaImageView = [[UIImageView alloc] init];
        _mediaImageView.contentMode = UIViewContentModeScaleAspectFit;
        _mediaImageView.layer.cornerRadius = 6;
        _mediaImageView.layer.masksToBounds = YES;
        [_bubbleView addSubview:_mediaImageView];
        
        _mediaLabel = [[UILabel alloc] init];
        _mediaLabel.font = [UIFont boldSystemFontOfSize:14];
        _mediaLabel.backgroundColor = [UIColor clearColor];
        [_bubbleView addSubview:_mediaLabel];
        
        _textLabel2 = [[UILabel alloc] init];
        _textLabel2.numberOfLines = 0;
        _textLabel2.backgroundColor = [UIColor clearColor];
        [_bubbleView addSubview:_textLabel2];
        
        _codeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _codeButton.backgroundColor = [UIColor colorWithWhite:0.15 alpha:1.0];
        _codeButton.titleLabel.font = [UIFont boldSystemFontOfSize:13];
        [_codeButton setTitleColor:[UIColor colorWithWhite:0.8 alpha:1.0] forState:UIControlStateNormal];
        [_codeButton addTarget:self action:@selector(codeTapped) forControlEvents:UIControlEventTouchUpInside];
        [_bubbleView addSubview:_codeButton];
        
        _codeScroll = [[UIScrollView alloc] init];
        _codeScroll.backgroundColor = [UIColor colorWithWhite:0.05 alpha:1.0];
        [_bubbleView addSubview:_codeScroll];
        
        _codeLabel = [[UILabel alloc] init];
        _codeLabel.numberOfLines = 0;
        _codeLabel.backgroundColor = [UIColor clearColor];
        [_codeScroll addSubview:_codeLabel];
        
        _postLabel = [[UILabel alloc] init];
        _postLabel.numberOfLines = 0;
        _postLabel.backgroundColor = [UIColor clearColor];
        [_bubbleView addSubview:_postLabel];

        _typingLabel = [[UILabel alloc] init];
        _typingLabel.text = @"● ● ●";
        _typingLabel.font = [UIFont boldSystemFontOfSize:15];
        _typingLabel.backgroundColor = [UIColor clearColor];
        _typingLabel.hidden = YES;
        [_bubbleView addSubview:_typingLabel];
    }
    return self;
}

- (void)codeTapped {
    if (self.delegate) [self.delegate chatBubbleCell:self toggleCodeAtIndex:self.messageIndex];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)gesture {
    if (gesture.state != UIGestureRecognizerStateBegan) return;
    [self becomeFirstResponder];
    UIMenuController *menu = [UIMenuController sharedMenuController];
    [menu setTargetRect:self.bubbleView.bounds inView:self.bubbleView];
    [menu setMenuVisible:YES animated:YES];
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(copy:)) return self.rawText.length > 0;
    return NO;
}

- (void)copy:(id)sender {
    [UIPasteboard generalPasteboard].string = self.rawText;
}

+ (CGFloat)messageFontSize {
    NSInteger stored = [[NSUserDefaults standardUserDefaults] integerForKey:@"FontSize"];
    return stored > 0 ? (CGFloat)stored : 15.0;
}

+ (CGFloat)heightForSegments:(NSArray *)segments isUser:(BOOL)isUser maxWidth:(CGFloat)maxWidth isExpanded:(BOOL)isExpanded mediaData:(NSData *)mediaData mediaType:(NSString *)mediaType {
    CGFloat maxW = MIN(maxWidth - 60, 480);
    CGFloat innerW = maxW - kPadH * 2;
    CGFloat msgFontSize = [self messageFontSize];
    UIFont *font = [UIFont systemFontOfSize:msgFontSize];
    UIFont *codeFont = [UIFont fontWithName:@"Courier" size:msgFontSize * (13.0 / 15.0)];

    CGFloat totalH = kPadV;

    if (mediaData) {
        if ([mediaType hasPrefix:@"image"]) {
            totalH += 120 + kSegSpacing;
        } else {
            totalH += 20 + kSegSpacing;
        }
    }

    for (MessageSegment *seg in segments) {
        if (seg.type == MessageSegmentTypeText) {
            if (seg.content.length > 0) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                CGSize sz = [seg.content sizeWithFont:font constrainedToSize:CGSizeMake(innerW, 9999) lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
                totalH += sz.height + kSegSpacing;
            }
        } else if (seg.type == MessageSegmentTypeCode) {
            totalH += kCodeHdrH;
            if (isExpanded) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                CGSize codeSz = [seg.content sizeWithFont:codeFont constrainedToSize:CGSizeMake(9999, 9999) lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
                CGFloat ch = MIN(codeSz.height + 16, kCodeMaxH);
                totalH += ch;
            }
            totalH += kSegSpacing;
        }
    }

    return MAX(totalH + kPadV, 44.0);
}

- (void)configureWithSegments:(NSArray *)segments isUser:(BOOL)isUser isDark:(BOOL)isDark isExpanded:(BOOL)isExpanded mediaData:(NSData *)mediaData mediaType:(NSString *)mediaType {
    CGFloat maxW = MIN(self.bounds.size.width - 60, 480);
    CGFloat innerW = maxW - kPadH * 2;
    CGFloat msgFontSize = [[self class] messageFontSize];
    UIFont *font = [UIFont systemFontOfSize:msgFontSize];
    
    _bubbleView.image = [self bubbleImageIsUser:isUser isDark:isDark];
    
    UIColor *textColor = isUser ? [UIColor whiteColor] : (isDark ? [UIColor whiteColor] : [UIColor blackColor]);
    UIColor *shadowColor = isUser ? [UIColor colorWithWhite:0 alpha:0.3] : (isDark ? [UIColor blackColor] : [UIColor whiteColor]);
    CGSize shadowOffset = isUser ? CGSizeMake(0, -1) : CGSizeMake(0, 1);
    
    _textLabel2.textColor = textColor;
    _postLabel.textColor = textColor;
    _textLabel2.shadowColor = shadowColor;
    _postLabel.shadowColor = shadowColor;
    _textLabel2.shadowOffset = shadowOffset;
    _postLabel.shadowOffset = shadowOffset;
    _textLabel2.font = font;
    _postLabel.font = font;
    
    _textLabel2.hidden = YES;
    _codeButton.hidden = YES;
    _codeScroll.hidden = YES;
    _postLabel.hidden  = YES;
    _mediaImageView.hidden = YES;
    _mediaLabel.hidden = YES;

    BOOL isTyping = (!isUser && segments.count == 0 && !mediaData);
    _typingLabel.hidden = !isTyping;
    if (isTyping) {
        _typingLabel.textColor = textColor;
        _typingLabel.frame = CGRectMake(kPadH, kPadV, 40, 20);
        if (![_typingLabel.layer animationForKey:@"pulse"]) {
            CABasicAnimation *pulse = [CABasicAnimation animationWithKeyPath:@"opacity"];
            pulse.fromValue = @1.0;
            pulse.toValue   = @0.25;
            pulse.duration  = 0.6;
            pulse.autoreverses = YES;
            pulse.repeatCount  = HUGE_VALF;
            [_typingLabel.layer addAnimation:pulse forKey:@"pulse"];
        }
    } else {
        [_typingLabel.layer removeAnimationForKey:@"pulse"];
    }

    CGFloat currentY = kPadV;
    CGFloat actualInnerW = isTyping ? 40 : 0;

    if (mediaData) {
        actualInnerW = innerW;
        if ([mediaType hasPrefix:@"image"]) {
            _mediaImageView.hidden = NO;
            _mediaImageView.image = [UIImage imageWithData:mediaData];
            _mediaImageView.frame = CGRectMake(kPadH, currentY, innerW, 120);
            currentY += 120 + kSegSpacing;
        } else {
            _mediaLabel.hidden = NO;
            _mediaLabel.text = @"🎤 Голосовое сообщение";
            _mediaLabel.textColor = textColor;
            _mediaLabel.shadowColor = shadowColor;
            _mediaLabel.shadowOffset = shadowOffset;
            _mediaLabel.frame = CGRectMake(kPadH, currentY, innerW, 20);
            currentY += 20 + kSegSpacing;
        }
    }
    
    for (MessageSegment *seg in segments) {
        if (seg.type == MessageSegmentTypeText) {
            if (seg.content.length == 0) continue;
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
            CGSize sz = [seg.content sizeWithFont:font constrainedToSize:CGSizeMake(innerW, 9999) lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
            actualInnerW = MAX(actualInnerW, sz.width);
            if (_textLabel2.hidden) {
                _textLabel2.hidden = NO;
                _textLabel2.text = seg.content;
                _textLabel2.frame = CGRectMake(kPadH, currentY, innerW, sz.height);
            } else {
                _postLabel.hidden = NO;
                _postLabel.text = seg.content;
                _postLabel.frame = CGRectMake(kPadH, currentY, innerW, sz.height);
            }
            currentY += sz.height + kSegSpacing;
        } else if (seg.type == MessageSegmentTypeCode) {
            actualInnerW = innerW;
            _codeButton.hidden = NO;
            NSString *lang = seg.language.length > 0 ? [seg.language uppercaseString] : @"CODE";
            NSString *btnTitle = isExpanded ? [NSString stringWithFormat:@"▼ %@  •  скрыть", lang] : [NSString stringWithFormat:@"▶ %@  •  показать", lang];
            [_codeButton setTitle:btnTitle forState:UIControlStateNormal];
            _codeButton.frame = CGRectMake(kPadH, currentY, innerW, kCodeHdrH);
            currentY += kCodeHdrH;
            
            if (isExpanded) {
                _codeScroll.hidden = NO;
                UIFont *codeFont = [UIFont fontWithName:@"Courier" size:msgFontSize * (13.0 / 15.0)];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
                CGSize codeSz = [seg.content sizeWithFont:codeFont constrainedToSize:CGSizeMake(9999, 9999) lineBreakMode:NSLineBreakByWordWrapping];
#pragma clang diagnostic pop
                CGFloat ch = MIN(codeSz.height + 16, kCodeMaxH);
                _codeScroll.frame = CGRectMake(kPadH, currentY, innerW, ch);
                _codeScroll.contentSize = CGSizeMake(codeSz.width + 16, codeSz.height + 16);
                
                _codeLabel.frame = CGRectMake(8, 8, codeSz.width, codeSz.height);
                _codeLabel.font = codeFont;
                
                NSMutableAttributedString *attr = [[NSMutableAttributedString alloc] initWithString:seg.content];
                [attr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.2 green:0.8 blue:0.2 alpha:1.0] range:NSMakeRange(0, attr.length)];
                
                if (seg.content.length > 0) {
                    NSRegularExpression *strRe = [NSRegularExpression regularExpressionWithPattern:@"\".*?\"" options:0 error:nil];
                    [strRe enumerateMatchesInString:seg.content options:0 range:NSMakeRange(0, seg.content.length) usingBlock:^(NSTextCheckingResult *res, NSMatchingFlags f, BOOL *stop) {
                        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:1.0 green:0.4 blue:0.4 alpha:1.0] range:res.range];
                    }];
                    
                    NSRegularExpression *comRe = [NSRegularExpression regularExpressionWithPattern:@"//.*" options:0 error:nil];
                    [comRe enumerateMatchesInString:seg.content options:0 range:NSMakeRange(0, seg.content.length) usingBlock:^(NSTextCheckingResult *res, NSMatchingFlags f, BOOL *stop) {
                        [attr addAttribute:NSForegroundColorAttributeName value:[UIColor grayColor] range:res.range];
                    }];
                }
                
                _codeLabel.attributedText = attr;
                currentY += ch;
            }
            currentY += kSegSpacing;
        }
    }
    
    actualInnerW = MAX(actualInnerW, 20);
    CGFloat finalW = actualInnerW + kPadH * 2;
    CGFloat finalH = MAX(currentY + kPadV - kSegSpacing, 44);
    
    if (isUser) {
        _bubbleView.frame = CGRectMake(self.bounds.size.width - finalW - 12, 0, finalW, finalH);
    } else {
        _bubbleView.frame = CGRectMake(12, 0, finalW, finalH);
    }

}

- (UIImage *)bubbleImageIsUser:(BOOL)isUser isDark:(BOOL)isDark {
    CGSize size = CGSizeMake(44, 44);
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    CGContextRef ctx = UIGraphicsGetCurrentContext();
    
    UIBezierPath *path = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, 44, 44) cornerRadius:16];
    [path addClip];
    
    NSArray *colors;
    if (isUser) {
        colors = @[(id)[UIColor colorWithRed:0.2 green:0.5 blue:1.0 alpha:1.0].CGColor,
                   (id)[UIColor colorWithRed:0.0 green:0.3 blue:0.8 alpha:1.0].CGColor];
    } else {
        if (isDark) {
            colors = @[(id)[UIColor colorWithWhite:0.3 alpha:1.0].CGColor,
                       (id)[UIColor colorWithWhite:0.15 alpha:1.0].CGColor];
        } else {
            colors = @[(id)[UIColor colorWithWhite:0.95 alpha:1.0].CGColor,
                       (id)[UIColor colorWithWhite:0.8 alpha:1.0].CGColor];
        }
    }
    
    CGGradientRef grad = CGGradientCreateWithColors(NULL, (__bridge CFArrayRef)colors, NULL);
    CGContextDrawLinearGradient(ctx, grad, CGPointMake(0,0), CGPointMake(0,44), 0);
    CGGradientRelease(grad);
    
    
    UIBezierPath *gloss = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(-10, -22, 64, 44)];
    [[UIColor colorWithWhite:1.0 alpha:0.3] setFill];
    [gloss fill];
    
    [[UIColor colorWithWhite:0 alpha:0.15] setStroke];
    path.lineWidth = 2;
    [path stroke];
    
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    if ([img respondsToSelector:@selector(resizableImageWithCapInsets:resizingMode:)]) {
        return [img resizableImageWithCapInsets:UIEdgeInsetsMake(21, 21, 21, 21) resizingMode:UIImageResizingModeStretch];
    }
    return [img stretchableImageWithLeftCapWidth:21 topCapHeight:21];
}

@end
