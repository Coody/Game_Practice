//
//  CSLevel.m
//  Quest
//
//  Created by CoodyChou on 2015/12/30.
//  Copyright © 2015年 CoodyChou. All rights reserved.
//

#import "CSLevel.h"

// for Const
#import "Constants.h"

// for node
#import "CSCharacter.h"

typedef enum{
    EnumZPosition_Level_Map = 10,
    EnumZPosition_Level_Leader = 20,
    EnumZPosition_Level_Shape = 1000,
}EnumZPosition_Level;

@interface CSLevel() < SKPhysicsContactDelegate >
{
    // Gesture
    UISwipeGestureRecognizer *swipeGestureLeft;
    UISwipeGestureRecognizer *swipeGestureRight;
    UISwipeGestureRecognizer *swipeGestureUp;
    UISwipeGestureRecognizer *swipeGestureDown;
    UITapGestureRecognizer *tapOnce;
    UITapGestureRecognizer *twoFingerTap;
    UITapGestureRecognizer *threeFingerTap;
    UIRotationGestureRecognizer *rotationGR;
    
    unsigned char charactersInWorld;    // 0 ~ 255
    
    int currentLevel;
    
    SKNode *myWorld;
    CSCharacter *leader;
    
    NSArray *characterArray;
    
    float followDelay;
    BOOL useDelayedFollow;
}
@end

@implementation CSLevel

-(id)initWithSize:(CGSize)size{
    if ( self = [super initWithSize:size] ) {
        
        currentLevel = 0;
        charactersInWorld = 0;
        
        [self setUpScene];
        
        [self performSelector:@selector(setUpCharacters)
                   withObject:nil
                   afterDelay:2.0f];
        
    }
    return self;
}

-(void)pauseScene{
    self.paused = YES;
}

-(void)unPauseScene{
    self.paused = NO;
}

#pragma mark - Setup Scene
-(void)setUpScene{
    
    
    ////////////////////// 重點：從 plist 取得關卡資料、並且載入 ////////////////////
    // 取得 level 以及 character 的資料，從 .plist 中
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath = [path stringByAppendingPathComponent:@"GameData.plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    NSLog(@" plist = %@" , plistData);
    
    
    
    // 取得 level 資料
    NSMutableArray *levelArray = [NSMutableArray arrayWithArray:[plistData objectForKey:@"Levels"]];
    NSDictionary *levelDict = [NSDictionary dictionaryWithDictionary:[levelArray objectAtIndex:currentLevel]];
    characterArray = [NSArray arrayWithArray:[levelDict objectForKey:@"Characters"]];
    NSLog(@" character array = %@" , characterArray);
    
    
    // 取得是否要 Follow Delay
    followDelay = [[levelDict objectForKey:@"FollowDelay"] floatValue];
    useDelayedFollow = [[levelDict objectForKey:@"UseDelayedFollow"] boolValue];
    
    
    // 初始化 myWord 的基礎 SKNode
    self.anchorPoint = CGPointMake(0.5, 0.5);
    myWorld = [SKNode node];
    [self addChild:myWorld];
    
    
    
    // 設定背景樣式（使用 SKSpriteNode ）
    SKSpriteNode *map = [SKSpriteNode spriteNodeWithImageNamed:[levelDict objectForKey:@"Background"]];
    map.position = CGPointMake(0, 0);
    [myWorld addChild:map];
    map.zPosition = EnumZPosition_Level_Map;
    
    
    
    // 設定真正 physics 碰撞的 frame
    float shrinkage = [[levelDict objectForKey:@"ShrinkBackgroundBoundaryBy"] floatValue];
    // 計算出篇移量的 1/2 ，讓碰撞的綠色框框會在整張大圖的正中央
    // (因為碰撞的綠色框框比較小 0.9 倍的 map.frame 而已)
    int offsetX = (map.frame.size.width - (map.frame.size.width * shrinkage)) / 2;
    int offsetY = (map.frame.size.height - (map.frame.size.height * shrinkage)) / 2;
    CGRect mapWithSmallerRect = CGRectMake(map.frame.origin.x + offsetX,
                                           map.frame.origin.y + offsetY,
                                           map.frame.size.width * shrinkage,
                                           map.frame.size.height * shrinkage);
    
    

    // 設定 physicsWorld 的重力（x,y）
    self.physicsWorld.gravity = CGVectorMake(0, 0);
    // 碰撞 delegate 回呼
    self.physicsWorld.contactDelegate = self;
    
    /////////////////// 重點：設定完 physics world 後，再設定 physics body （設定到 SKNode 上）/////////////////

    myWorld.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:mapWithSmallerRect];
    myWorld.physicsBody.categoryBitMask = wallCategory;// 給這個碰撞的 body 一個 tag
    
    if ( [[levelDict objectForKey:@"DebugBroader"] boolValue] == YES ) {
        [self debugPath:map.frame];
    }
    
    
    
}


