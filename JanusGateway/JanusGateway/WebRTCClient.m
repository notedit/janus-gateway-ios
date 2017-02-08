//
//  WebRTCClient.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "WebRTCClient.h"


#import "WebRTCSignaling.h"
#import "WebRTCStream.h"



NSString* kWebsocketServerURL = @"";

@interface WebRTCClient () <WebRTCSignalingDelegate,RTCPeerConnectionDelegate>
{
    RTCMediaConstraints*  _mediaConstraints;
    RTCPeerConnectionFactory *_peerConnectionFactory;
    RTCAudioTrack*  _localAudioTrack;
    RTCVideoTrack*  _localVideoTrack;
    WebRTCSignaling* _signalingChannel;
    
    uint64_t  _room;
    uint64_t  _localUserid;
    
    // for local test
    uint64_t  _session;
    uint64_t  _handle;
    RTCPeerConnection* _peerConnection;
    WebRTCStream*  _localStream;
    
}

@end


@implementation WebRTCClient


-(instancetype)initWithDelegate:(id<WebRTCClientDelegate>)delegate
{
    
   
    self = [super init];
    _delegate = delegate;
    _handleMap = [[NSMutableDictionary alloc] init];
    _state = kClientStateDisconnected;
    _peerConnectionFactory = [[RTCPeerConnectionFactory alloc] init];
    _signalingChannel = [[WebRTCSignaling alloc] initWithURL:kWebsocketServerURL delegate:self];
    return self;
}


-(void)setCameraConstraints:(RTCMediaConstraints *)constraints
{
    _mediaConstraints = constraints;
}

-(void)startLocalMedia
{
    
    if (!self.localMediaStream) {
        _localMediaStream = [_peerConnectionFactory mediaStreamWithStreamId:[[NSUUID UUID] UUIDString]];
    }
    
    if (_localAudioTrack == nil) {
        _localAudioTrack = [_peerConnectionFactory audioTrackWithTrackId:@"Auido"];
        
        [_delegate client:self didReceiveLocalAudioTrack:_localAudioTrack];
    }
    
    if (_localVideoTrack == nil) {
        RTCAVFoundationVideoSource *videosource = [_peerConnectionFactory avFoundationVideoSourceWithConstraints:[self videoConstraints]];
        
        _localVideoTrack = [_peerConnectionFactory videoTrackWithSource:videosource trackId:@"Video"];
        [_delegate client:self didReceiveLocalVideoTrack:_localVideoTrack];
    }
    
    [_localMediaStream addAudioTrack:_localAudioTrack];
    [_localMediaStream addVideoTrack:_localVideoTrack];
    
    
}


-(void)stopLocalMedia
{
    if (self.localMediaStream) {
        [_delegate client:self didRemoveLocalVideoTrack:_localVideoTrack];
        [_delegate client:self didRemoveLocalAudioTrack:_localAudioTrack];
        
        _localVideoTrack = nil;
        _localAudioTrack = nil;
        _localMediaStream = nil;
    }
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
    _localUserid = user;
    
    [_signalingChannel connect];
    
    _state = kClientStateConnecting;
}


-(void)leaveRoom
{
    
    if (_state == kClientStateDisconnected) {
        return;
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
                                           @"OfferToReceiveAudio":@"false",
                                           @"OfferToReceiveVideo":@"false"
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
                              @"session":[NSNumber numberWithUnsignedLongLong:session],
                              @"type":@"join",
                              @"room": [NSNumber numberWithUnsignedLongLong:room],
                              @"data":@{
                                      @"room":[NSNumber numberWithUnsignedLongLong:room],
                                      @"userid":[NSNumber numberWithUnsignedLongLong:user],
                                      @"role":role,
                                      },
                              };
    
    [_signalingChannel sendMessage:message];
}


