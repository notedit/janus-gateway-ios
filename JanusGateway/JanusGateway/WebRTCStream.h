//
//  WebRTCStream.h
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <WebRTC/WebRTC.h>

@interface WebRTCStream : NSObject

@property(nonatomic)  uint64_t userID;
@property(nonatomic)  uint64_t handleID;
@property(nonatomic)  uint64_t sessionID;
@property(nonatomic,readonly) NSString* role;
@property(nonatomic,strong) RTCPeerConnection *peerconnection;
@property(nonatomic,strong) RTCEAGLVideoView  *view;


@end
