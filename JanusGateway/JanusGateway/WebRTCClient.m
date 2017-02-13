//
//  WebRTCClient.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "WebRTCClient.h"


#import "WebRTCSignaling.h"
#import "WebRTCPeer.h"



static NSString * const kMediaStreamId = @"ARDAMS";


NSString* kWebsocketServerURL = @"ws://101.201.141.179:9000/ws";

@interface WebRTCClient () <WebRTCSignalingDelegate,RTCPeerConnectionDelegate,WebRTCPeerDelegate>
{
    RTCMediaConstraints*  _mediaConstraints;
    RTCPeerConnectionFactory *_peerConnectionFactory;
    RTCAudioTrack*  _localAudioTrack;
    RTCVideoTrack*  _localVideoTrack;
    WebRTCSignaling* _signalingChannel;
    
    uint64_t  _room;
    
    // for local test
    uint64_t  _session;
    
}

@end


@implementation WebRTCClient


-(instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate
{
    
   
    self = [super init];
    _delegate = delegate;
    _state = kClientStateDisconnected;
    _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    _signalingChannel = [[WebRTCSignaling alloc] initWithURL:kWebsocketServerURL delegate:self];
    _peers = [[NSMutableDictionary alloc] init];
    _localPeer = [[WebRTCPeer alloc] initWithDelegate:self];
    return self;
}


-(void)startLocalMedia
{
    if (!self.localMediaStream) {
        _localMediaStream = [_peerConnectionFactory mediaStreamWithStreamId:kMediaStreamId];
    }
    
    if (_localAudioTrack == nil) {
        _localAudioTrack = [_peerConnectionFactory audioTrackWithTrackId:@"Auido"];
        [_localMediaStream addAudioTrack:_localAudioTrack];
    }
    
    if (_localVideoTrack == nil) {
        RTCAVFoundationVideoSource *videosource = [_peerConnectionFactory avFoundationVideoSourceWithConstraints:[self videoConstraints]];
        
        _localVideoTrack = [_peerConnectionFactory videoTrackWithSource:videosource trackId:@"Video"];
        [_localMediaStream addVideoTrack:_localVideoTrack];
        
        _localPeer.localStream = _localMediaStream;
        
        [_localPeer.localStream.videoTracks[0] addRenderer:_localPeer.view];
        
        if ([_delegate respondsToSelector:@selector(client:didReceiveLocalVideo:)]) {
            [_delegate client:self didReceiveLocalVideo:_localPeer];
        }
    }
    
}


-(void)stopLocalMedia
{
    if (self.localMediaStream) {
        
        [_localVideoTrack removeRenderer:_localPeer.view];
        [_delegate client:self didRemoveLocalVideo:_localPeer];
        
        _localVideoTrack = nil;
        _localAudioTrack = nil;
        _localMediaStream = nil;
    }
}


-(void)sendMessage:(NSDictionary *)message
{
    

}


-(void)joinRoomWith:(uint64_t)room userid:(uint64_t)user
{
    
    if (_state == kClientStateConnected) {
        return;
    }
    
    if (!_localMediaStream) {
        [self startLocalMedia];
    }
    
    _room = room;
    _localPeer.userID = user;
    
    [_signalingChannel connect];
    
    _state = kClientStateConnecting;
}


-(void)leaveRoom
{
    
    if (_state == kClientStateDisconnected) {
        return;
    }
    
    [self internalLeave];
    
}


-(void)internalLeave
{
    
    // lcoal send leave
    
    [self leave:_localPeer];
    
    // remote send leave
    for (WebRTCPeer* peer in _peers) {
        [self leave:peer];
    }
    
    
    [_signalingChannel disconnect];
    
}


#pragma internal function 

-(RTCConfiguration *) rtcConfiguration
{
    RTCConfiguration* config = [[RTCConfiguration alloc] init];
    RTCIceServer* server = [[RTCIceServer alloc] initWithURLStrings:@[@"stun:101.201.141.179:3478"]];
    config.iceServers = @[server];
    
    // more config
    return config;
}

- (RTCMediaConstraints *)offerConstraints
{
    NSDictionary *optional = @{@"VoiceActivityDetection":@"true"};
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio":@"true",
                                           @"OfferToReceiveVideo":@"true"
                                           };
    
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:mandatoryConstraints
                                        optionalConstraints:optional];
    
    return constraints;
}



