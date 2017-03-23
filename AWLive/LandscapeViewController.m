//
//  LandscapeViewController.m
//  AWLive
//
//  Created by jjk on 2017/3/21.
//
//

#import "LandscapeViewController.h"
#import "TestAVCapture.h"
#import "PureLayout.h"

@interface LandscapeViewController ()
@property (nonatomic, strong) TestVideoCapture *testVideoCapture;
@end

@implementation LandscapeViewController

//- (UIView *)preview {
//    if (!_preview) {
//        _preview = [UIView new];
//        [self.view addSubview:_preview];
//        [self.view sendSubviewToBack:_preview];
//        [_preview autoPinEdgesToSuperviewEdges];
//        [_preview layoutIfNeeded];
//        [UIView animateWithDuration:0.1 animations:^{
//            
//        }];
//        
////        CGFloat dx = [UIScreen mainScreen].bounds.size.height / 2 - [UIScreen mainScreen].bounds.size.width / 2;
////        CGFloat dy = [UIScreen mainScreen].bounds.size.height / 2 - [UIScreen mainScreen].bounds.size.width / 2;
////        CGAffineTransform transform = CGAffineTransformMakeTranslation(-dx, -dy);
////        _preview.transform = CGAffineTransformRotate(transform, -M_PI_2);
//    }
//    return _preview;
//}
- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _preview = [UIView new];
    [self.view addSubview:_preview];
    [self.view sendSubviewToBack:_preview];
    [_preview autoPinEdgesToSuperviewEdges];
    [_preview layoutIfNeeded];
    self.testVideoCapture = [[TestVideoCapture alloc] initWithViewController:self];
    
}

- (void)viewWillLayoutSubviews{
    [super viewWillLayoutSubviews];
    [self.testVideoCapture onLayout];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskLandscapeRight;
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationLandscapeRight;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return NO;
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