///////////////// 重點：利用 SKShapeNode 繪製出碰撞的範圍（線條、或形狀 SKShapeNode ） ////////////
-(void)debugPath:(CGRect)theRect{
    
    SKShapeNode *pathShape = [[SKShapeNode alloc] init];
    CGPathRef thePath = CGPathCreateWithRect( theRect , NULL);
    pathShape.path = thePath;
    
    pathShape.lineWidth = 2;
    pathShape.strokeColor = [SKColor greenColor];
    pathShape.position = CGPointMake(0, 0);
    
    pathShape.zPosition = EnumZPosition_Level_Shape;
    [myWorld addChild:pathShape];
    
    
}

#pragma mark - Setup Character
-(void)setUpCharacters{
    NSLog(@" set up characters!");
    
    leader = [CSCharacter node];
    [leader createWithDictionary:[characterArray objectAtIndex:0]];
    [leader makeLeader];
    [myWorld addChild:leader];
    leader.zPosition = EnumZPosition_Level_Leader;
    
    int count = 1;
    while ( count < [characterArray count] ) {
        
        [self performSelector:@selector(createAnotherCharacter) withObject:nil afterDelay:(0.5 * count)];
        
        count++;
    }
    
}

-(void)createAnotherCharacter{
    charactersInWorld++;
    
    CSCharacter *character = [CSCharacter node];
    [character createWithDictionary:[characterArray objectAtIndex:charactersInWorld]];
    [myWorld addChild:character];
    
    character.zPosition = character.zPosition - charactersInWorld;
    
}


#pragma mark - Update
#pragma mark 重要！
-(void)update:(NSTimeInterval)currentTime{
    
    __weak __typeof(self)weakSelf = self;
    // 這裡的 Name 可以用 @"*" 代表( myWorld )全部的 Child ，或是 @"//character" 代表全部的 sub children of
    [myWorld enumerateChildNodesWithName:@"character"
                              usingBlock:
     ^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
         
         __strong __typeof(weakSelf)strongSelf = weakSelf;
         
         // do something if we find a character insoide of myWorld
         CSCharacter *character = (CSCharacter *)node;
         
         if ( strongSelf.paused == NO ) {
             
             if (character == leader) {
                 
             }
             else if ( character.followingEnabled == YES ){
                 character.idealX = leader.position.x;
                 character.idealY = leader.position.y;
             }
             
             [character update];
         }
         
         
         
     }];
}

#pragma mark - 碰撞監聽
//////////////// 重點：實作 SKPhysicsContactDelegate 的碰撞回呼 /////////////
-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody , *secondBody;
    
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
    
    if ( firstBody.categoryBitMask == wallCategory || secondBody.categoryBitMask == wallCategory ) {
        
        
    }
    
    if ( firstBody.categoryBitMask == playerCategory || secondBody.categoryBitMask == playerCategory ) {
        CSCharacter *character = (CSCharacter *)firstBody.node;
        CSCharacter *character2 = (CSCharacter *)secondBody.node;
        
        if ( character == leader ) {
            if ( character2.followingEnabled == NO ) {
                character2.followingEnabled = YES;
                [character2 followIntoPositionWithDirection:[leader returnDirection] andPlaceInLine:1 andLeaderPosition:leader.position];
            }
        }
        else if ( character2 == leader ){
            if ( character.followingEnabled == NO ) {
                character.followingEnabled = YES;
                [character followIntoPositionWithDirection:[leader returnDirection] andPlaceInLine:1 andLeaderPosition:leader.position];
            }
        }
        
    }
}


