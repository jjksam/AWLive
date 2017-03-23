//
//  ViewController.m
//  AWLive
//
//  Created by wanghongyu on 5/11/16.
//
//

#import "ViewController.h"
#import "LandscapeViewController.h"
#import "PureLayout.h"

@interface ViewController ()
@property (nonatomic, strong) LandscapeViewController *vc;
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
    
    [landscapePush autoSetDimensionsToSize:CGSizeMake(100, 44)];
    [landscapePush autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:90];
    [landscapePush autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:30];
    
    [portraitPush autoSetDimensionsToSize:CGSizeMake(100, 44)];
    [portraitPush autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:90];
    [portraitPush autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:30];
}

- (void)landscapePush {
    self.vc = [LandscapeViewController new];
    [self presentViewController:self.vc animated:YES completion:nil];
}

- (void)portraitPush {
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
