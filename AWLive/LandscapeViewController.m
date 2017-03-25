//
//  LandscapeViewController.m
//  AWLive
//
//  Created by jjk on 2017/3/21.
//
//

#import "LandscapeViewController.h"
#import "RSCLiveApi.h"
#import "PureLayout.h"

static NSString *sRtmpUrl = @"rtmp://live.roadshowchina.cn/live/123456";

@interface LandscapeViewController ()
@property (nonatomic, strong) RSCLiveApi *api;
@property (nonatomic, strong) UIButton *startBtn;
@end

@implementation LandscapeViewController

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    CGFloat dx = [UIScreen mainScreen].bounds.size.width / 2 - [UIScreen mainScreen].bounds.size.height / 2;
    CGFloat dy = [UIScreen mainScreen].bounds.size.width / 2 - [UIScreen mainScreen].bounds.size.height / 2;
    CGAffineTransform transform = CGAffineTransformMakeTranslation(-dx, -dy);
    self.preview.transform = CGAffineTransformRotate(transform, -M_PI_2);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _preview = [UIView new];
    [self.view addSubview:_preview];
    [self.view sendSubviewToBack:_preview];
    [_preview autoPinEdgesToSuperviewEdges];
    [_preview layoutIfNeeded];
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
    [_api setPreviewView:_preview];
    [_api startPreview];
}

- (void)onStartClick {
    [self.api startPublishingWithUrl:sRtmpUrl];
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
