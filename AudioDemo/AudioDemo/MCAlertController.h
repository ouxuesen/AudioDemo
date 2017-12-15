//
//  MCAlertController.h
//  MCFriends

//

#import <UIKit/UIKit.h>

@protocol TopMostControllerProtocol <NSObject>
- (UIViewController *)visibleViewController;
@end
@interface UINavigationController (MCAlertView) <TopMostControllerProtocol>
@end
@interface UITabBarController (MCAlertView) <TopMostControllerProtocol>
@end

@interface MCAlertContainerViewController : UIViewController

@end

@interface UIApplication (MCAlertView)
/**
 This is your entry point.
 Will return the top most controller, looping through each controllers adopting the TopMostControllerProtocol
 */
+ (UIViewController *)topMostController;
@end

@interface MCAlertView : UIViewController

@property(nonatomic, strong) id controller;

+ (instancetype)showWithMessage:(NSString *)message;

+ (instancetype)showWithTitle:(NSString *)title message:(NSString *)message;

+ (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle;

+ (instancetype)initWithMessage:(NSString *)message
              cancelButtonTitle:(NSString *)cancelButtonTitle
              otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)clickedIndex:(NSInteger)index;

- (void)showWithCompletionBlock:(void (^)(NSInteger buttonIndex))completionBlock;

@end

@interface MCActionSheet : UIViewController <UIActionSheetDelegate>

@property(nonatomic, strong) id controller;

+ (instancetype)initWithOtherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

+ (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION;

- (void)clickedIndex:(NSInteger)index;

- (void)showWithCompletionBlock:(void (^)(NSInteger buttonIndex))completionBlock;

@end
