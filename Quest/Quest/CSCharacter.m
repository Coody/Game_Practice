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

typedef enum{
    EnumZPosition_CSCharacter_Shape = 1000,
}EnumZPosition_CSCharacter;

@interface CSCharacter()
{
    // actual image
    SKSpriteNode *character;
    
    NSDictionary *characterData;
    
    BOOL useForCollisions;
    
    float collisionBodyCoversWhatPercent;
    
    unsigned char collisionBodyType; // 0~255
    
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
    
    useForCollisions = [[characterData objectForKey:@"UseForCollisions"] boolValue];
    
    if ( useForCollisions == YES ) {
        [self setupPhysics];
    }
}

-(void)setupPhysics{
    
    
    collisionBodyCoversWhatPercent = [[characterData objectForKey:@"CollisionBodyCoversWhatPercent"] floatValue];
    CGSize newSize = CGSizeMake(character.size.width * collisionBodyCoversWhatPercent,
                                character.size.height * collisionBodyCoversWhatPercent);
    
    /////////////// 重點：設定兩種不同形狀的碰撞 body，方形、或圓形
    if ( [[characterData objectForKey:@"CollisionBodyType"] isEqualToString:@"square"] ) {
        collisionBodyType = squareType;
        self.physicsBody = [SKPhysicsBody bodyWithRectangleOfSize:newSize];
        if ( [[characterData objectForKey:@"DebugBody"] boolValue] == YES ) {
            CGRect rect = CGRectMake(-(newSize.width/2),
                                     -(newSize.height/2),
                                     newSize.width,
                                     newSize.height);
            [self debugPath:rect bodyType:collisionBodyType];
        }
    }
    else{
        collisionBodyType = circleType;
        self.physicsBody = [SKPhysicsBody bodyWithCircleOfRadius:newSize.width/2];
        if ( [[characterData objectForKey:@"DebugBody"] boolValue] == YES ) {
            CGRect rect = CGRectMake(-(newSize.width/2),
                                     -(newSize.height/2),
                                     newSize.width,
                                     newSize.height);
            [self debugPath:rect bodyType:collisionBodyType];
        }
    }
    
    
    
    /////////////// 重要：設定 physics body /////////////////
    self.physicsBody.dynamic = YES;
    self.physicsBody.restitution = 0.2;
    self.physicsBody.allowsRotation = NO;
    
    self.physicsBody.categoryBitMask = playerCategory;
    self.physicsBody.collisionBitMask = wallCategory | playerCategory;   // collision 碰撞的意思
    self.physicsBody.contactTestBitMask = wallCategory | playerCategory; // 碰撞後會聯繫的 category , 可以用 | 來聯繫多個 body
}

-(void)debugPath:(CGRect)theRect bodyType:(int)type{
    
    SKShapeNode *pathShape = [[SKShapeNode alloc] init];
    CGPathRef thePath ;
    if ( type == squareType ) {
         thePath = CGPathCreateWithRect( theRect , NULL);
    }
    else{
        thePath = CGPathCreateWithEllipseInRect( theRect , NULL);
    }
    
   
    pathShape.path = thePath;
    
    pathShape.lineWidth = 1;
    pathShape.strokeColor = [SKColor greenColor];
    pathShape.position = CGPointMake(0, 0);
    
    pathShape.zPosition = EnumZPosition_CSCharacter_Shape;
    [self addChild:pathShape];
    
}

@end
