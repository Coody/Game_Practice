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

@interface CSLevel() < SKPhysicsContactDelegate >
{
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
        
        [self performSelector:@selector(setUpCharacters) withObject:nil afterDelay:4.0f];
        
    }
    return self;
}

-(void)setUpScene{
    
    // 取得 level 以及 character 的資料，從 .plist 中
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *finalPath = [path stringByAppendingPathComponent:@"GameData.plist"];
    NSDictionary *plistData = [NSDictionary dictionaryWithContentsOfFile:finalPath];
    
    NSLog(@" plist = %@" , plistData);
    
    NSMutableArray *levelArray = [NSMutableArray arrayWithArray:[plistData objectForKey:@"Levels"]];
    NSDictionary *levelDict = [NSDictionary dictionaryWithDictionary:[levelArray objectAtIndex:currentLevel]];
    characterArray = [NSArray arrayWithArray:[levelDict objectForKey:@"Characters"]];
    NSLog(@" character array = %@" , characterArray);
    
    //
    self.anchorPoint = CGPointMake(0.5, 0.5);
    myWorld = [SKNode node];
    [self addChild:myWorld];
    
    SKSpriteNode *map = [SKSpriteNode spriteNodeWithImageNamed:[levelDict objectForKey:@"Background"]];
    map.position = CGPointMake(0, 0);
    [myWorld addChild:map];
    map.zPosition = 10;
    
    // physics
    self.physicsWorld.gravity = CGVectorMake(0.5, -0.9);
    self.physicsWorld.contactDelegate = self;
    
    myWorld.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:map.frame];
    myWorld.physicsBody.categoryBitMask = wallCategory;
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody , *secondBody;
    
    firstBody = contact.bodyA;
    secondBody = contact.bodyB;
    
    if ( firstBody.categoryBitMask == wallCategory || secondBody.categoryBitMask == wallCategory ) {
        NSLog(@" Hit!!!! ");
        
        
    }
    
    
}

-(void)setUpCharacters{
    NSLog(@" set up characters!");
    
    leader = [CSCharacter node];
    [leader createWithDictionary:[characterArray objectAtIndex:0]];
    
    [myWorld addChild:leader];
    leader.zPosition = 20;
    
}

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