#pragma mark - Gesture
///////////////////// 手勢
-(void)didMoveToView:(SKView *)view{
    
    // 設置 View 的設定
    
    // 加入手勢
    swipeGestureLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwapeLeft:)];
    [swipeGestureLeft setDirection:(UISwipeGestureRecognizerDirectionLeft)];
    [view addGestureRecognizer:swipeGestureLeft];
    
    swipeGestureRight = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwapeRight:)];
    [swipeGestureRight setDirection:UISwipeGestureRecognizerDirectionRight];
    [view addGestureRecognizer:swipeGestureRight];
    
    swipeGestureUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeUp:)];
    [swipeGestureUp setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [view addGestureRecognizer:swipeGestureUp];
    
    swipeGestureDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(handleSwipeDown:)];
    [swipeGestureDown setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [view addGestureRecognizer:swipeGestureDown];
    
    tapOnce = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedOnce:)];
    tapOnce.numberOfTapsRequired = 1;
    tapOnce.numberOfTouchesRequired = 1;
    [view addGestureRecognizer:tapOnce];
    
    twoFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToSwipeToSecond:)];
    twoFingerTap.numberOfTapsRequired = 1;
    twoFingerTap.numberOfTouchesRequired = 2;
    [view addGestureRecognizer:twoFingerTap];
    
    threeFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self  action:@selector(tapToSwipeToThird:)];
    threeFingerTap.numberOfTapsRequired = 1;
    threeFingerTap.numberOfTouchesRequired = 3;
    [view addGestureRecognizer:threeFingerTap];
    
    rotationGR = [[UIRotationGestureRecognizer alloc] initWithTarget:self action:@selector(handleRotation:)];
    [view addGestureRecognizer:rotationGR];
}

-(void)handleSwapeLeft:(UISwipeGestureRecognizer *)recognizer{
    NSLog(@"Left");
    
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        
        CSCharacter *character = (CSCharacter *)node;
        
        if ( character == leader ) {
            [character moveLeftWithPlace:[NSNumber numberWithInt:0]];
        }
        else{
            
            if ( useDelayedFollow ) {
                [character performSelector:@selector(moveLeftWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay:place * followDelay];
            }
            else{
                [character followIntoPositionWithDirection:left
                                            andPlaceInLine:place
                                         andLeaderPosition:leader.position];
            }
            
        }
        
        place++;
        
    }];
    
}

-(void)handleSwapeRight:(UISwipeGestureRecognizer *)recognizer{
    NSLog(@"Right");
    
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        
        CSCharacter *character = (CSCharacter *)node;
        
        if ( character == leader ) {
            [character moveRightWithPlace:[NSNumber numberWithInt:0]];
        }
        else{
            
            if ( useDelayedFollow ) {
                [character performSelector:@selector(moveRightWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay:place * followDelay];
            }
            else{
                [character followIntoPositionWithDirection:right
                                            andPlaceInLine:place
                                         andLeaderPosition:leader.position];
            }
            
        }
        
        place++;
        
    }];
}

-(void)handleSwipeUp:(UISwipeGestureRecognizer *)recognizer{
    NSLog(@"Up");
    
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        
        CSCharacter *character = (CSCharacter *)node;
        
        if ( character == leader ) {
            [character moveUpWithPlace:[NSNumber numberWithInt:0]];
        }
        else{
            
            if ( useDelayedFollow ) {
                [character performSelector:@selector(moveUpWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay:place * followDelay];
            }
            else{
                [character followIntoPositionWithDirection:up
                                            andPlaceInLine:place
                                         andLeaderPosition:leader.position];
            }
            
        }
        
        place++;
        
    }];
}

