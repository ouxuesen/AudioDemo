//
//  MCAlertController.m

#import "MCAlertController.h"

#define UIAlertControllerClass  NSClassFromString(@"UIAlertController")

@implementation UINavigationController (MCAlertView)

- (UIViewController *)visibleViewController{
    return self.topViewController;
}

@end

@implementation UITabBarController (MCAlertView)

- (UIViewController *)visibleViewController {
    return self.selectedViewController;
}

@end

@implementation MCAlertContainerViewController

// <=ios5
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return NO;
}
// ios6
- (BOOL)shouldAutorotate
{
    return NO;
}

@end

@implementation UIApplication (MCAlertView)


+ (UIViewController *)getModalViewControllerOfControllerIfExists:(UIViewController *)controller {
    UIViewController *toReturn = nil;
    // modalViewController is deprecated since iOS 6, so use presentedViewController instead
    if ([controller respondsToSelector:@selector(presentedViewController)]) toReturn = [controller performSelector:@selector(presentedViewController)];
    else toReturn = [controller performSelector:@selector(modalViewController)];
    
    // If no modal view controller found, return the controller itself
    if (!toReturn) toReturn = controller;
    return toReturn;
}

+ (UIViewController *)topMostController {
    // Start with the window rootViewController
    UIViewController *topController = ((UIWindow *)[[UIApplication sharedApplication].windows firstObject]).rootViewController;
    
    // Is there any modal view on top?
    topController = [self getModalViewControllerOfControllerIfExists:topController];
    
    // Keep reference to the old controller while looping
    UIViewController *oldTopController = nil;
    
    // Loop them all
    while ([topController conformsToProtocol:@protocol(TopMostControllerProtocol)] && oldTopController != topController) {
        oldTopController = topController;
        topController = [(UIViewController < TopMostControllerProtocol > *) topController visibleViewController];
        // Again, check for any modal controller
        topController = [self getModalViewControllerOfControllerIfExists:topController];
    }
    
    return topController;
}

@end

@interface MCAlertView()
{
    void (^completeBlock)(NSInteger buttonIndex);
}
@end

@implementation MCAlertView

- (void)clickedIndex:(NSInteger)index
{
    completeBlock?completeBlock(index):nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.controller = nil;
        if (!UIAlertControllerClass) {
            [self removeFromParentViewController];
        }
    });
}

+ (instancetype)showWithMessage:(NSString *)message
{
    MCAlertView *alertView = [self initWithTitle:nil message:message cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView showWithCompletionBlock:nil];
    return alertView;
}

+ (instancetype)showWithTitle:(NSString *)title message:(NSString *)message
{
    MCAlertView *alertView = [self initWithTitle:title message:message cancelButtonTitle:@"确定" otherButtonTitles:nil];
    [alertView showWithCompletionBlock:nil];
    return alertView;
}

+ (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
{
    return [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitles:nil];
}

+ (instancetype)initWithMessage:(NSString *)message
              cancelButtonTitle:(NSString *)cancelButtonTitle
              otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    NSMutableArray *otherTitleArray = [NSMutableArray array];
    va_list _arguments;
    va_start(_arguments, otherButtonTitles);
    for (NSString *key = otherButtonTitles; key != nil; key = (__bridge NSString *)va_arg(_arguments, void *)) {
        [otherTitleArray addObject:key];
    }
    va_end(_arguments);
    
    return [self initWithTitle:nil message:message cancelButtonTitle:cancelButtonTitle otherButtonTitleArray:otherTitleArray];
}

+ (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    NSMutableArray *otherTitleArray = [NSMutableArray array];
    va_list _arguments;
    va_start(_arguments, otherButtonTitles);
    for (NSString *key = otherButtonTitles; key != nil; key = (__bridge NSString *)va_arg(_arguments, void *)) {
        [otherTitleArray addObject:key];
    }
    va_end(_arguments);
    
    return [self initWithTitle:title message:message cancelButtonTitle:cancelButtonTitle otherButtonTitleArray:otherTitleArray];
}

+ (instancetype)initWithTitle:(NSString *)title
                      message:(NSString *)message
            cancelButtonTitle:(NSString *)cancelButtonTitle
        otherButtonTitleArray:(NSArray *)otherButtonTitleArray
{
    MCAlertView *alertController = [[MCAlertView alloc] init];
    
    if(!UIAlertControllerClass){
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                            message:message
                                                           delegate:alertController
                                                  cancelButtonTitle:cancelButtonTitle
                                                  otherButtonTitles:nil];
        for (NSString *otherButtonTitle in otherButtonTitleArray) {
            [alertView addButtonWithTitle:otherButtonTitle];
        }
        
        alertController.controller = alertView;
        
        return alertController;
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title?:@"" message:message preferredStyle:UIAlertControllerStyleAlert];
    int index = 0;
    
    if(cancelButtonTitle){
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [alertController clickedIndex:index];
        }];
        [alertVC addAction:cancelAction];
        
        index ++;
    }
    
    for (NSString *otherButtonTitle in otherButtonTitleArray) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [alertController clickedIndex:index];
        }];
        [alertVC addAction:otherAction];
        
        index ++;
    }
    
    alertController.controller = alertVC;
    
    return alertController;
}

