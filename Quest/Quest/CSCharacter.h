//
//  CSCharacter.h
//  Quest
//
//  Created by CoodyChou on 2015/12/31.
//  Copyright © 2015年 CoodyChou. All rights reserved.
//

#import <SpriteKit/SpriteKit.h>

@interface CSCharacter : SKNode

-(void)createWithDictionary:(NSDictionary *)charData;

// update 1/30 per second
-(void)update;

// move
-(void)moveLeftWithPlace:(NSNumber *)place;
-(void)moveRightWithPlace:(NSNumber *)place;
-(void)moveDownWithPlace:(NSNumber *)place;
-(void)moveUpWithPlace:(NSNumber *)place;

@end
