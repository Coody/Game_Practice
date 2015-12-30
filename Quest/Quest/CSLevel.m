//
//  CSLevel.m
//  Quest
//
//  Created by CoodyChou on 2015/12/30.
//  Copyright © 2015年 CoodyChou. All rights reserved.
//

#import "CSLevel.h"

@interface CSLevel(){
    SKNode *myWorld;
}
@end

@implementation CSLevel

-(id)initWithSize:(CGSize)size{
    if ( self = [super initWithSize:size] ) {
        
        [self setUpScene];
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
    
    
    
}

-(void)update:(NSTimeInterval)currentTime{
    
}

@end
