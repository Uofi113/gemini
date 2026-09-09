// Uofist | https://t.me/iOS6Great
#import "G6BackgroundView.h"

@implementation G6BackgroundView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor clearColor];
        self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    }
    return self;
}

- (void)drawRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    BOOL isDark = [[NSUserDefaults standardUserDefaults] boolForKey:@"DarkTheme"];
    
    
    UIColor *centerColor = isDark ? [UIColor colorWithWhite:0.2 alpha:1.0] : [UIColor colorWithWhite:0.95 alpha:1.0];
    UIColor *edgeColor = isDark ? [UIColor colorWithWhite:0.05 alpha:1.0] : [UIColor colorWithWhite:0.75 alpha:1.0];
    
    NSArray *colors = @[(id)centerColor.CGColor, (id)edgeColor.CGColor];
    CGFloat locations[] = {0.0, 1.0};
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locations);
    
    
    CGPoint centerPoint = CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMaxY(self.bounds));
    CGFloat radius = MAX(self.bounds.size.width, self.bounds.size.height);
    
    CGContextDrawRadialGradient(context, gradient, centerPoint, 0, centerPoint, radius, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
    
    NSString *watermark = @"G6mini by Uofist";
    UIFont *font = [UIFont boldSystemFontOfSize:28];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    CGSize size = [watermark sizeWithFont:font];
    UIColor *textColor = isDark ? [UIColor colorWithWhite:1.0 alpha:0.04] : [UIColor colorWithWhite:0.0 alpha:0.04];
    [textColor setFill];
    
    CGPoint pt = CGPointMake((self.bounds.size.width - size.width) / 2.0, (self.bounds.size.height - size.height) / 2.0 - 50);
    [watermark drawAtPoint:pt withFont:font];
#pragma clang diagnostic pop
}

@end
