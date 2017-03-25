//
//  PublishViewController.m
//  AWLive
//
//  Created by jjk on 2017/3/21.
//
//

#import "PublishViewController.h"
#import "RSCLiveApi.h"
#import "PureLayout.h"

//static NSString *sRtmpUrl = @"rtmp://live.roadshowchina.cn/live/123456";
static NSString *sRtmpUrl = @"rtmp://rtmp-w.quklive.com/live/w1490414374429984";
@interface PublishViewController ()
@property (nonatomic, strong) RSCLiveApi *api;
@property (nonatomic, strong) UIButton *startBtn;

@end

@implementation PublishViewController

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    if (UIInterfaceOrientationIsLandscape(self.orientation)) {
        CGFloat dx = [UIScreen mainScreen].bounds.size.width / 2 - [UIScreen mainScreen].bounds.size.height / 2;
        CGFloat dy = [UIScreen mainScreen].bounds.size.width / 2 - [UIScreen mainScreen].bounds.size.height / 2;
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-dx, -dy);
        self.preview.transform = CGAffineTransformRotate(transform, -M_PI_2);
    }
}

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
    
    UIButton *closeButton = [[UIButton alloc] initForAutoLayout];
    [closeButton setTitle:@"关闭" forState:UIControlStateNormal];
//    closeButton.layer.borderColor = [UIColor blackColor].CGColor;
//    closeButton.layer.borderWidth = 1;
    closeButton.backgroundColor = [UIColor blackColor];
    [closeButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(onClose) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
    
    [closeButton autoSetDimensionsToSize:CGSizeMake(60, 44)];
    [closeButton autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
    [closeButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:30];
    
    self.startBtn = [[UIButton alloc] initForAutoLayout];
    [self.startBtn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.startBtn setTitleColor:[UIColor grayColor] forState:UIControlStateHighlighted];
    self.startBtn.backgroundColor = [UIColor blackColor];
    [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
    [self.startBtn addTarget:self action:@selector(onStartClick) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:self.startBtn];
    
    [self.startBtn autoSetDimensionsToSize:CGSizeMake([UIScreen mainScreen].bounds.size.width - 80, 40)];
    [self.startBtn autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:30];
    [self.startBtn autoAlignAxisToSuperviewAxis:ALAxisVertical];
    
    _api = [[RSCLiveApi alloc] init];
    [_api setAppOrientation:self.orientation];
    [_api setPreviewView:_preview];
    [_api startPreview];
}

- (void)onClose {
    [_api stopPublishing];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onStartClick {
    [self.api startPublishingWithUrl:self.pushUrl];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    if (UIInterfaceOrientationIsPortrait(self.orientation)) {
        return UIInterfaceOrientationMaskPortrait;
    } else {
        return UIInterfaceOrientationMaskLandscapeRight;
    }

}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    if (UIInterfaceOrientationIsPortrait(self.orientation)) {
        return UIInterfaceOrientationPortrait;
    } else {
        return UIInterfaceOrientationLandscapeRight;
    }
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
