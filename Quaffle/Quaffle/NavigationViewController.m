//
//  NavigationViewController.m
//  小球碰碰
//
//  Created by 谢 砾威 on 28/11/15.
//  Copyright © 2015 谢 砾威. All rights reserved.
//

#import "NavigationViewController.h"
@import GoogleMobileAds;

@interface NavigationViewController ()

@end

@implementation NavigationViewController

- (void)viewDidLoad {
    [super viewDidLoad];
        NSLog(@"Google Mobile Ads SDK Version: %@", [GADRequest sdkVersion]);
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma make 防止屏幕转动

- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
    return (toInterfaceOrientation == UIInterfaceOrientationPortrait);
}

- (BOOL) shouldAutorotate
{
    return NO;
}


@end
