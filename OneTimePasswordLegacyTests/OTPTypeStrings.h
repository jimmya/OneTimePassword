//
//  OTPTypeStrings.h
//  OneTimePassword
//
//  Copyright (c) 2014-2015 Matt Rubin and the OneTimePassword authors
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.
//

@import Foundation;
#import "OneTimePasswordLegacyTests-Swift.h"


#pragma mark - OTPTokenType

@interface NSString (OTPTokenType)
+ (instancetype)stringForTokenType:(OTPTokenType)tokenType;
@end


#pragma mark - OTPAlgorithm

extern NSString *const kOTPAlgorithmSHA1;
extern NSString *const kOTPAlgorithmSHA256;
extern NSString *const kOTPAlgorithmSHA512;

@interface NSString (OTPAlgorithm)
+ (instancetype)stringForAlgorithm:(OTPAlgorithm)algorithm;
@end