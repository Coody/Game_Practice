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
    EnumZPosition_CSCharacter_Self = 100,
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
    self.zPosition = EnumZPosition_CSCharacter_Self;
    self.name = @"Character";
    self.position = CGPointFromString([charData objectForKey:@"StartLocation"]);
    
    useForCollisions = [[characterData objectForKey:@"UseForCollisions"] boolValue];
    
    if ( useForCollisions == YES ) {
        [self setupPhysics];
    }
    
    /*
     
     參考：http://ios-imaxlive.blogspot.tw/2013/07/uiuserinterfaceidiom.html
     
    UI_USER_INTERFACE_IDIOM() 使用中的設備類型
    在使用 storyboad 時, 必須指明要使用的 device 是 iPad 或 iPhone, 會產生出2個不同的名字, 如果是要從 即有的 xib 裡切換 presentModalViewController 時可能就會遇這一個問題.
    
    判斷目前執行中的 Device 是使用 iPad 還是 iPhone, 請參考下面的範例:
     */
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        // The device is an iPad running iOS 3.2 or later.
        self.xScale = .75;
        self.yScale = .75;
    }
    else {
        // The device is an iPhone or iPod touch.
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
    
    // 設定反彈力
    self.physicsBody.restitution = 0.2;
    
    // 禁止旋轉
    self.physicsBody.allowsRotation = NO;
    
    // 設定 BitMask 來標示物件
    self.physicsBody.categoryBitMask = playerCategory;
    
    // collision 碰撞的意思，設定碰撞的 BitMask ，意思是說你要監聽碰撞到哪些東西的時候給回應
    // （ 牆壁、以及其他 player character 物件 ）
    self.physicsBody.collisionBitMask = wallCategory | playerCategory;
    
    // 碰撞後會聯繫的 category ，可以用 | 來聯繫多個 body ，然後同上
    self.physicsBody.contactTestBitMask = wallCategory | playerCategory;
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
