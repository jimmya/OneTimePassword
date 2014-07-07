//
//  OTPToken+Serialization.m
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

#import "OTPToken+Serialization.h"
#import <Base32/MF_Base32Additions.h>


static NSString *const kOTPAuthScheme = @"otpauth";
static NSString *const kQueryAlgorithmKey = @"algorithm";
static NSString *const kQuerySecretKey = @"secret";
static NSString *const kQueryCounterKey = @"counter";
static NSString *const kQueryDigitsKey = @"digits";
static NSString *const kQueryPeriodKey = @"period";
static NSString *const kQueryIssuerKey = @"issuer";


@implementation OTPToken (Serialization)

+ (instancetype)tokenWithURL:(NSURL *)url
{
    return [self tokenWithURL:url secret:nil];
}

+ (instancetype)tokenWithURL:(NSURL *)url secret:(NSData *)secret
{
    OTPToken *token = nil;

    if ([url.scheme isEqualToString:kOTPAuthScheme]) {
        // Modern otpauth:// URL
        token = [self tokenWithOTPAuthURL:url secret:secret];
    }

    return [token validate] ? token : nil;
}

+ (instancetype)tokenWithOTPAuthURL:(NSURL *)url secret:(NSData *)secret
{
    NSDictionary *query = [url queryDictionary];

    OTPTokenType type = [url.host tokenTypeValue];

    if (!secret) {
        NSString *secretString = query[kQuerySecretKey];
        secret = [NSData dataWithBase32String:secretString];
    }

    NSString *algorithmString = query[kQueryAlgorithmKey];
    OTPAlgorithm algorithm = algorithmString ? [algorithmString algorithmValue] : [OTPToken defaultAlgorithm];

    NSString *digitString = query[kQueryDigitsKey];
    NSUInteger digits = digitString ? (NSUInteger)[digitString integerValue] : [OTPToken defaultDigits];

    NSString *name = (url.path.length > 1) ? [url.path substringFromIndex:1] : @""; // Skip the leading "/"

    NSString *counterString = query[kQueryCounterKey];
    uint64_t counter = counterString ? strtoull([counterString UTF8String], NULL, 10) : [OTPToken defaultInitialCounter];

    NSString *periodString = query[kQueryPeriodKey];
    NSTimeInterval period = periodString ? [periodString doubleValue] : [OTPToken defaultPeriod];

    NSString *issuerString = query[kQueryIssuerKey];
    // If the name is prefixed by the issuer string, trim the name
    if (issuerString.length &&
        name.length > issuerString.length &&
        [name rangeOfString:issuerString].location == 0 &&
        [name characterAtIndex:issuerString.length] == ':') {
        name = [[name substringFromIndex:issuerString.length+1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
    } else if (!issuerString.length && name.length) {
        // If there is no issuer string, try to extract one from the name
        NSRange colonRange = [name rangeOfString:@":"];
        if (colonRange.location != NSNotFound && colonRange.location > 0) {
            issuerString = [name substringToIndex:colonRange.location];
            name = [[name substringFromIndex:colonRange.location+1] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" "]];
        }
    }
    NSString *issuer = issuerString;

    OTPToken *token = [[OTPToken alloc] initWithType:type
                                              secret:secret
                                                name:name
                                           algorithm:algorithm
                                              digits:digits];

    token.counter = counter;
    token.period = period;
    token.issuer = issuer;

    return token;
}

- (NSURL *)url
{
    NSMutableArray *query = [NSMutableArray array];

    [query addObject:[NSURLQueryItem queryItemWithName:kQueryAlgorithmKey value:[NSString stringForAlgorithm:self.algorithm]]];
    [query addObject:[NSURLQueryItem queryItemWithName:kQueryDigitsKey value:@(self.digits).stringValue]];

    if (self.type == OTPTokenTypeTimer) {
        [query addObject:[NSURLQueryItem queryItemWithName:kQueryPeriodKey value:@(self.period).stringValue]];
    } else if (self.type == OTPTokenTypeCounter) {
        [query addObject:[NSURLQueryItem queryItemWithName:kQueryCounterKey value:@(self.counter).stringValue]];
    }

    if (self.issuer)
        [query addObject:[NSURLQueryItem queryItemWithName:kQueryIssuerKey value:self.issuer]];

    NSURLComponents *urlComponents = [NSURLComponents new];
    urlComponents.scheme = kOTPAuthScheme;
    urlComponents.host = [NSString stringForTokenType:self.type];
    if (self.name)
        urlComponents.path = [@"/" stringByAppendingString:self.name];
    urlComponents.queryItems = query;

    return urlComponents.URL;
}

@end


@implementation NSURL (QueryDictionary)

- (NSDictionary *)queryDictionary
{
    NSArray *queryItems = [NSURLComponents componentsWithURL:self resolvingAgainstBaseURL:NO].queryItems;
    NSMutableDictionary *queryDictionary = [NSMutableDictionary dictionaryWithCapacity:queryItems.count];
    for (NSURLQueryItem *item in queryItems) {
        queryDictionary[item.name] = item.value;
    }
    return queryDictionary;
}

@end


@implementation NSDictionary (QueryItems)

- (NSArray *)queryItemsArray
{
    NSMutableArray *queryItems = [NSMutableArray arrayWithCapacity:self.count];
    for (NSString *key in self) {
        id value = self[key];
        if ([value isKindOfClass:[NSNumber class]]) {
            value = ((NSNumber *)value).stringValue;
        } else if (![value isKindOfClass:[NSString class]]) {
            NSAssert(NO, @":(");
        }
        [queryItems addObject:[NSURLQueryItem queryItemWithName:key value:value]];
    }
    return queryItems;
}

@end