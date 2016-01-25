//
//  ViewController.m
//  小球碰碰
//
//  Created by 谢 砾威 on 24/11/15.
//  Copyright © 2015 谢 砾威. All rights reserved.
//

#import "ViewController.h"
#import <CoreMotion/CoreMotion.h>
@import GoogleMobileAds;

@interface ViewController () <UIAlertViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *gameView;
@property (nonatomic, strong) UIDynamicAnimator *animator;
@property (nonatomic, weak) UIGravityBehavior *gravity;
@property (nonatomic, weak) UICollisionBehavior *collider;
@property (nonatomic, weak) UIDynamicItemBehavior *elastic;
@property (nonatomic, weak) UIDynamicItemBehavior *quicksand;
@property (nonatomic, strong) CMMotionManager *motionManager;
@property (nonatomic, weak) UIImageView *redBall;
@property (nonatomic, weak) UIImageView *blackBall;
@property (nonatomic) BOOL isOver;
// 计时器
@property (nonatomic, strong) NSTimer *timer;
@property int number;
// 记分牌
@property (weak, nonatomic) IBOutlet UILabel *maxScoreLable;
@property (weak, nonatomic) IBOutlet UILabel *timeLabel;
@property (nonatomic, weak) UILabel *scoreLabel;
@property (nonatomic) int lastScore;
@property (nonatomic) int maxScore;
@property (nonatomic) double blackBallDistanceTraveled;
@property (nonatomic, strong) NSDate *lastRecordedBlackBallTravelTime;
@property (nonatomic) double cumulativeBlackBallTravelTime;
@property (nonatomic, weak) UIDynamicItemBehavior *blackBallTracker;
@property (nonatomic, weak) UICollisionBehavior *scoreBoundary;
@property (nonatomic) CGPoint scoreBoundaryCenter;
@property (nonatomic) int highScore;
@end

@implementation ViewController

static CGSize ballSize = {35, 35};

- (void) actionTimer:(NSTimer *) timer
{
    self.number++;
    self.timeLabel.text = [NSString stringWithFormat:@"Time:%d",self.number];
    NSLog(@"%d", self.number);
}

//    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(actionTimer:) userInfo:nil repeats:YES];

- (UIImageView *) addBallOffsetFromCenterBy:(UIOffset) offset
{
    CGPoint ImgCenter = CGPointMake(CGRectGetMidX(self.gameView.bounds)/2+offset.horizontal, CGRectGetMidY(self.gameView.bounds)+offset.vertical);
    CGRect ballFrame = CGRectMake(ImgCenter.x-ballSize.width/2, ImgCenter.y-ballSize.height/2, ballSize.width, ballSize.height);
    UIImageView *ball = [[UIImageView alloc]initWithFrame:ballFrame];
    [self.gameView addSubview:ball];
    return ball;
}

- (void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self pauseGame];
    
}
- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self resumeGame];
}


- (void) viewDidLoad
{
    [super viewDidLoad];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(actionTimer:) userInfo:nil repeats:YES];
    self.maxScoreLable.text = [NSString stringWithFormat:@"MaxScore:%d",self.highScore];
    [self.view addSubview:self.gameView];
    [self.gameView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tap)]];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self pauseGame];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self resumeGame];
                                                  }];
    [[NSNotificationCenter defaultCenter] addObserverForName:NSUserDefaultsDidChangeNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification * _Nonnull note) {
                                                      [self resetElasticity];
                                                  }];
}

//重新开始游戏
- (void) restartGame
{
    self.quicksand.resistance = 10;
    [self resetScore];
    [self resumeGame];
}

- (void) tap
{
    if ([self isPaused]) {
        [self resumeGame];
        
    } else {
        [self pauseGame];
    }
}

- (UIDynamicAnimator *) animator
{
    if (!_animator) _animator = [[UIDynamicAnimator alloc] initWithReferenceView:self.gameView];
    return _animator;
}

- (UIGravityBehavior *) gravity
{
    if (!_gravity) {
        UIGravityBehavior *gravity = [[UIGravityBehavior alloc] init];
        [self.animator addBehavior:gravity];
        self.gravity = gravity;
    }
    return _gravity;
}

- (UICollisionBehavior *) collider
{
    if (!_collider) {
        UICollisionBehavior *collider = [[UICollisionBehavior alloc] init];
        collider.translatesReferenceBoundsIntoBoundary = YES;
        [self.animator addBehavior:collider];
        self.collider = collider;
    }
    return _collider;
}

- (UIDynamicItemBehavior *) elastic
{
    if (!_elastic) {
        UIDynamicItemBehavior *elastic = [[UIDynamicItemBehavior alloc] init];
        [self.animator addBehavior:elastic];
        self.elastic = elastic;
        [self resetElasticity];
    }
    return _elastic;
}

