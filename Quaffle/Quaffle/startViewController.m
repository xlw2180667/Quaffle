//
//  startViewController.m
//  小球碰碰
//
//  Created by 谢 砾威 on 28/11/15.
//  Copyright © 2015 谢 砾威. All rights reserved.
//

#import "startViewController.h"
#import "ViewController.h"
@import GoogleMobileAds;
@interface startViewController ()
@property (weak, nonatomic) IBOutlet UILabel *maxScore;
@property (weak, nonatomic) IBOutlet GADBannerView *bannerView;

@property (weak, nonatomic) IBOutlet UIButton *startButton;
@end

@implementation startViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bannerView.adUnitID = @"ca-app-pub-3299332488548768/3613719737";
    self.bannerView.rootViewController = self;
//    [self.bannerView loadRequest:[GADRequest request]];
    GADRequest *request = [GADRequest request];
    request.testDevices = @[ @"a78a04b7ef281f5d65e6413b81552b3e" ];
    [self.bannerView loadRequest:request];
    
    self.startButton.backgroundColor = [UIColor greenColor];

    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
