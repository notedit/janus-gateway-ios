//
//  WebRTCSignaling.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "WebRTCSignaling.h"




@interface WebRTCSignaling () <SRWebSocketDelegate>
@end

@implementation WebRTCSignaling {
    NSString* _url;
    SRWebSocket *_socekt;
}

-(instancetype)initWithURL:(NSString *)url delegate:(id<WebRTCSignalingDelegate>)delegate
{
    
    self = [super init];
    _delegate = delegate;
    _url = url;
    _socekt = [[SRWebSocket alloc] initWithURL:[NSURL URLWithString:_url]];
    _socekt.delegate = self;
    return self;
}


- (void)setState:(WebRTCSignalingState)state {
    if (_state == state) {
        return;
    }
    _state = state;
    [_delegate channel:self didChangeState:_state];
}


-(void)connect
{
    [_socekt open];
}


-(void)disconnect
{
    if (_state == kSignalingStateClosed || _state == kSignalingStateError) {
        return;
    }
    [_socekt close];
    
    [self setState:kSignalingStateClosed];
    
}

-(void)dealloc
{
    [self disconnect];
}


-(void)sendMessage:(NSDictionary *)message
{
    
    if (_state != kSignalingStateOpen) {
        return;
    }
    
}


#pragma mark  - SRWebSocketDelegate

-(void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.state = kSignalingStateOpen;
}

-(void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSString *messageString = message;
    NSData *messageData = [messageString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:messageData
                                                    options:0
                                                      error:nil];
    if (![jsonObject isKindOfClass:[NSDictionary class]]) {
        return;
    }
    
    NSDictionary *wssMessage = jsonObject;
    [self.delegate channel:self didReceiveMessage:wssMessage];
    
}

-(void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    self.state = kSignalingStateError;
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.state = kSignalingStateClosed;
}

@end






















