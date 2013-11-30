/**
 * Copyright (C) 2013 Packet7, LLC.
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
 *
 * See the GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 */

#include <grapevine/stack.hpp>

#import "GVStack.h"

NSString * kGVDidConnectNotification = @"gvDidConnectNotification";
NSString * kGVDidDisconnectNotification = @"gvDidDisconnectNotification";
NSString * kGVDidSignInNotification = @"gvDidSignInNotification";
NSString * kGVDidFindMessageNotification = @"gvDidFindMessageNotification";
NSString * kGVDidFindProfileNotification = @"gvDidFindProfileNotification";
NSString * kGVOnVersionNotification = @"gvOnVersionNotification";

static NSMutableArray * gIncomingMessageQueue = nil;

void process_incoming_queue()
{
    @autoreleasepool
    {
        @synchronized (gIncomingMessageQueue)
        {
            NSDictionary * dict = [gIncomingMessageQueue lastObject];
            
            dispatch_async(dispatch_get_main_queue(),^
            {
                [[NSNotificationCenter defaultCenter]
                    postNotificationName:kGVDidFindMessageNotification
                    object:dict
                ];
            });
            
            [gIncomingMessageQueue removeObjectAtIndex:
                gIncomingMessageQueue.count - 1
            ];
            
            if (gIncomingMessageQueue.count > 0)
            {
                int64_t delta = (int64_t)(1.0e9 * 0.10f);
      
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta),
                dispatch_get_current_queue(), ^
                {
                    process_incoming_queue();
                });
            }
        }
    }
}

class my_grapevine_stack : public grapevine::stack
{
    public:
    