-(void)handleSwipeDown:(UISwipeGestureRecognizer *)recognizer{
    NSLog(@"Down");
    
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        
        CSCharacter *character = (CSCharacter *)node;
        
        if ( character == leader ) {
            [character moveDownWithPlace:[NSNumber numberWithInt:0]];
        }
        else{
            
            if ( useDelayedFollow ) {
                [character performSelector:@selector(moveDownWithPlace:) withObject:[NSNumber numberWithInt:place] afterDelay:place * followDelay];
            }
            else{
                [character followIntoPositionWithDirection:down
                                            andPlaceInLine:place
                                         andLeaderPosition:leader.position];
            }
            
        }
        
        place++;
        
    }];
}

-(void)tappedOnce:(UITapGestureRecognizer *)recognizer{
    NSLog(@"Tap Once");
}

-(void)tapToSwipeToSecond:(UITapGestureRecognizer *)recognizer{
    NSLog(@"Tap Twice");
}

-(void)tapToSwipeToThird:(UITapGestureRecognizer *)recognizer{
    NSLog(@"Tap Third");
}

-(void)handleRotation:(UIRotationGestureRecognizer *)recognizer{
    
    if ( recognizer.state == UIGestureRecognizerStateEnded ) {
        NSLog(@"Rotate");
        
        [self stopAllPlayersAndIntoLine];
    }
}

-(void)stopAllPlayersAndIntoLine{
    // 取消上面手勢的 perform:selector:
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    
    __block unsigned char leaderDirection;
    __block unsigned char place = 0;
    
    [myWorld enumerateChildNodesWithName:@"character" usingBlock:^(SKNode * _Nonnull node, BOOL * _Nonnull stop) {
        
        CSCharacter *character = (CSCharacter *)node;
        
        if ( character == leader ) {
            leaderDirection = [leader returnDirection];
            [leader stopMoving];
        }
        else{
            
            // for place , 1 is first follower , 2 is second follower , 0 is Leader ... 
            [character stopInFormation:leaderDirection
                        andPlaceInLine:place
                     andLeaderPosition:leader.position ];
        }
        
        place++;
        
    }];
    
}

/**
 * @brief - 記得移除這個 View 的時候，必須要移除手勢，避免 crash
 */
-(void)willMoveFromView:(SKView *)view{
    NSLog(@"Scene moved from view");
    
    [view removeGestureRecognizer:swipeGestureLeft];
    [view removeGestureRecognizer:swipeGestureRight];
    [view removeGestureRecognizer:swipeGestureUp];
    [view removeGestureRecognizer:swipeGestureDown];
    [view removeGestureRecognizer:tapOnce];
    [view removeGestureRecognizer:twoFingerTap];
    [view removeGestureRecognizer:threeFingerTap];
    [view removeGestureRecognizer:rotationGR];
    
}

#pragma mark - Camera Center In
///////////////////// 將給定的 node 置中！！！ /////////////////////////
- (void)didSimulatePhysics{
    [self centerOfNode:leader];
}

-(void)centerOfNode:(SKNode *)node{
    
    /*
     首先是坐標系，遊戲開發中必須要注意的，如果一個遊戲開發者連坐標系都不知道是什麼的話，還談何開發。
     坐標系主要有屏幕坐標系和遊戲場景裡的世界坐標系，屏幕坐標系大家應該都知道，
     就是原點（0， 0）在屏幕的左上角，而世界坐標系則在屏幕的左下角，兩個坐標系可以相互轉換，
     這個在任何遊戲引擎裡都會有提供一些轉換函數， Sprite Kit 也不例外，有兩個函數可以轉換坐標（場景中contents裡面的東西也可以根據需要，轉變相對參考坐標系）
     convertPoint：fromNode
     和
     convertPoint：ToNode，
     第一個是 formNode 轉變為當前node的坐標系，
     第二個則是由當前的轉變為toNode的node坐標系，
     使用這兩個函數應該注意區分兩個的含義。
     */
    
    
    // 強制將 node.parent 的節點轉成目前（ node ）的座標軸位置，避免座標軸不同造成問題
    CGPoint camaraPositionScene = [node.scene convertPoint:node.position fromNode:node.parent];
    
    // 將 node.parent(父節點) 的位置改成 node 的位置
    node.parent.position = CGPointMake(node.parent.position.x - camaraPositionScene.x, node.parent.position.y - camaraPositionScene.y);
}


@end
