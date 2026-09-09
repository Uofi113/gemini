// Uofist | https://t.me/iOS6Great
#import <Foundation/Foundation.h>

@interface ChatMessage : NSObject <NSCoding>

@property (nonatomic, strong) NSString *text;
@property (nonatomic, assign) BOOL isUser;
@property (nonatomic, strong) NSData *mediaData;
@property (nonatomic, strong) NSString *mediaType; 
@end

@interface ChatSession : NSObject <NSCoding>

@property (nonatomic, strong) NSString *sessionId;
@property (nonatomic, strong) NSString *title;
@property (nonatomic, strong) NSMutableArray *messages;
@property (nonatomic, strong) NSData *avatarData;
@property (nonatomic, assign) BOOL pinned;
@end

@interface ChatManager : NSObject
@property (nonatomic, strong) NSMutableArray *sessions;
+ (instancetype)sharedManager;
- (void)save;
- (void)addSession:(ChatSession *)session;
- (void)removeSessionAtIndex:(NSInteger)index;
- (void)togglePinForSession:(ChatSession *)session;
@end