-(RTCMediaConstraints *)answerConstraints
{
    NSDictionary *mandatoryConstraints = @{
                                           @"OfferToReceiveAudio":@"true",
                                           @"OfferToReceiveVideo":@"true"
                                           };
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:mandatoryConstraints
                                        optionalConstraints:nil];
    return constraints;
}


-(RTCMediaConstraints *)videoConstraints
{
    
    NSDictionary *videoConstraints = @{
                                       @"maxWidth":[NSString stringWithFormat:@"%d", 1280],
                                       @"maxHeight":[NSString stringWithFormat:@"%d", 1280],
                                       @"minWidth":[NSString stringWithFormat:@"%d", 180],
                                       @"minHeight":[NSString stringWithFormat:@"%d", 180],
                                       @"minFrameRate":[NSString stringWithFormat:@"%d", 15],
                                       @"maxFrameRate":[NSString stringWithFormat:@"%d", 20]
                                       };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:videoConstraints
                                        optionalConstraints:nil];
    return constraints;

}


- (RTCMediaConstraints *)connectionConstraints
{
    
    
    NSDictionary *optionalConstraints = @{
                                          @"DtlsSrtpKeyAgreement":@"true",
                                          @"googSuspendBelowMinBitrate":@"false",
                                          @"googCombinedAudioVideoBwe":@"true"
                                          };
    
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc]
                                        initWithMandatoryConstraints:nil
                                        optionalConstraints:optionalConstraints];
    
    return constraints;
}





-(void)joinWithRoom:(uint64_t)room user:(uint64_t)user role:(NSString*)role  session:(uint64_t)session
{
    NSDictionary* message = @{
                              @"session":[NSNumber numberWithUnsignedLongLong:_session],
                              @"type":@"join",
                              @"room": [NSNumber numberWithUnsignedLongLong:_room],
                              @"data":@{
                                      @"room":[NSNumber numberWithUnsignedLongLong:room],
                                      @"userid":[NSNumber numberWithUnsignedLongLong:user],
                                      @"role":role,
                                      },
                              };
    
    [_signalingChannel sendMessage:message];
}


-(void)publish:(WebRTCPeer*)localPeer
{
    
    _localPeer.peerconnection = [_peerConnectionFactory
                                 peerConnectionWithConfiguration:[self rtcConfiguration]
                                                                            constraints:[self connectionConstraints] delegate:_localPeer];
    
    [_localPeer.peerconnection addStream:_localMediaStream];
    
    
    [_localPeer.peerconnection offerForConstraints:[self offerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
        
        if (error!= nil) {
            NSLog(@"offerForConstraints error %@", error);
            return;
        }
        
        [_localPeer.peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            
            if (error != nil){
                NSLog(@"setLocalDescription error %@", [error localizedDescription]);
                return;
            }
            
            NSDictionary* message = @{
                                      @"session":[NSNumber numberWithUnsignedLongLong:_session],
                                      @"handle":[NSNumber numberWithUnsignedLongLong:_localPeer.handleID],
                                      @"type":@"publish",
                                      @"room": [NSNumber numberWithUnsignedLongLong:_room],
                                      @"data":@{
                                              @"media":@{@"audio":@TRUE,@"video":@TRUE},
                                              @"sdp":@{
                                                      @"type":@"offer",
                                                      @"sdp":sdp.sdp,
                                                      },
                                              },
                                      };
            
            [_signalingChannel sendMessage:message];
        }];
        
    }];
    
}



-(void)newRemoteFeed:(uint64_t)userid
{
    //todo need to check local
    [self.delegate client:self didJoin:userid];
    
    // create remote feed
    WebRTCPeer* webrtcPeer = [[WebRTCPeer alloc] initWithDelegate:self];
    webrtcPeer.userID = userid;
    [_peers setObject:webrtcPeer forKey:[NSNumber numberWithUnsignedLongLong:userid]];
    
    webrtcPeer.peerconnection = [_peerConnectionFactory
                                 peerConnectionWithConfiguration:[self rtcConfiguration]
                                 constraints:[self connectionConstraints] delegate:webrtcPeer];
    
    NSDictionary* message = @{
                              @"session":[NSNumber numberWithUnsignedLongLong:_session],
                              @"type":@"attach",
                              @"room": @1234,
                              @"data":@{
                                      @"room":[NSNumber numberWithUnsignedLongLong:_room],
                                      @"userid":[NSNumber numberWithUnsignedLongLong:userid],
                                      @"role":@"listener",
                                    },
                              
                              };
    
    [_signalingChannel sendMessage:message];
    
}


