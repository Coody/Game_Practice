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
    SKNode *myWorld;
    CSCharacter *leader;
}
@end

@implementation CSLevel

-(id)initWithSize:(CGSize)size{
    if ( self = [super initWithSize:size] ) {
        
        [self setUpScene];
        
        [self performSelector:@selector(setUpCharacters) withObject:nil afterDelay:4.0f];
        
    }
    return self;
}

-(void)setUpScene{
    //
    self.anchorPoint = CGPointMake(0.5, 0.5);
    myWorld = [SKNode node];
    [self addChild:myWorld];
    
    SKSpriteNode *map = [SKSpriteNode spriteNodeWithImageNamed:@"level_map1"];
    map.position = CGPointMake(0, 0);
    
    // physics
    self.physicsWorld.gravity = CGVectorMake(0, 1);
    self.physicsWorld.contactDelegate = self;
    
    myWorld.physicsBody = [SKPhysicsBody bodyWithEdgeLoopFromRect:map.frame];
    myWorld.physicsBody.categoryBitMask = wallCategory;
    
}

-(void)setUpCharacters{
    NSLog(@" set up characters!");
    
    leader = [CSCharacter node];
    
    [myWorld addChild:leader];
    
}

-(void)didBeginContact:(SKPhysicsContact *)contact{
    SKPhysicsBody *firstBody , *secondBody;
    
    
}

-(void)update:(NSTimeInterval)currentTime{
    
}

@end
