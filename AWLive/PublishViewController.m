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
#import "aw_rtmp.h" // should hide

@interface PublishViewController () <RSCLivePublisherDelegate>
@property (nonatomic, strong) RSCLiveApi *api;
@property (nonatomic, strong) UIButton *startBtn;
@property (nonatomic, strong) UILabel *stateText;
@property (assign) BOOL isPublishing;
@property (assign) BOOL useFrontCamera;

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
    self.useFrontCamera = YES;
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
    
    self.stateText = [[UILabel alloc] initForAutoLayout];
    self.stateText.textColor = [UIColor whiteColor];
    self.stateText.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.stateText];
    
    [self.stateText autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
    [self.stateText autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
    
    UIButton *switchCamera = [[UIButton alloc] initForAutoLayout];
    [switchCamera setTitle:@"switch cam" forState:UIControlStateNormal];
    [switchCamera addTarget:self action:@selector(onSwitchCamera) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:switchCamera];
    
    [switchCamera autoSetDimensionsToSize:CGSizeMake(100, 44)];
    [switchCamera autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:8];
    [switchCamera autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:50];
    
    _api = [[RSCLiveApi alloc] init];
    _api.delegate = self;
    [_api setFrontCam:self.useFrontCamera];
    [_api setAppOrientation:self.orientation];
    [_api setPreviewView:_preview];
    [_api startPreview];
}

- (void)onSwitchCamera {
    self.useFrontCamera = !self.useFrontCamera;
    [_api setFrontCam:self.useFrontCamera];
}

- (void)onClose {
    [_api stopPublishing];
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)onStartClick {
    if (self.isPublishing) {
        [self.api stopPublishing];
        self.isPublishing = NO;
    } else {
        [self.api startPublishingWithUrl:self.pushUrl];
        [self.startBtn setTitle:@"停止直播" forState:UIControlStateNormal];
    }
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

- (void)onPublishStateChangeFrom:(int)fromState toState:(int)toState {
    switch (toState) {
        case aw_rtmp_state_idle: {
            self.startBtn.enabled = YES;
            [self.startBtn setTitle:@"开始直播" forState:UIControlStateNormal];
            self.stateText.text = @"未连接";
            break;
        }
        case aw_rtmp_state_connecting: {
            self.startBtn.enabled = NO;
            self.stateText.text = @"连接中";
            break;
        }
        case aw_rtmp_state_opened: {
            self.startBtn.enabled = YES;
            self.stateText.text = @"正在直播";
            self.isPublishing = YES;
            break;
        }
        case aw_rtmp_state_connected: {
            self.stateText.text = @"连接成功";
            // should send metadata before sending video/audio packet
            break;
        }
        case aw_rtmp_state_closed: {
            self.startBtn.enabled = YES;
            self.stateText.text = @"已关闭";
            break;
        }
        case aw_rtmp_state_error_write: {
            self.stateText.text = @"写入错误";
            break;
        }
        case aw_rtmp_state_error_open: {
            self.stateText.text = @"连接错误";
            self.startBtn.enabled = YES;
            break;
        }
        case aw_rtmp_state_error_net: {
            self.stateText.text = @"网络不给力";
            self.startBtn.enabled = YES;
            break;
        }
    }
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