- (void) resetElasticity
{
    NSNumber *elastictiy = [[NSUserDefaults standardUserDefaults] valueForKey:@"Settings_Elasticity"];
    if (elastictiy) {
        self.elastic.elasticity = [elastictiy floatValue];
    } else {
        self.elastic.elasticity = 0.8;
    }
}

- (UIDynamicItemBehavior *) quicksand
{
    if (!_quicksand) {
        UIDynamicItemBehavior *quicksand = [[UIDynamicItemBehavior alloc] init];
        quicksand.resistance = 0; // 阻力
        [self.animator addBehavior:quicksand];
        _quicksand = quicksand;
    }
    return _quicksand;
}

- (CMMotionManager *) motionManager
{
    if (!_motionManager) {
        _motionManager = [[CMMotionManager alloc] init];
        _motionManager.accelerometerUpdateInterval = 0.1;
    }
    return _motionManager;
}

- (void) pauseGame
{
    [self.motionManager stopAccelerometerUpdates];
    self.gravity.gravityDirection = CGVectorMake(0, 0);
    self.quicksand.resistance = 10.0;
    [self pauseScoring];
    [_timer setFireDate:[NSDate distantFuture]];// timer暂停运行
    NSLog(@"%d",self.maxScore);
    NSLog(@"%d",self.highScore);

}

- (BOOL) isPaused
{
    return !self.motionManager.isAccelerometerActive;
}


- (void) resumeGame
{
    [super viewDidLoad];
    // redball
    [_timer setFireDate:[NSDate date]];// 将timer的起始运行时间设为现在 即继续运行
    if (!self.redBall) {
        self.redBall = [self addBallOffsetFromCenterBy:UIOffsetMake(10, 0)];
        self.redBall.image = [UIImage imageNamed:@"redBall.png"];
        [self.gravity addItem:self.redBall];
        [self.collider addItem:self.redBall];
        [self.elastic addItem:self.redBall];
        [self.quicksand addItem:self.redBall];
        // blackball
        self.blackBall = [self addBallOffsetFromCenterBy:UIOffsetMake(160, 0)];
        self.blackBall.image = [UIImage imageNamed:@"blackBall.png"];
        [self.collider addItem:self.blackBall];
        [self.quicksand addItem:self.blackBall];
        [self.elastic addItem:self.blackBall];
    }
    self.quicksand.resistance = 0;
    self.gravity.gravityDirection = CGVectorMake(0, 0); //开始先设置重力方向为0
    
    if (!self.motionManager.isAccelerometerActive) {
        [self.motionManager startAccelerometerUpdatesToQueue:[NSOperationQueue mainQueue]
                                                 withHandler:^(CMAccelerometerData * _Nullable accelerometerData, NSError * _Nullable error) {
                                                     CGFloat x = accelerometerData.acceleration.x;
                                                     CGFloat y = accelerometerData.acceleration.y;
                                                     self.gravity.gravityDirection = CGVectorMake(x, y);
                                                     switch (self.interfaceOrientation) {
                                                         case UIInterfaceOrientationLandscapeRight:
                                                             self.gravity.gravityDirection = CGVectorMake( -y, -x);
                                                             break;
                                                         case UIInterfaceOrientationLandscapeLeft:
                                                             self.gravity.gravityDirection = CGVectorMake(y, x);
                                                             break;
                                                         case UIInterfaceOrientationPortrait:
                                                             self.gravity.gravityDirection = CGVectorMake(x, -y);
                                                             break;
                                                         case UIInterfaceOrientationPortraitUpsideDown:
                                                             self.gravity.gravityDirection = CGVectorMake(- x, y);
                                                             break;
                                                     }
                                                     [self updateScore];
                                                     [self updateHighScore];
                                                     if (self.number == 60) {
                                                         [_timer setFireDate:[NSDate distantFuture]];
                                                         self.number = 0;
                                                         self.timeLabel.text = [NSString stringWithFormat:@"Time Over"];
                                                         [self gameOver];
                                                     }
                                                 }];

    }
    
    
#pragma mark - Scorekeeping
    //计分
}
- (void) updateScore
{
    if (self.lastRecordedBlackBallTravelTime) {
        self.cumulativeBlackBallTravelTime -= [self.lastRecordedBlackBallTravelTime timeIntervalSinceNow];
        int score = self.blackBallDistanceTraveled / self.cumulativeBlackBallTravelTime;
        if (score > self.maxScore) self.maxScore = score;
        if ((score != self.lastScore) || ![self.scoreLabel.text length])
        {
            self.scoreLabel.textColor = [UIColor blackColor];
            self.scoreLabel.text = [NSString stringWithFormat:@"%d\n%d", score, self.maxScore];
            [self updateScoreBoundary];
        } else if (!CGPointEqualToPoint(self.scoreLabel.center, self.scoreBoundaryCenter))
        {
            [self updateScoreBoundary];
        }

    }
    else
    {
        [self.animator addBehavior:self.blackBallTracker];
        self.scoreLabel.text = nil;
    }
    self.lastRecordedBlackBallTravelTime = [NSDate date];


}