-(void)removeRemoteFeed:(uint64_t)userid
{
    
    [self.delegate client:self didLeave:userid];
    
    WebRTCPeer* webrtcPeer = [_peers objectForKey:[NSNumber numberWithUnsignedLongLong:userid]];
    
    if (!webrtcPeer) {
        return;
    }
    [_peers removeObjectForKey:[NSNumber numberWithUnsignedLongLong:userid]];
    [webrtcPeer leave];
    //  todo  check if we need to remove the view;
    
}


-(void)subcribe:(WebRTCPeer*)peer withSDP:(RTCSessionDescription*)sdp
{
    
    __weak WebRTCClient * weakSelf = self;
    [peer.peerconnection setRemoteDescription:sdp completionHandler:^(NSError * _Nullable error) {
        
        if (error != nil) {
            NSLog(@"error  can not set remote offer sdp %@", error);
            return;
        }
        
        [peer answerWithConstraints:[weakSelf answerConstraints] Block:^(RTCSessionDescription *sdp, NSError *error) {
            
            if(error!= nil){
                NSLog(@"can not generate answer sdp %@", error);
                return;
            }
            
            [peer.peerconnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                
                if (error != nil) {
                    NSLog(@"error can not set local answer %@", error);
                    return;
                }
                
                NSDictionary* message = @{
                                          @"session":[NSNumber numberWithUnsignedLongLong:_session],
                                          @"handle":[NSNumber numberWithUnsignedLongLong:peer.handleID],
                                          @"type":@"subcribe",
                                          @"room":[NSNumber numberWithUnsignedLongLong:_room],
                                          @"data":@{
                                                  @"sdp":@{
                                                          @"type":@"answer",
                                                          @"sdp":sdp.sdp,
                                                          }
                                                  },
                                          };
                
                [_signalingChannel sendMessage:message];
            
            }];
            
        }];
        
    }];
    

}




-(void)trickleCandidate:(WebRTCPeer*)peer  candidate:(RTCIceCandidate*)candidate
{

    NSDictionary* ice = @{
                          @"candidate":candidate.sdp,
                          @"sdpMid":candidate.sdpMid,
                          @"sdpMLineIndex":@(candidate.sdpMLineIndex),
                          };
    
    
    NSDictionary* message = @{
                              @"session":[NSNumber numberWithUnsignedLongLong:_session],
                              @"handle":[NSNumber numberWithUnsignedLongLong:peer.handleID],
                              @"type":@"ice",
                              @"room": [NSNumber numberWithUnsignedLongLong:_room],
                              @"data":@{
                                      @"candidate":ice,
                                      },
                              };
    
    [_signalingChannel sendMessage:message];
    
    
}



-(void)unpublish:(WebRTCPeer*)peer
{
    // 暂时不实现
    // not for now
    
}


-(void) unsubcribe:(WebRTCPeer*)peer
{
    
    // 暂时不实现
    // not for now
}


-(void)leave:(WebRTCPeer*)peer
{
    
    [peer leave];
    
    NSDictionary* message = @{
                              @"session":[NSNumber numberWithUnsignedLongLong:_session],
                              @"handle":[NSNumber numberWithUnsignedLongLong:peer.handleID],
                              @"type":@"leave",
                              @"room": [NSNumber numberWithUnsignedLongLong:_room],
                              @"data":@{
                                      },
                              };
    
    [_signalingChannel sendMessage:message];
    
}

#pragma delegate