        /**
         * Called when connected to the network.
         * @param addr The address.
         * @param port The port.
         */
        virtual void on_connected(
            const char * addr, const std::uint16_t & port
            )
        {
            @autoreleasepool
            {
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];
                
                dispatch_async(dispatch_get_main_queue(),^
                {
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:kGVDidConnectNotification
                        object:dict
                    ];
                });
            }
        }
    
        /**
         * Called when disconnected from the network.
         * @param addr The address.
         * @param port The port.
         */
        virtual void on_disconnected(
            const char * addr, const std::uint16_t & port
            )
        {
            @autoreleasepool
            {
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];
                
                dispatch_async(dispatch_get_main_queue(),^
                {
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:kGVDidDisconnectNotification
                        object:dict
                    ];
                });
            }
        }
    
        virtual void on_sign_in(const std::string & status)
        {
            @autoreleasepool
            {
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];

                [dict setObject:
                    [NSString stringWithUTF8String:status.c_str()]
                    forKey:@"status"
                ];
                
                dispatch_async(dispatch_get_main_queue(),^
                {
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:kGVDidSignInNotification
                        object:dict
                    ];
                });
            }
        }
    
        virtual void on_find_message(
            const std::uint16_t & transaction_id,
            const std::map<std::string, std::string> & pairs,
            const std::vector<std::string> & tags
            )
        {
            @autoreleasepool
            {
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];

                [dict setObject:
                    [NSString stringWithUTF8String:
                    std::to_string(transaction_id).c_str()]
                    forKey:@"transaction_id"
                ];
            
                for (auto & i : pairs)
                {
                    NSString * key = [NSString stringWithUTF8String:
                        i.first.c_str()
                    ];
                    NSString * val = [NSString stringWithUTF8String:
                        i.second.c_str()
                    ];
                    /**
                     * If the value is nil try decoding differently.
                     */
                    if (!val)
                    {
                        val = [[NSString alloc] initWithBytes:
                            i.second.data() length:i.second.size()
                            encoding:NSUnicodeStringEncoding
                        ];
                    }
                    
                    assert(val != nil);
                    
                    if (key && val)
                    {
                        if ([key isEqualToString:@"__t"])
                        {
                            NSDate * t = [NSDate
                                dateWithTimeIntervalSince1970:atoi(val.UTF8String)
                            ];
                            
                            [dict setObject:t forKey:@"__t"];
                        }
                        else if ([key isEqualToString:@"_l"])
                        {
                            NSDate * _l = [NSDate
                                dateWithTimeInterval:atoi(val.UTF8String)
                                sinceDate:[NSDate date]
                            ];
                            
                            [dict setObject:_l forKey:@"_l"];
                        }
                        else if ([key isEqualToString:@"_e"])
                        {
                            NSDate * _e = [NSDate
                                dateWithTimeInterval:atoi(val.UTF8String)
                                sinceDate:[NSDate date]
                            ];
                            
                            [dict setObject:_e forKey:@"_e"];
                        }
                        else if ([key isEqualToString:@"_t"])
                        {
                            NSDate * _t = [NSDate
                                dateWithTimeIntervalSince1970:atoi(val.UTF8String)
                            ];
                            
                            [dict setObject:_t forKey:@"_t"];
                        }
                        else
                        {
                            [dict setObject:val forKey:key];
                        }
                    }
                }
            
                NSMutableArray * tagsArray = [NSMutableArray array];
            
                for (auto & i : tags)
                {
                    [tagsArray
                        addObject:[NSString stringWithUTF8String:i.c_str()]
                    ];
                }
            
                [dict setObject:tagsArray forKey:@"tags"];
            
                BOOL wasEmpty = YES;
                
                @synchronized (gIncomingMessageQueue)
                {
                    if (!gIncomingMessageQueue)
                    {
                        gIncomingMessageQueue = [NSMutableArray new];
                    }
                    
                    wasEmpty = gIncomingMessageQueue.count == 0;
                    
                    [gIncomingMessageQueue insertObject:dict atIndex:0];            
                }
                
                if (wasEmpty)
                {
                    int64_t delta = (int64_t)(1.0e9 * 0.10f);
                    
                    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, delta),
                    dispatch_get_current_queue(), ^
                    {
                        process_incoming_queue();
                    });
                }
            }
        }
        
        virtual void on_find_profile(
            const std::uint16_t & transaction_id,
            const std::map<std::string, std::string> & pairs
            )
        {
            @autoreleasepool
            {
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];

                [dict setObject:
                    [NSString stringWithUTF8String:
                    std::to_string(transaction_id).c_str()]
                    forKey:@"transaction_id"
                ];
            
                for (auto & i : pairs)
                {
                    NSString * key = [NSString stringWithUTF8String:
                        i.first.c_str()
                    ];
                    NSString * val = [NSString stringWithUTF8String:
                        i.second.c_str()
                    ];
                    
                    if (key && val)
                    {
                        if ([key isEqualToString:@"__t"])
                        {
                            NSDate * t = [NSDate
                                dateWithTimeIntervalSince1970:atoi(val.UTF8String)
                            ];
                            
                            [dict setObject:t forKey:@"__t"];
                        }
                        else if ([key isEqualToString:@"_l"])
                        {
                            NSDate * _l = [NSDate
                                dateWithTimeInterval:atoi(val.UTF8String)
                                sinceDate:[NSDate date]
                            ];
                            
                            [dict setObject:_l forKey:@"_l"];
                        }
                        else if ([key isEqualToString:@"_e"])
                        {
                            NSDate * _e = [NSDate
                                dateWithTimeInterval:atoi(val.UTF8String)
                                sinceDate:[NSDate date]
                            ];
                            
                            [dict setObject:_e forKey:@"_e"];
                        }
                        else if ([key isEqualToString:@"_t"])
                        {
                            NSDate * _t = [NSDate
                                dateWithTimeIntervalSince1970:atoi(val.UTF8String)
                            ];
                            
                            [dict setObject:_t forKey:@"_t"];
                        }
                        else
                        {
                            [dict setObject:val forKey:key];
                        }
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(),^
                {
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:kGVDidFindProfileNotification
                        object:dict
                    ];
                });
            }
        }
    
        /**
         * Called when a version check completes.
         */
        virtual void on_version(
            const std::map<std::string, std::string> & pairs
            )
        {
            @autoreleasepool
            {
                NSMutableDictionary * dict = [NSMutableDictionary dictionary];

                for (auto & i : pairs)
                {
                    NSString * key = [NSString stringWithUTF8String:
                        i.first.c_str()
                    ];
                    NSString * val = [NSString stringWithUTF8String:
                        i.second.c_str()
                    ];
                    
                    if (key && val)
                    {
                        [dict setObject:val forKey:key];
                    }
                }
                
                dispatch_async(dispatch_get_main_queue(),^
                {
                    [[NSNotificationCenter defaultCenter]
                        postNotificationName:kGVOnVersionNotification
                        object:dict
                    ];
                });
            }
        }
    
    private:
    
    protected:
};

static my_grapevine_stack * g_my_grapevine_stack = 0;

@interface GVStack ()
@property (nonatomic, strong) NSTimer * timer;
@end

@implementation GVStack

+ (GVStack *)sharedInstance
{
    static GVStack * gGVStack = nil;
    
    if (!gGVStack)
    {
        gGVStack = [GVStack new];

        [[NSNotificationCenter defaultCenter] addObserver:gGVStack
            selector:@selector(didConnectNotification:)
            name:kGVDidConnectNotification object:nil
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:gGVStack
            selector:@selector(didDisconnectNotification:)
            name:kGVDidDisconnectNotification object:nil
        ];
        
        [[NSNotificationCenter defaultCenter] addObserver:gGVStack
            selector:@selector(didSignInNotification:)
            name:kGVDidSignInNotification object:nil
        ];
    
        [[NSUserDefaults standardUserDefaults] setObject:
            [NSNumber numberWithInt:0] forKey:@"gvStatsConnects"
        ];
        
        [[NSUserDefaults standardUserDefaults] setObject:
            [NSNumber numberWithInt:0] forKey:@"gvStatsDisconnects"
        ];
    }
    
    return gGVStack;
}

