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
    
    
    int currentLevel;
    
    SKNode *myWorld;
    CSCharacter *leader;
    
    NSArray *characterArray;
}
@end

@implementation CSLevel

-(id)initWithSize:(CGSize)size{
    if ( self = [super initWithSize:size] ) {
        
        currentLevel = 0;
        
        [self setUpScene];
        
        [self setUpCharacters];
        
    }
    return self;
}

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
    
    
    //////////////////// 重點：設定 physics world （到 SKScene 上） ///////////////////
    // 設定 physicsWorld 的重力（x,y）
    self.physicsWorld.gravity = CGVectorMake(0.0, 0.0);
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

-(void)setUpCharacters{
    NSLog(@" set up characters!");
    
    leader = [CSCharacter node];
    [leader createWithDictionary:[characterArray objectAtIndex:0]];
    
    [myWorld addChild:leader];
    leader.zPosition = EnumZPosition_Level_Leader;
    
}


#pragma mark - 碰撞監聽
//////////////// 重點：實作 SKPhysicsContactDelegate 的碰撞回呼 /////////////
-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody , *secondBody;
    
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
    
    if ( firstBody.categoryBitMask == wallCategory || secondBody.categoryBitMask == wallCategory ) {
        NSLog(@" Hit!!!! ");
        
        
    }
}


#pragma mark - Gesture
///////////////////// 手勢
-(void)didMoveToView:(SKView *)view{
    
}

#pragma mark - Camera Center In
///////////////////// 將給定的 node 置中！！！ /////////////////////////
- (void)didSimulatePhysics{
    [self centerOfNode:leader];
}

-(void)centerOfNode:(SKNode *)node{
    CGPoint camaraPositionScene = [node.scene convertPoint:node.position fromNode:node.parent];
    node.parent.position = CGPointMake(node.parent.position.x - camaraPositionScene.x, node.parent.position.y - camaraPositionScene.y);
}

-(void)update:(NSTimeInterval)currentTime{
    
}

@end
