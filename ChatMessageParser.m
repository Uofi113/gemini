// Uofist | https://t.me/iOS6Great
#import "ChatMessageParser.h"

@implementation MessageSegment
@end

@implementation ChatMessageParser

+ (NSArray *)parseMessage:(NSString *)rawText {
    NSMutableArray *segments = [NSMutableArray array];
    if (!rawText.length) return segments;

    NSError *err = nil;
    
    NSRegularExpression *codeRegex = [NSRegularExpression
        regularExpressionWithPattern:@"```([a-zA-Z0-9+#-]*)[\\r\\n]?([\\s\\S]*?)```"
        options:0 error:&err];

    NSArray *matches = [codeRegex matchesInString:rawText options:0 range:NSMakeRange(0, rawText.length)];
    NSInteger lastEnd = 0;

    for (NSTextCheckingResult *match in matches) {
        
        if ((NSInteger)match.range.location > lastEnd) {
            NSRange textRange = NSMakeRange(lastEnd, match.range.location - lastEnd);
            NSString *txt = [[rawText substringWithRange:textRange]
                             stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
            txt = [self stripMarkdown:txt];
            if (txt.length > 0) {
                MessageSegment *seg = [MessageSegment new];
                seg.type = MessageSegmentTypeText;
                seg.content = txt;
                [segments addObject:seg];
            }
        }

        
        NSString *lang = @"code";
        NSRange langRange = [match rangeAtIndex:1];
        if (langRange.length > 0) {
            lang = [rawText substringWithRange:langRange];
        }
        NSString *code = @"";
        NSRange codeRange = [match rangeAtIndex:2];
        if (codeRange.length > 0) {
            code = [[rawText substringWithRange:codeRange]
                    stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        }

        MessageSegment *seg = [MessageSegment new];
        seg.type = MessageSegmentTypeCode;
        seg.language = (lang.length > 0) ? lang : @"code";
        seg.content = code;
        [segments addObject:seg];

        lastEnd = (NSInteger)(match.range.location + match.range.length);
    }

    
    if (lastEnd < (NSInteger)rawText.length) {
        NSString *txt = [[rawText substringFromIndex:lastEnd]
                         stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        txt = [self stripMarkdown:txt];
        if (txt.length > 0) {
            MessageSegment *seg = [MessageSegment new];
            seg.type = MessageSegmentTypeText;
            seg.content = txt;
            [segments addObject:seg];
        }
    }

    
    if (segments.count == 0) {
        NSString *stripped = [self stripMarkdown:rawText];
        stripped = [stripped stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if (stripped.length) {
            MessageSegment *seg = [MessageSegment new];
            seg.type = MessageSegmentTypeText;
            seg.content = stripped;
            [segments addObject:seg];
        }
    }

    return segments;
}

+ (NSString *)stripMarkdown:(NSString *)text {
    if (!text.length) return text;

    NSMutableString *s = [NSMutableString stringWithString:text];
    NSError *err = nil;
    NSRegularExpression *r;

    
    r = [NSRegularExpression regularExpressionWithPattern:@"^#{1,6}\\s+"
                                                  options:NSRegularExpressionAnchorsMatchLines error:&err];
    [r replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@""];

    
    r = [NSRegularExpression regularExpressionWithPattern:@"\\*\\*(.+?)\\*\\*"
                                                  options:NSRegularExpressionDotMatchesLineSeparators error:&err];
    [r replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@"$1"];

    
    r = [NSRegularExpression regularExpressionWithPattern:@"(?<!\\*)\\*(?!\\*)(.+?)(?<!\\*)\\*(?!\\*)"
                                                  options:0 error:&err];
    [r replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@"$1"];

    
    r = [NSRegularExpression regularExpressionWithPattern:@"`([^`\n]+)`"
                                                  options:0 error:&err];
    [r replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@"$1"];

    
    r = [NSRegularExpression regularExpressionWithPattern:@"^[=\\-]{3,}$"
                                                  options:NSRegularExpressionAnchorsMatchLines error:&err];
    [r replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@""];

    
    r = [NSRegularExpression regularExpressionWithPattern:@"\n{3,}"
                                                  options:0 error:&err];
    [r replaceMatchesInString:s options:0 range:NSMakeRange(0, s.length) withTemplate:@"\n\n"];

    return s;
}

@end
