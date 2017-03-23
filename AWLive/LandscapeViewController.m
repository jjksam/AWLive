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

- (UIView *)preview {
    if (!_preview) {
        _preview = [UIView new];
        [self.view addSubview:_preview];
        [self.view sendSubviewToBack:_preview];
        [_preview autoPinEdgesToSuperviewEdges];
        [UIView animateWithDuration:0.1 animations:^{
            [_preview layoutIfNeeded];
        }];
        
        [self.view layoutIfNeeded];
        [_preview setTransform:CGAffineTransformRotate(CGAffineTransformIdentity, -M_PI_2)];
        _preview.transform = CGAffineTransformTranslate(_preview.transform, 90+55, -90-55);

    }
    return _preview;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
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
