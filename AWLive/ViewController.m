//
//  ViewController.m
//  AWLive
//
//  Created by wanghongyu on 5/11/16.
//
//

#import "ViewController.h"
#import "PublishViewController.h"
#import "PureLayout.h"

static NSString *sRtmpUrl = @"";

@interface ViewController ()
@property (nonatomic, strong) PublishViewController *vc;
@property (nonatomic, strong) UITextField *textField;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *landscapePush = [[UIButton alloc] initForAutoLayout];
    landscapePush.layer.borderColor = [UIColor blackColor].CGColor;
    landscapePush.layer.borderWidth = 1.0;
    [landscapePush setTitle:@"横屏推流" forState:UIControlStateNormal];
    [landscapePush setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [landscapePush addTarget:self action:@selector(landscapePush) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:landscapePush];
    
    UIButton *portraitPush = [[UIButton alloc] initForAutoLayout];
    portraitPush.layer.borderColor = [UIColor blackColor].CGColor;
    portraitPush.layer.borderWidth = 1.0;
    [portraitPush setTitle:@"竖屏推流" forState:UIControlStateNormal];
    [portraitPush setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [portraitPush addTarget:self action:@selector(portraitPush) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:portraitPush];
    
    _textField = [[UITextField alloc] initForAutoLayout];
    _textField.text = sRtmpUrl;
    _textField.borderStyle = UITextBorderStyleLine;
    [self.view addSubview:_textField];
    
    [landscapePush autoSetDimensionsToSize:CGSizeMake(100, 44)];
    [landscapePush autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:90];
    [landscapePush autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
    
    [portraitPush autoSetDimensionsToSize:CGSizeMake(100, 44)];
    [portraitPush autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:90];
    [portraitPush autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:30];
    
    [_textField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:landscapePush withOffset:30];
    [_textField autoPinEdgeToSuperviewEdge:ALEdgeLeading];
    [_textField autoSetDimensionsToSize:CGSizeMake([UIScreen mainScreen].bounds.size.width, 44)];
}

- (void)landscapePush {
    self.vc = [PublishViewController new];
    self.vc.orientation = UIInterfaceOrientationLandscapeRight;
    self.vc.pushUrl = self.textField.text;
    [self presentViewController:self.vc animated:YES completion:nil];
}

- (void)portraitPush {
    self.vc = [PublishViewController new];
    self.vc.orientation = UIInterfaceOrientationPortrait;
    self.vc.pushUrl = self.textField.text;
    [self presentViewController:self.vc animated:YES completion:nil];
}

- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    [self.view endEditing:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
