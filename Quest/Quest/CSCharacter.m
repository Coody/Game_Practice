//
//  CSCharacter.m
//  Quest
//
//  Created by CoodyChou on 2015/12/31.
//  Copyright © 2015年 CoodyChou. All rights reserved.
//

#import "CSCharacter.h"

// for constant
#import "Constants.h"

@interface CSCharacter()
{
    // actual image
    SKSpriteNode *character;
    
    NSDictionary *characterData;
    
}
@end

@implementation CSCharacter

-(id)init{
    if ( self = [super init] ) {
        
        
        
    }
    return self;
}


-(void)createWithDictionary:(NSDictionary *)charData{
    
    characterData = [NSDictionary dictionaryWithDictionary:charData];
    
    character = [SKSpriteNode spriteNodeWithImageNamed:[characterData objectForKey:@"BaseFrame"]];
    [self addChild:character];
    
    self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:character.frame.size.width/2];
    self.physicsBody.dynamic = YES;
    self.physicsBody.restitution = 1.5;
    self.physicsBody.allowsRotation = YES;
    
    self.physicsBody.categoryBitMask = playerCategory;
    self.physicsBody.collisionBitMask = wallCategory;   // collision 碰撞的意思
    self.physicsBody.contactTestBitMask = wallCategory; // 碰撞後會聯繫的 category , 可以用 | 來聯繫多個 body
    
}

@end