// 历史最高分
- (void) updateHighScore
{
    if (self.highScore <= self.maxScore)
        self.highScore = self.maxScore;
    self.maxScoreLable.text = [NSString stringWithFormat:@"MaxScore:%d",self.highScore];

}


- (void) pauseScoring
{
    self.lastRecordedBlackBallTravelTime = nil;
    self.scoreLabel.text = @"Pause";
    self.scoreLabel.textColor = [UIColor lightGrayColor];
    [self.animator removeBehavior:self.blackBallTracker];
}

- (void) resetScore
{
    [self.motionManager stopAccelerometerUpdates];
    [self.animator removeBehavior:self.blackBallTracker];
    self.gravity.gravityDirection = CGVectorMake(0, 0);
    self.blackBallDistanceTraveled = 0;
    self.lastRecordedBlackBallTravelTime = nil;
    self.cumulativeBlackBallTravelTime = 0;
    self.quicksand.resistance = 100;

    self.maxScore = 0;
    self.lastScore = 0;
//    self.highScore = self.highScore;
    self.scoreLabel.text = @"";
}

- (UILabel *) scoreLabel
{
    if (!_scoreLabel) {
        UILabel *scoreLabel = [[UILabel alloc] initWithFrame:self.gameView.bounds];
        scoreLabel.font = [scoreLabel.font fontWithSize:42];
        scoreLabel.textAlignment = NSTextAlignmentCenter;
        scoreLabel.numberOfLines = 2;
        scoreLabel.autoresizingMask = UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
        [self.gameView insertSubview:scoreLabel atIndex:0];
        _scoreLabel = scoreLabel;
    }
    return _scoreLabel;
}

- (void) updateScoreBoundary
{
    CGSize scoreSize = [self.scoreLabel.text sizeWithAttributes:@{ NSFontAttributeName : self.scoreLabel.font}];
    self.scoreBoundaryCenter = self.scoreLabel.center;
    CGRect scoreRect = CGRectMake(self.scoreBoundaryCenter.x - scoreSize.width / 2,
                                  self.scoreBoundaryCenter.y - scoreSize.height /2,
                                  scoreSize.width,
                                  scoreSize.height);
    [self.scoreBoundary removeBoundaryWithIdentifier:@"Score"];
    [self.scoreBoundary addBoundaryWithIdentifier:@"Score" forPath:[UIBezierPath bezierPathWithRect:scoreRect]];
}

- (UICollisionBehavior *) scoreBoundary
{
    if (!_scoreBoundary) {
        UICollisionBehavior *scoreBoundary = [[UICollisionBehavior alloc] initWithItems:@[self.redBall, self.blackBall]];
        [self.animator addBehavior:scoreBoundary];
        _scoreBoundary = scoreBoundary;
    }
    return _scoreBoundary;
}

- (UIDynamicItemBehavior *) blackBallTracker
{
    if (!_blackBallTracker) {
        UIDynamicItemBehavior *blackBallTracker = [[UIDynamicItemBehavior alloc] initWithItems:@[self.blackBall]];
        [self.animator addBehavior:blackBallTracker];
        __weak ViewController *weakSelf = self;
        __block CGPoint lastKnownBlackBallCenter = self.blackBall.center;
        blackBallTracker.action = ^{
            CGFloat dx = weakSelf.blackBall.center.x - lastKnownBlackBallCenter.x;
            CGFloat dy = weakSelf.blackBall.center.y - lastKnownBlackBallCenter.y;
            weakSelf.blackBallDistanceTraveled += sqrt(dx*dx + dy*dy);
            lastKnownBlackBallCenter = weakSelf.blackBall.center;
        };
        _blackBallTracker =blackBallTracker;
    }
    return _blackBallTracker;
}

- (void) alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == 100) {
        if (buttonIndex==0) {
            [self resumeGame];
        }
    }
}

- (void) gameOver
{
    if (self.maxScore == self.highScore) {
        //self.highScore = self.maxScore;
        [self.motionManager stopAccelerometerUpdates];
        [self resetScore];
        NSLog(@"xianzai%d",self.highScore);
        NSLog(@"重新开始后%d", self.highScore);
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Game Over"
                                                            message:[NSString stringWithFormat:@"新纪录：%d",self.highScore]
                                                           delegate:self
                                                  cancelButtonTitle:@"Retry"
                                                  otherButtonTitles:@"Return", nil];
        alertView.tag = 100;
        [alertView show];

    } else if (self.maxScore < self.highScore){
        NSLog(@"重新开始后%d", self.highScore);
        [self.motionManager stopAccelerometerUpdates];
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Game Over"
                                                            message:[NSString stringWithFormat:@"分数为：%d",self.maxScore]
                                                           delegate:self
                                                  cancelButtonTitle:@"Retry"
                                                  otherButtonTitles:@"Return", nil];
        alertView.tag = 100;
        [self resetScore];

        [alertView show];
    }

}


#pragma mark 保存最高分



@end
