// Uofist | https://t.me/iOS6Great
#import "ChatManager.h"

@implementation ChatMessage

- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.text = [coder decodeObjectForKey:@"text"];
        self.isUser = [coder decodeBoolForKey:@"isUser"];
        self.mediaData = [coder decodeObjectForKey:@"mediaData"];
        self.mediaType = [coder decodeObjectForKey:@"mediaType"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.text forKey:@"text"];
    [coder encodeBool:self.isUser forKey:@"isUser"];
    [coder encodeObject:self.mediaData forKey:@"mediaData"];
    [coder encodeObject:self.mediaType forKey:@"mediaType"];
}
@end

@implementation ChatSession

- (instancetype)init {
    if (self = [super init]) {
        self.sessionId = [[NSUUID UUID] UUIDString];
        self.messages = [NSMutableArray array];
        self.title = @"New Chat";
    }
    return self;
}
- (instancetype)initWithCoder:(NSCoder *)coder {
    if (self = [super init]) {
        self.sessionId = [coder decodeObjectForKey:@"sessionId"];
        self.title = [coder decodeObjectForKey:@"title"];
        self.messages = [coder decodeObjectForKey:@"messages"];
        self.avatarData = [coder decodeObjectForKey:@"avatarData"];
        self.pinned = [coder decodeBoolForKey:@"pinned"];
    }
    return self;
}
- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:self.sessionId forKey:@"sessionId"];
    [coder encodeObject:self.title forKey:@"title"];
    [coder encodeObject:self.messages forKey:@"messages"];
    [coder encodeObject:self.avatarData forKey:@"avatarData"];
    [coder encodeBool:self.pinned forKey:@"pinned"];
}
@end

@implementation ChatManager
+ (instancetype)sharedManager {
    static ChatManager *shared = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        shared = [[ChatManager alloc] init];
    });
    return shared;
}

- (instancetype)init {
    if (self = [super init]) {
        [self load];
    }
    return self;
}

- (NSString *)filePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    return [paths[0] stringByAppendingPathComponent:@"chats.plist"];
}

- (void)load {
    NSData *data = [NSData dataWithContentsOfFile:[self filePath]];
    if (data) {
        self.sessions = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    } else {
        self.sessions = [NSMutableArray array];
    }
}

- (void)save {
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:self.sessions];
    [data writeToFile:[self filePath] atomically:YES];
}

- (void)addSession:(ChatSession *)session {
    NSUInteger insertIdx = 0;
    for (ChatSession *s in self.sessions) {
        if (!s.pinned) break;
        insertIdx++;
    }
    [self.sessions insertObject:session atIndex:insertIdx];
    [self save];
}

- (void)removeSessionAtIndex:(NSInteger)index {
    if (index >= 0 && index < self.sessions.count) {
        [self.sessions removeObjectAtIndex:index];
        [self save];
    }
}

- (void)togglePinForSession:(ChatSession *)session {
    session.pinned = !session.pinned;
    NSArray *sorted = [self.sessions sortedArrayUsingComparator:^NSComparisonResult(ChatSession *a, ChatSession *b) {
        if (a.pinned == b.pinned) return NSOrderedSame;
        return a.pinned ? NSOrderedAscending : NSOrderedDescending;
    }];
    self.sessions = [sorted mutableCopy];
    [self save];
}
@end
