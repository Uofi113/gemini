// Uofist | https://t.me/iOS6Great
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>
#import "ChatManager.h"

@interface ChatViewController : UIViewController <UINavigationControllerDelegate, UIImagePickerControllerDelegate, UIActionSheetDelegate, AVAudioRecorderDelegate>
- (instancetype)initWithSession:(ChatSession *)session;
@end
