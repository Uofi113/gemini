// Uofist | https://t.me/iOS6Great
#import <UIKit/UIKit.h>
#import "ChatMessageParser.h"

@class ChatBubbleCell;
@protocol ChatBubbleCellDelegate <NSObject>
- (void)chatBubbleCell:(ChatBubbleCell *)cell toggleCodeAtIndex:(NSInteger)msgIndex;
@end

@interface ChatBubbleCell : UITableViewCell
@property (nonatomic, weak) id<ChatBubbleCellDelegate> delegate;
@property (nonatomic, assign) NSInteger messageIndex;
@property (nonatomic, copy) NSString *rawText;

+ (CGFloat)heightForSegments:(NSArray *)segments isUser:(BOOL)isUser maxWidth:(CGFloat)maxWidth isExpanded:(BOOL)isExpanded mediaData:(NSData *)mediaData mediaType:(NSString *)mediaType;

- (void)configureWithSegments:(NSArray *)segments isUser:(BOOL)isUser isDark:(BOOL)isDark isExpanded:(BOOL)isExpanded mediaData:(NSData *)mediaData mediaType:(NSString *)mediaType;
@end
