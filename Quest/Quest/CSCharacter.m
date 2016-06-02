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
    
    BOOL useFrontViewFrames;
    BOOL useRestingFrames;
    BOOL useSideViewFrames;
    BOOL useBackViewFrames;
    BOOL useSideAttackFrames;
    BOOL useFrontAttackFrames;
    BOOL useBackAttackFrames;
    
    SKAction *walkFrontAction;
    SKAction *walkBackAction;
    SKAction *walkSideAction;
    SKAction *repeatRest;
    SKAction *sideAttackAction;
    SKAction *frontAttackAction;
    SKAction *backAttackAction;
    
    unsigned char fps; // the range is 0~ 255 , but really 1~60 is fine
    
    
}
@end

@implementation CSCharacter

-(id)init{
    if ( self = [super init] ) {
        
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
    
    speed = [[characterData objectForKey:@"Speed"] integerValue];
    
    // Textures
    fps = [[charData objectForKey:@"FPS"] integerValue];

    useBackViewFrames = [[charData objectForKey:@"UseBackViewFrames"] boolValue];
    useSideViewFrames = [[charData objectForKey:@"UseSideViewFrames"] boolValue];
    useFrontViewFrames = [[charData objectForKey:@"UseFrontViewFrames"] boolValue];
    useRestingFrames = [[charData objectForKey:@"UseRestingFrames"] boolValue];
    useSideAttackFrames = [[charData objectForKey:@"UseSideAttackFrames"] boolValue];
    useFrontAttackFrames = [[charData objectForKey:@"UseFrontAttackFrames"] boolValue];
    useBackAttackFrames = [[charData objectForKey:@"UseBackAttackFrames"] boolValue];
    
    if ( useRestingFrames == YES) {
        [self setUpRest];
    }
    
    if ( useSideViewFrames == YES) {
        [self setUpWalkSide];
    }
    
    if ( useBackViewFrames == YES ) {
        [self setUpWalkBack];
    }
    
    if ( useFrontViewFrames == YES ) {
        [self setUpWalkFront];
    }
    
    if ( useBackAttackFrames == YES ) {
        [self setUpBackAttackFrames];
    }
    
    if ( useSideAttackFrames == YES ) {
        [self setUpSideAttackFrames];
    }
    
    if ( useFrontAttackFrames == YES ) {
        [self setUpFrontAttackFrames];
    }
    
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
        self.xScale = 0.75;
        self.yScale = 0.75;
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

#pragma mark - Rest / Walk Frames
-(void)setUpRest{
    
    /**
     動畫效果設定
     */
    
    // 設定 SKTestureAtlas 的MFDHCG0000027537  
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"RestingAtlasFile"]];
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"RestingFrames"]];
    
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    SKAction *wait = [SKAction waitForDuration:0.5f];
    SKAction *sequence = [SKAction sequence:@[atlasAnimation , wait ]];
    repeatRest = [SKAction repeatActionForever:sequence];
    
}

-(void)setUpWalkFront{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"WalkFrontAtlasFile"]];
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"WalkFrontFrames"]];
    
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    walkFrontAction = [SKAction repeatActionForever:atlasAnimation];
}

-(void)setUpWalkBack{
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"WalkBackAtlasFile"]];
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"WalkBackFrames"]];
    
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    walkBackAction = [SKAction repeatActionForever:atlasAnimation];
}

-(void)setUpWalkSide{
    
    // 取得 atlas 圖片集合（其實是一個圖片資料夾）
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"WalkSideAtlasFile"]];
    // 取得動畫圖片的檔案名稱（有順序性，所以才能組合成連續圖片變成動畫）
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"WalkSideFrames"]];
    
    // 建立一個陣列，陣列內將會依照順序拿來存一張張的動畫圖片
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    // 存入動畫圖片
    unsigned char count = 0;
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    // 既練一個 SKAction ，然後展示動畫
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    walkSideAction = [SKAction repeatActionForever:atlasAnimation];
    
}

#pragma mark - Attack Frames
-(void)setUpBackAttackFrames{
    
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"BackAttackAtlasFile"]];
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"BackAttackFrames"]];
    
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    
    if ( useBackViewFrames == YES ) {
        SKAction *returnToWalking = [SKAction performSelector:@selector(runWalkBackTextures) onTarget:self];
        backAttackAction = [SKAction sequence:@[atlasAnimation , returnToWalking]];
    }
    else{
        backAttackAction = [SKAction repeatAction:atlasAnimation count:1];
    }
    
}

-(void)setUpSideAttackFrames{
    
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"SideAttackAtlasFile"]];
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"SideAttackFrames"]];
    
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    
    if ( useSideViewFrames == YES ) {
        SKAction *returnToWalking = [SKAction performSelector:@selector(runWalkSideTextures) onTarget:self];
        sideAttackAction = [SKAction sequence:@[atlasAnimation , returnToWalking]];
    }
    else{
        sideAttackAction = [SKAction repeatAction:atlasAnimation count:1];
    }
    
}

-(void)setUpFrontAttackFrames{
    
    SKTextureAtlas *atlas = [SKTextureAtlas atlasNamed:[characterData objectForKey:@"FrontAttackAtlasFile"]];
    NSArray *array = [NSArray arrayWithArray:[characterData objectForKey:@"FrontAttackFrames"]];
    
    NSMutableArray *atlasTextures = [NSMutableArray arrayWithCapacity:[array count]];
    
    unsigned char count = 0;
    
    for ( id object in array ) {
        SKTexture *texture = [atlas textureNamed:[array objectAtIndex:count]];
        [atlasTextures addObject:texture];
        count++;
    }
    
    SKAction *atlasAnimation = [SKAction animateWithTextures:atlasTextures timePerFrame:(1.0/fps)];
    
    if ( useFrontViewFrames == YES ) {
        SKAction *returnToWalking = [SKAction performSelector:@selector(runWalkFrontTextures) onTarget:self];
        frontAttackAction = [SKAction sequence:@[atlasAnimation , returnToWalking]];
    }
    else{
        frontAttackAction = [SKAction repeatAction:atlasAnimation count:1];
    }
    
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