- (void)start
{
    if (g_my_grapevine_stack)
    {
        // ...
    }
    else
    {
        g_my_grapevine_stack = new my_grapevine_stack();
        
        g_my_grapevine_stack->start();
    }
}

- (void)start:(NSNumber *)aPort
{
    if (g_my_grapevine_stack)
    {
        // ...
    }
    else
    {
        g_my_grapevine_stack = new my_grapevine_stack();
        
        g_my_grapevine_stack->start(aPort.intValue);
    }
}

- (void)stop
{
    [self.timer invalidate];
    
    if (g_my_grapevine_stack)
    {
        g_my_grapevine_stack->stop();
        
        delete g_my_grapevine_stack, g_my_grapevine_stack = 0;
    }
    else
    {
        // ...
    }
}

- (void)signIn:(NSString *)aUsername password:(NSString *)aPassword
{
    if (g_my_grapevine_stack)
    {
        self.username = aUsername;
        
        g_my_grapevine_stack->sign_in(
            aUsername.UTF8String, aPassword.UTF8String
        );
    }
}

- (void)signOut
{
    if (g_my_grapevine_stack)
    {
        self.username = nil;
        
        g_my_grapevine_stack->sign_out();
    }
}

- (NSUInteger)find:(NSString *)aQuery
{
    if (g_my_grapevine_stack)
    {
        return g_my_grapevine_stack->find(aQuery.UTF8String, 200);
    }
    
    return 0;
}

- (void)subscribe:(NSString *)aUsername
{
    if (g_my_grapevine_stack)
    {
        g_my_grapevine_stack->subscribe(aUsername.UTF8String);
    }
}

- (void)unsubscribe:(NSString *)aUsername
{
    if (g_my_grapevine_stack)
    {
        g_my_grapevine_stack->unsubscribe(aUsername.UTF8String);
    }
}

- (void)post:(NSString *)aMessage
{
    if (g_my_grapevine_stack)
    {
        g_my_grapevine_stack->post(aMessage.UTF8String);
    }
}

- (void)updateProfile:(NSDictionary *)aProfile
{
    if (g_my_grapevine_stack)
    {
        std::map<std::string, std::string> profile;
        
        for (id key in aProfile)
        {
            if ([[aProfile objectForKey:key] isKindOfClass:NSString.class])
            {
                profile[[key UTF8String]] = [[aProfile objectForKey:key] UTF8String];
            }
        }
    
        g_my_grapevine_stack->update_profile(profile);
    }
}

- (void)updateProfile
{
    NSUserDefaults * userDefaults = [NSUserDefaults standardUserDefaults];
    
    NSString * username = [userDefaults objectForKey:@"username"];
    
    NSDictionary * preferences = [userDefaults objectForKey:username];
    
    NSDictionary * profile = [preferences objectForKey:@"profile"];
    
    if (profile || profile.count > 0)
    {
        NSLog(@"updateProfile");
        
        [self updateProfile:profile];
    }
}

- (NSDictionary *)subscriptions
{
    NSMutableDictionary * ret = nil;
    
    if (g_my_grapevine_stack)
    {
        ret = [NSMutableDictionary new];
        
        auto s = g_my_grapevine_stack->subscriptions();
        
        for (auto & i : s)
        {
            [ret setObject:
                [NSString stringWithUTF8String:i.c_str()]
                forKey:[NSString stringWithUTF8String:i.c_str()]
            ];
        }
    }
    
    return ret;
}

#pragma mark - NSNotification's

- (void)didConnectNotification:(NSNotification *)aNotification
{
    self.isConnected = YES;
    
    NSNumber * connects = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"gvStatsConnects"
    ];
    
    if (connects)
    {
        connects = [NSNumber numberWithInt:connects.intValue + 1];
    }
    else
    {
        connects = [NSNumber numberWithInt:1];
    }
    
    NSLog(@"Stats connects = %@", connects);
    
    [[NSUserDefaults standardUserDefaults] setObject:connects
        forKey:@"gvStatsConnects"
    ];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didDisconnectNotification:(NSNotification *)aNotification
{
    self.isConnected = NO;
    
    NSNumber * disconnects = [[NSUserDefaults standardUserDefaults]
        objectForKey:@"gvStatsDisconnects"
    ];
    
    if (disconnects)
    {
        disconnects = [NSNumber numberWithInt:disconnects.intValue + 1];
    }
    else
    {
        disconnects = [NSNumber numberWithInt:1];
    }
    
    NSLog(@"Stats disconnects = %@", disconnects);
    
    [[NSUserDefaults standardUserDefaults] setObject:disconnects
        forKey:@"gvStatsDisconnects"
    ];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)didSignInNotification:(NSNotification *)aNotification
{
    NSDictionary * dict  = aNotification.object;
    
    if ([[dict objectForKey:@"status"] intValue] == 0)
    {
        NSString * query = [NSString stringWithFormat:@"u=%@", self.username];
        
        [self performSelector:@selector(find:) withObject:query afterDelay:1.5f];
    }
    else
    {
        self.username = nil;
    }
}

@end
