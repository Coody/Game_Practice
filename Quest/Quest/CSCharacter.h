//
//  CSCharacter.h
//  Quest
//
//  Created by CoodyChou on 2015/12/31.
//  Copyright © 2015年 CoodyChou. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface CSCharacter : SKNode


@property (nonatomic , assign) int idealX;
@property (nonatomic , assign) int idealY;
@property (nonatomic , assign) BOOL theLeader;


//
-(void)createWithDictionary:(NSDictionary *)charData;

// update 1/30 per second
-(void)update;

// move
-(void)moveLeftWithPlace:(NSNumber *)place;
-(void)moveRightWithPlace:(NSNumber *)place;
-(void)moveDownWithPlace:(NSNumber *)place;
-(void)moveUpWithPlace:(NSNumber *)place;

-(void)makeLeader;

@end
