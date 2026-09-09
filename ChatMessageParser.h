// Uofist | https://t.me/iOS6Great
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, MessageSegmentType) {
    MessageSegmentTypeText,
    MessageSegmentTypeCode
};

@interface MessageSegment : NSObject
@property (nonatomic, assign) MessageSegmentType type;
@property (nonatomic, strong) NSString *content;
@property (nonatomic, strong) NSString *language; 
@end

@interface ChatMessageParser : NSObject
+ (NSArray *)parseMessage:(NSString *)rawText;
@end
