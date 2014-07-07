//
//  OTPToken.m
//  Authenticator
//
//  Copyright (c) 2013 Matt Rubin
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of
//  this software and associated documentation files (the "Software"), to deal in
//  the Software without restriction, including without limitation the rights to
//  use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//  the Software, and to permit persons to whom the Software is furnished to do so,
//  subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//  FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//  COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//  IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//  CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//

#import "OTPToken.h"
#import <OneTimePassword/OneTimePassword-Swift.h>


static NSString *const OTPTokenInternalTimerNotification = @"OTPTokenInternalTimerNotification";


@interface OTPToken ()
@property (nonatomic, strong) Token *core;
@end


@implementation OTPToken

- (instancetype)initWithType:(OTPTokenType)type secret:(NSData *)secret name:(NSString *)name algorithm:(OTPAlgorithm)algorithm digits:(NSUInteger)digits
{
    self = [super init];
    if (self) {
        NSAssert(secret != nil, @"Token secret must be non-nil");
        NSAssert(name != nil, @"Token name must be non-nil");
        self.core = [[Token alloc] initWithType:type secret:secret name:name algorithm:algorithm digits:digits];
        self.counter = [self.class defaultInitialCounter];
        self.period = [self.class defaultPeriod];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updatePasswordIfNeeded)
                                                     name:OTPTokenInternalTimerNotification
                                                   object:nil];
    }
    return self;
}

- (id)init
{
    NSAssert(NO, @"Use -initWithType:secret:name:algorithm:digits:");
    return nil;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:OTPTokenInternalTimerNotification
                                                  object:nil];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"<%@ %p> type: %u, name: %@, algorithm: %@, digits: %lu",
            self.class, self, self.type, self.name, [NSString stringForAlgorithm:self.algorithm], (unsigned long)self.digits];
}

+ (instancetype)tokenWithType:(OTPTokenType)type secret:(NSData *)secret name:(NSString *)name issuer:(NSString *)issuer
{
    OTPToken *token = [[OTPToken alloc] initWithType:type
                                              secret:secret
                                                name:name
                                           algorithm:[OTPToken defaultAlgorithm]
                                              digits:[OTPToken defaultDigits]];
    token.issuer = issuer;
    return token;
}


#pragma mark - Defaults

+ (OTPAlgorithm)defaultAlgorithm
{
    return OTPAlgorithmSHA1;
}

+ (NSUInteger)defaultDigits
{
    return 6;
}

+ (uint64_t)defaultInitialCounter
{
    return 1;
}

+ (NSTimeInterval)defaultPeriod
{
    return 30;
}


#pragma mark - Validation

- (BOOL)validate
{
    BOOL validType = (self.type == OTPTokenTypeCounter) || (self.type == OTPTokenTypeTimer);
    BOOL validSecret = !!self.secret.length;
    BOOL validAlgorithm = (self.algorithm == OTPAlgorithmSHA1 ||
                           self.algorithm == OTPAlgorithmSHA256 ||
                           self.algorithm == OTPAlgorithmSHA512);
    BOOL validDigits = (self.digits <= 8) && (self.digits >= 6);

    BOOL validPeriod = (self.period > 0) && (self.period <= 300);

    return validType && validSecret && validAlgorithm && validDigits && validPeriod;
}


#pragma mark - Timed update

+ (void)load
{
    static NSTimer *sharedTimer = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                       target:self
                                                     selector:@selector(updateAllTokens)
                                                     userInfo:nil
                                                      repeats:YES];
        // Ensure this timer fires right at the beginning of every second
        sharedTimer.fireDate = [NSDate dateWithTimeIntervalSince1970:floor(sharedTimer.fireDate.timeIntervalSince1970)+.01];
    });
}

+ (void)updateAllTokens
{
    [[NSNotificationCenter defaultCenter] postNotificationName:OTPTokenInternalTimerNotification object:self];
}

- (void)updatePasswordIfNeeded
{
    if (self.type != OTPTokenTypeTimer) return;

    NSTimeInterval allTime = [NSDate date].timeIntervalSince1970;
    uint64_t newCount = (uint64_t)allTime / (uint64_t)self.period;
    if (newCount > self.counter) {
        self.counter = newCount;
    }
}


#pragma mark - Core

- (NSString *)name { return self.core.name; }

- (NSString *)issuer { return self.core.issuer; }
- (void)setIssuer:(NSString *)issuer { self.core.issuer = issuer; }

- (OTPTokenType)type { return self.core.type; }
- (NSData *)secret { return self.core.secret; }
- (OTPAlgorithm)algorithm { return self.core.algorithm; }
- (NSUInteger)digits { return self.core.digits; }

@end