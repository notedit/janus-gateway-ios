//
//  WebRTCSignaling.m
//  JanusGateway
//
//  Created by xiang on 07/02/2017.
//  Copyright © 2017 dotEngine. All rights reserved.
//

#import "WebRTCSignaling.h"

static NSTimeInterval kXSPeerClientKeepaliveInterval = 10.0;


@interface WebRTCSignaling () <SRWebSocketDelegate>

@property (nonatomic, strong) NSTimer* presenceKeepAliveTimer;


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
    NSError *error;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:message
                                                       options:NSJSONWritingPrettyPrinted // Pass 0 if you don't care about the readability of the generated string
                                                         error:&error];
    
    if (! jsonData) {
        NSLog(@"Got an error: %@", error);
    } else {
        NSString *jsonString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        [_socekt send:jsonString];
    }
}


#pragma mark  - SRWebSocketDelegate

-(void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    self.state = kSignalingStateOpen;
    
    [self scheduleTimer];
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
    NSLog(@"didFailWithError %@", error);
    [self invalidateTimer];
    
}

-(void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    self.state = kSignalingStateClosed;
    NSLog(@"didCloseWithCode %@", reason);
    [self invalidateTimer];
    
}




- (void)scheduleTimer
{
    [self invalidateTimer];
    
    NSTimer *timer = [NSTimer timerWithTimeInterval:kXSPeerClientKeepaliveInterval target:self selector:@selector(handleTimer:) userInfo:nil repeats:NO];
    
    [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];
    
    self.presenceKeepAliveTimer = timer;
}


- (void)invalidateTimer
{
    [self.presenceKeepAliveTimer invalidate];
    self.presenceKeepAliveTimer = nil;
}

- (void)handleTimer:(NSTimer *)timer
{
    [self sendPing];
    
    [self scheduleTimer];
}

- (void)sendPing
{
    [_socekt sendPing:nil];
}


@end






