-(void)publish
{
    
    _peerConnection = [_peerConnectionFactory peerConnectionWithConfiguration:[self rtcConfiguration]
                                                                  constraints:[self connectionConstraints] delegate:self];
    
    [_peerConnection offerForConstraints:[self offerConstraints] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        
        [_peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            
            if (error != nil){
                NSLog(@"setLocalDescription error %@", [error localizedDescription]);
                return;
            }
            
            NSDictionary* message = @{
                                      @"session":[NSNumber numberWithUnsignedLongLong:_session],
                                      @"handle":[NSNumber numberWithUnsignedLongLong:_handle],
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


-(void)onPublished:(NSDictionary *)message
{
    NSDictionary* sdp = [message valueForKeyPath:@"data.sdp"];
    if (!sdp) {
        NSLog(@"error: can not find sdp in message");
        return;
    }
    
    RTCSessionDescription* _sdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:[sdp objectForKey:@"sdp"]];
    
    [_peerConnection setLocalDescription:_sdp completionHandler:^(NSError * _Nullable error) {
        if (error != nil) {
            NSLog(@"error: set answer sdp error ");
            return;
        }
    }];
    
}



-(void)trickleCandidate:(NSDictionary*)candidate
{
    
    NSDictionary* message = @{
                              @"session":[NSNumber numberWithUnsignedLongLong:_session],
                              @"handle":[NSNumber numberWithUnsignedLongLong:_handle],
                              @"type":@"ice",
                              @"room": [NSNumber numberWithUnsignedLongLong:_room],
                              @"data":@{
                                      @"candidate":candidate,
                                      },
                              };
    
    [_signalingChannel sendMessage:message];
}


-(void)unpublish
{
    
    NSDictionary* message = @{
                              @"session":[NSNumber numberWithUnsignedLongLong:_session],
                              @"handle":[NSNumber numberWithUnsignedLongLong:_handle],
                              @"type":@"unpublish",
                              @"room": [NSNumber numberWithUnsignedLongLong:_room],
                              @"data":@{
                                      },
                              };
    
    [_signalingChannel sendMessage:message];
}

#pragma delegate


-(void)channel:(WebRTCSignaling *)channel didReceiveMessage:(NSDictionary *)data
{
    
    NSString* type = [data objectForKey:@"type"];
    
    
    
    if ([type isEqualToString:@"created"]) {
        // session is created
        NSNumber* sessionID = [data objectForKey:@"session"];
        _session = [sessionID unsignedLongLongValue];
        // ok now  we can join
        [self joinWithRoom:_room user:_localUserid role:@"publisher" session:_session];
    }
    
    if ([type  isEqualToString: @"joined"]) {
        // now  we have handle we can publish
        NSNumber* handleID = [data objectForKey:@"handle"];
        _handle = [handleID unsignedLongLongValue];
        
        [self publish];
        
        
    } else if([type isEqualToString:@"attached"]){
        // here create a remote stream
        
        
    } else if([type isEqualToString:@"leaved"]){
        
        
    } else if([type isEqualToString:@"published"]){
        // here we got answer sdp
        
        
    } else if([type isEqualToString:@"unpublished"]){
        
        
    } else if([type isEqualToString:@"subcribed"]) {
        
        
    }
}


-(void)channel:(WebRTCSignaling *)channel didChangeState:(WebRTCSignalingState)signalingState
{
    if (signalingState == kSignalingStateOpen) {
        // 不处理
        
    } else if(signalingState == kSignalingStateClosed) {
        
        
        
    } else if(signalingState == kSignalingStateError) {
        
        // notify  
        
    }
}



#pragma 


/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeSignalingState:(RTCSignalingState)stateChanged
{
    NSLog(@"didChangeSignalingState ");
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream
{


}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream
{


}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{


}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceConnectionState:(RTCIceConnectionState)newState
{


}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didChangeIceGatheringState:(RTCIceGatheringState)newState
{


}

/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    
    NSDictionary* ice = @{
                          @"candidate":candidate.sdp,
                          @"sdpMid":candidate.sdpMid,
                          @"sdpMlineIndex":@(candidate.sdpMLineIndex),
                          };
    
    [self trickleCandidate:ice];

}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{


}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
    didOpenDataChannel:(RTCDataChannel *)dataChannel
{



}

@end
