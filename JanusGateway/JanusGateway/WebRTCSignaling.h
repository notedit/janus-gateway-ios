//
//  WebRTCSignaling.h
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <SocketRocket.h>

@class WebRTCSignaling;


typedef NS_ENUM(NSInteger, WebRTCSignalingState) {
    // State when disconnected.
    kSignalingStateClosed,
    // State when connection is established.
    kSignalingStateOpen,
    // State when connection encounters a fatal error.
    kSignalingStateError
};


@protocol WebRTCSignalingDelegate <NSObject>


-(void)channel:(WebRTCSignaling *)channel didChangeState:(WebRTCSignalingState) state;

-(void)channel:(WebRTCSignaling *)channel didReceiveMessage:(NSDictionary *)data;

@end


@interface WebRTCSignaling : NSObject

@property(nonatomic,readonly) WebRTCSignalingState state;
@property(nonatomic,weak) id<WebRTCSignalingDelegate> delegate;


-(instancetype) initWithURL:(NSString*)url  delegate:(id<WebRTCSignalingDelegate>)delegate;


-(void)connect;

-(void)disconnect;

-(void)sendMessage:(NSDictionary*)message;

@end