- (void)showWithCompletionBlock:(void (^)(NSInteger buttonIndex))completionBlock
{
    completeBlock = completionBlock;
    dispatch_async(dispatch_get_main_queue(), ^{

    UIViewController *topVC = [UIApplication topMostController];
        if(!UIAlertControllerClass){
            [topVC addChildViewController:self];
            [(UIAlertView *)_controller show];
        
            return;
        }
        
        if (topVC.presentedViewController) {
            [topVC dismissViewControllerAnimated:false completion:^{
                [topVC presentViewController:_controller animated:YES completion:nil];
            }];
        }else{

            [topVC presentViewController:_controller animated:YES completion:nil];
        }
    });
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self clickedIndex:buttonIndex];
}

- (void)dealloc
{
//    completeBlock = nil;
    
    NSLog(@"MCAlertView dealloc");
}

@end


@interface MCActionSheet()
{
    void (^completeBlock)(NSInteger buttonIndex);
}
@end

@implementation MCActionSheet

- (void)clickedIndex:(NSInteger)index
{
    completeBlock?completeBlock(index):nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        self.controller = nil;
        
        if (!UIAlertControllerClass) {
            [self removeFromParentViewController];
        }
    });
}

+ (instancetype)initWithOtherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    NSMutableArray *otherTitleArray = [NSMutableArray array];
    va_list _arguments;
    va_start(_arguments, otherButtonTitles);
    for (NSString *key = otherButtonTitles; key != nil; key = (__bridge NSString *)va_arg(_arguments, void *)) {
        [otherTitleArray addObject:key];
    }
    va_end(_arguments);
    
    return [self initWithTitle:nil cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitleArray:otherTitleArray];
}

+ (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    NSMutableArray *otherTitleArray = [NSMutableArray array];
    va_list _arguments;
    va_start(_arguments, otherButtonTitles);
    for (NSString *key = otherButtonTitles; key != nil; key = (__bridge NSString *)va_arg(_arguments, void *)) {
        [otherTitleArray addObject:key];
    }
    va_end(_arguments);
    
    return [self initWithTitle:title cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil otherButtonTitleArray:otherTitleArray];
}

+ (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
            otherButtonTitles:(NSString *)otherButtonTitles, ... NS_REQUIRES_NIL_TERMINATION
{
    NSMutableArray *otherTitleArray = [NSMutableArray array];
    va_list _arguments;
    va_start(_arguments, otherButtonTitles);
    for (NSString *key = otherButtonTitles; key != nil; key = (__bridge NSString *)va_arg(_arguments, void *)) {
        [otherTitleArray addObject:key];
    }
    va_end(_arguments);
    
    return [self initWithTitle:title cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:destructiveButtonTitle otherButtonTitleArray:otherTitleArray];
}

+ (instancetype)initWithTitle:(NSString *)title
            cancelButtonTitle:(NSString *)cancelButtonTitle
       destructiveButtonTitle:(NSString *)destructiveButtonTitle
        otherButtonTitleArray:(NSArray *)otherButtonTitleArray
{
    MCActionSheet *alertController = [[MCActionSheet alloc] init];
    
    if(!UIAlertControllerClass){
        UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                                 delegate:alertController
                                                        cancelButtonTitle:nil
                                                   destructiveButtonTitle:destructiveButtonTitle
                                                        otherButtonTitles:nil];
        for (NSString *otherButtonTitle in otherButtonTitleArray) {
            [actionSheet addButtonWithTitle:otherButtonTitle];
        }
        [actionSheet addButtonWithTitle:cancelButtonTitle];
        
        actionSheet.cancelButtonIndex = otherButtonTitleArray.count;
        if (destructiveButtonTitle) {
            actionSheet.cancelButtonIndex = otherButtonTitleArray.count + 1;
        }
        alertController.controller = actionSheet;
        
        return alertController;
    }
    
    UIAlertController *alertVC = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    int index = 0;
    
    if(destructiveButtonTitle){
        UIAlertAction *destructiveAction = [UIAlertAction actionWithTitle:destructiveButtonTitle style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
            [alertController clickedIndex:index];
        }];
        [alertVC addAction:destructiveAction];
        
        index ++;
    }
    for (NSString *otherButtonTitle in otherButtonTitleArray) {
        UIAlertAction *otherAction = [UIAlertAction actionWithTitle:otherButtonTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [alertController clickedIndex:index];
        }];
        [alertVC addAction:otherAction];
        
        index ++;
    }
    
    if(cancelButtonTitle){
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:cancelButtonTitle style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            [alertController clickedIndex:index];
        }];
        [alertVC addAction:cancelAction];
        
        index ++;
    }
    alertController.controller = alertVC;
    
    return alertController;
}

- (void)showWithCompletionBlock:(void (^)(NSInteger buttonIndex))completionBlock
{
    completeBlock = completionBlock;
    
    dispatch_async(dispatch_get_main_queue(), ^{

        UIViewController *topVC = [UIApplication topMostController];
       
        
        if(!UIAlertControllerClass){
            [topVC addChildViewController:self];
            [(UIActionSheet *)_controller showInView:topVC.view];
            return;
        }
        
        // for iPAD support:
        UIPopoverPresentationController *popover = [(UIAlertController *)_controller popoverPresentationController];
        if (!popover.sourceView) {
            popover.sourceView = topVC.view;
            popover.sourceRect = CGRectMake(topVC.view.center.x, topVC.view.center.y, 1.0, 1.0); // 显示在中心位置
            popover.permittedArrowDirections = 0;
        }
        
        [topVC presentViewController:_controller animated:YES completion:nil];
    });
}

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    [self clickedIndex:buttonIndex];
}


- (void)dealloc
{
//    completeBlock = nil;
    
    NSLog(@"MCActionSheet dealloc");
}

@end