-(void)channel:(WebRTCSignaling *)channel didReceiveMessage:(NSDictionary *)data
{
    NSLog(@"didReceiveMessage %@", data);
    
    NSString* type = [data objectForKey:@"type"];
    
    if ([type isEqualToString:@"created"]) {
        // session is created
        NSNumber* sessionID = [data objectForKey:@"session"];
        _session = [sessionID unsignedLongLongValue];
        // ok now  we can join
        [self joinWithRoom:_room user:_localPeer.userID role:@"publisher" session:_session];

    }
    
    if ([type  isEqualToString: @"joined"]) {
        // now  we have handle we can publish
        NSNumber* handleID = [data objectForKey:@"handle"];
        _localPeer.handleID = [handleID unsignedLongLongValue];
        
        if ([_delegate respondsToSelector:@selector(client:didJoin:withHandleID:)]) {
            [_delegate client:self didJoin:_localPeer.userID];
        }
        
        [self publish:_localPeer];
        
        NSArray* publishers = [data valueForKeyPath:@"data.publishers"];
        
        if (!publishers) {
            return;
        }
        
        for (NSDictionary* publisher in publishers) {
            NSNumber* userid = [publisher objectForKey:@"id"];
            if (userid) {
                [self newRemoteFeed:[userid unsignedLongLongValue]];
            }
        }
        
    } else if([type isEqualToString:@"attached"]){
        // here create a remote stream
        NSNumber* handleID = [data objectForKey:@"handle"];
        NSNumber* userID = [data valueForKeyPath:@"data.userid"];
        NSDictionary* sdp = [data valueForKeyPath:@"data.sdp"];
        
        
        if (sdp && userID && [_peers objectForKey:userID]) {
            RTCSessionDescription* _sdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:[sdp objectForKey:@"sdp"]];
            
            WebRTCPeer* peer = [_peers objectForKey:userID];
            peer.handleID = [handleID unsignedLongLongValue];
            [self subcribe:peer withSDP:_sdp];
        }
        
        
    } else if ([type isEqualToString:@"publishers"]) {
        // new publisher
        NSNumber* handleID = [data objectForKey:@"handle"];
        NSNumber* userID = [data valueForKeyPath:@"data.userid"];
        
        NSArray* publishers = [data valueForKeyPath:@"data.publishers"];
        
        if (!publishers) {
            return;
        }
        
        for (NSDictionary* publisher in publishers) {
            NSNumber* userid = [publisher objectForKey:@"id"];
            if (userid) {
               
                [self newRemoteFeed:[userid unsignedLongLongValue]];
            }
        }
    
    } else if ([type isEqualToString:@"leaving"]){
        // some body leaving
        NSNumber*  userid = [data objectForKey:@"data.leaving"];
        if (userid){
            [self removeRemoteFeed:[userid unsignedLongLongValue]];
        }
        
        
    } else if([type isEqualToString:@"leaved"]){
        
        NSLog(@"we just do not handle this");
        
    } else if([type isEqualToString:@"published"]){
        // here we got answer sdp
        //NSNumber* handleID = [data objectForKey:@"handle"];
        NSDictionary* sdp = [data valueForKeyPath:@"data.sdp"];
        if (sdp == nil) {
            NSLog(@"event published can not find sdp");
            return;
        }
        NSString* sdpStr = [sdp objectForKey:@"sdp"];
        RTCSessionDescription* _sdp = [[RTCSessionDescription alloc]
                                       initWithType:RTCSdpTypeAnswer sdp:sdpStr];
        
        [_localPeer.peerconnection setRemoteDescription:_sdp completionHandler:^(NSError * _Nullable error) {
            if (error != nil) {
                NSLog(@"setRemoteDescription answer error %@", error);
                return;
            }
            
        }];
        
    } else if([type isEqualToString:@"unpublished"]){
        
        NSLog(@"does not have");
        
    } else if([type isEqualToString:@"subcribed"]) {
        
        NSLog(@"does not have");
        
    }
}


-(void)channel:(WebRTCSignaling *)channel didChangeState:(WebRTCSignalingState)signalingState
{
    if (signalingState == kSignalingStateOpen) {
        
        
    } else if(signalingState == kSignalingStateClosed) {
        
        
    } else if(signalingState == kSignalingStateError) {
        
    }
}



#pragma


-(void)peer:(WebRTCPeer*)peer didReceiveRemoteVideo:(RTCVideoTrack*)track
{
    
    NSLog(@"peer userid %llu didReceiveRemoteVideo", peer.userID);

    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [track addRenderer:peer.view];
        [self.delegate client:self didReceiveRemoteVideo:peer];
        
    });

}

-(void)peer:(WebRTCPeer*)peer didRemoveRemoteVideo:(RTCVideoTrack*)track
{
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        [track removeRenderer:peer.view];
        [self.delegate client:self didRemoveRemoteVideo:peer];
        
    });
    

    NSLog(@"peer userid %llu didRemoveRemoteVideo", peer.userID);
    
}

-(void)peer:(WebRTCPeer*)peer didOccurError:(NSInteger*)errorCode
{

    
}

-(void)peer:(WebRTCPeer*)peer didGotCandidate:(RTCIceCandidate*)candidate
{
    
    [self trickleCandidate:peer candidate:candidate];

}


@end
