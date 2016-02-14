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
    
    unsigned char speed;    // 0~255
    unsigned char currentDirection;
    
}
@end

@implementation CSCharacter

-(id)init{
    if ( self = [super init] ) {
        
        speed = 5;
        currentDirection = noDirection;
        
    }
    return self;
}


-(void)createWithDictionary:(NSDictionary *)charData{
    
    
    characterData = [NSDictionary dictionaryWithDictionary:charData];
    
    character = [SKSpriteNode spriteNodeWithImageNamed:[characterData objectForKey:@"BaseFrame"]];
    [self addChild:character];
    self.zPosition = EnumZPosition_CSCharacter_Self;
    self.name = @"character";
    self.position = CGPointFromString([charData objectForKey:@"StartLocation"]);
    
    _followingEnabled = [[characterData objectForKey:@"FollowingEnabled"] boolValue];
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
        CGRect adjustedRect = CGRectMake(theRect.origin.x, theRect.origin.y, theRect.size.width, theRect.size.height);
        thePath = CGPathCreateWithEllipseInRect( adjustedRect , NULL);
    }
    
   
    pathShape.path = thePath;
    
    pathShape.lineWidth = 1;
    pathShape.strokeColor = [SKColor greenColor];
    pathShape.position = CGPointMake(0, 0);
    
    pathShape.zPosition = EnumZPosition_CSCharacter_Shape;
    [self addChild:pathShape];
    
}

#pragma mark - Update Methods
-(void)update{
    
    if ( _theLeader == YES || _followingEnabled == YES ) {
        switch (currentDirection) {
            case up:
            {
                self.position = CGPointMake(self.position.x, self.position.y + speed);
                
                if ( _theLeader == NO && self.position.x < _idealX ) {
                    self.position = CGPointMake(self.position.x + 1, self.position.y);
                }
                else if( _theLeader == NO && self.position.x > _idealX ){
                    self.position = CGPointMake(self.position.x - 1, self.position.y);
                }
            }
                break;
            case down:
            {
                self.position = CGPointMake(self.position.x, self.position.y - speed);
                
                if ( _theLeader == NO && self.position.x < _idealX ) {
                    self.position = CGPointMake(self.position.x + 1, self.position.y);
                }
                else if( _theLeader == NO && self.position.x > _idealX ){
                    self.position = CGPointMake(self.position.x - 1, self.position.y);
                }
            }
                break;
            case left:
            {
                self.position = CGPointMake(self.position.x - speed, self.position.y);
                
                if ( _theLeader == NO && self.position.y < _idealY ) {
                    self.position = CGPointMake(self.position.x, self.position.y + 1);
                }
                else if( _theLeader == NO && self.position.y > _idealY ){
                    self.position = CGPointMake(self.position.x, self.position.y - 1);
                }
            }
                break;
            case right:
            {
                self.position = CGPointMake(self.position.x + speed, self.position.y);
                
                if ( _theLeader == NO && self.position.y < _idealY ) {
                    self.position = CGPointMake(self.position.x, self.position.y + 1);
                }
                else if( _theLeader == NO && self.position.y > _idealY ){
                    self.position = CGPointMake(self.position.x, self.position.y - 1);
                }
            }
                break;
            case noDirection:
            {
                
            }
                break;
            default:
                break;
        }
    }
}

#pragma mark - Handle Movement
CGFloat DegreeToRadians(CGFloat degree)
{
    return degree * M_PI / 180;
};

CGFloat RadiansToDegrees(CGFloat radians)
{
    return radians * 180 / M_PI;
};

-(void)moveLeftWithPlace:(NSNumber *)place{
    
    if ( _theLeader == YES || _followingEnabled == YES ){
        character.zRotation = DegreeToRadians(-90);
        currentDirection = left;
    }
    
    
}

-(void)moveRightWithPlace:(NSNumber *)place{
    
    if ( _theLeader == YES || _followingEnabled == YES ){
        character.zRotation = DegreeToRadians(90);
        currentDirection = right;
    }
}

-(void)moveDownWithPlace:(NSNumber *)place{
    
    if ( _theLeader == YES || _followingEnabled == YES ){
        character.zRotation = DegreeToRadians(0);
        currentDirection = down;
    }
}

-(void)moveUpWithPlace:(NSNumber *)place{
    
    if ( _theLeader == YES || _followingEnabled == YES ){
        character.zRotation = DegreeToRadians(180);
        currentDirection = up;
    }
}

#pragma mark - Leader Stuff
-(void)makeLeader{
    _theLeader = YES;
}

-(int)returnDirection{
    return currentDirection;
}

-(void)stopMoving{
    currentDirection = noDirection;
    [character removeAllActions];
}

-(void)stopInFormation:(int)direction
        andPlaceInLine:(unsigned char)place
     andLeaderPosition:(CGPoint)location{
    
    if ( _followingEnabled == YES && currentDirection != noDirection ) {
        int paddingX = character.frame.size.width*0.67;
        int paddingY = character.frame.size.width*0.67;
        
        CGPoint newPosition = CGPointMake(self.position.x, self.position.y);
        switch (direction) {
            case up:
            {
                newPosition = CGPointMake(location.x, location.y - (paddingY * place) );
            }
                break;
            case down:
            {
                newPosition = CGPointMake(location.x, location.y + (paddingY * place) );
            }
                break;
            case right:
            {
                newPosition = CGPointMake(location.x - (paddingX * place), location.y );
            }
                break;
            case left:
            {
                newPosition = CGPointMake(location.x + (paddingX * place), location.y );
            }
                break;
            default:
                break;
        }
        
        SKAction *moveInAction = [SKAction moveTo:newPosition duration:0.5f];
        SKAction *stop = [SKAction performSelector:@selector(stopMoving) onTarget:self];
        SKAction *sequence =[SKAction sequence:@[moveInAction , stop]];
        [self runAction:sequence];
    }
    
    
}

-(void)followIntoPositionWithDirection:(int)direction
                        andPlaceInLine:(unsigned char)place
                     andLeaderPosition:(CGPoint)location{
    
    if ( _followingEnabled == YES ) {
        
        int paddingX = character.frame.size.width*0.67;
        int paddingY = character.frame.size.width*0.67;
        
        CGPoint newPosition = CGPointMake(0, 0);
        switch (direction) {
            case up:
            {
                newPosition = CGPointMake(location.x, location.y - (paddingY * place) );
                [self moveUpWithPlace:[NSNumber numberWithInt:place]];
            }
                break;
            case down:
            {
                newPosition = CGPointMake(location.x, location.y + (paddingY * place) );
                [self moveDownWithPlace:[NSNumber numberWithInt:place]];
            }
                break;
            case right:
            {
                newPosition = CGPointMake(location.x - (paddingX * place), location.y );
                [self moveRightWithPlace:[NSNumber numberWithInt:place]];
            }
                break;
            case left:
            {
                newPosition = CGPointMake(location.x + (paddingX * place), location.y );
                [self moveLeftWithPlace:[NSNumber numberWithInt:place]];
            }
                break;
            default:
                break;
        }
        
        SKAction *moveIntoLine = [SKAction moveTo:newPosition duration:0.2f];
        [self runAction:moveIntoLine];
        
    }
}

@end








