//
//  TokenTests.swift
//  OneTimePassword
//
//  Created by Matt Rubin on 7/16/14.
//  Copyright (c) 2014 Matt Rubin. All rights reserved.
//

import XCTest
import OneTimePassword

class TokenTests: XCTestCase {
    func testInit() {
        // Create a token
        let name = "Test Name"
        let issuer = "Test Issuer"
        guard let generator = Generator(
            factor: .Counter(111),
            secret: "12345678901234567890".dataUsingEncoding(NSASCIIStringEncoding)!,
            algorithm: .SHA1,
            digits: 6
        ) else {
            XCTFail()
            return
        }

        let token = Token(
            name: name,
            issuer: issuer,
            generator: generator
        )

        XCTAssertEqual(token.name, name)
        XCTAssertEqual(token.issuer, issuer)
        XCTAssertEqual(token.generator, generator)

        // Create another token
        let other_name = "Other Test Name"
        let other_issuer = "Other Test Issuer"
        guard let other_generator = Generator(
            factor: .Timer(period: 123),
            secret: "09876543210987654321".dataUsingEncoding(NSASCIIStringEncoding)!,
            algorithm: .SHA512,
            digits: 8
        ) else {
            XCTFail()
            return
        }

        let other_token = Token(
            name: other_name,
            issuer: other_issuer,
            generator: other_generator
        )

        XCTAssertEqual(other_token.name, other_name)
        XCTAssertEqual(other_token.issuer, other_issuer)
        XCTAssertEqual(other_token.generator, other_generator)

        // Ensure the tokens are different
        XCTAssertNotEqual(token.name, other_token.name)
        XCTAssertNotEqual(token.issuer, other_token.issuer)
        XCTAssertNotEqual(token.generator, other_token.generator)
    }

    func testDefaults() {
        guard let generator = Generator(
            factor: .Counter(0),
            secret: NSData(),
            algorithm: .SHA1,
            digits: 6
        ) else {
            XCTFail()
            return
        }
        let n = "Test Name"
        let i = "Test Issuer"

        let tokenWithDefaultName = Token(issuer: i, generator: generator)
        XCTAssertEqual(tokenWithDefaultName.name, "")
        XCTAssertEqual(tokenWithDefaultName.issuer, i)

        let tokenWithDefaultIssuer = Token(name: n, generator: generator)
        XCTAssertEqual(tokenWithDefaultIssuer.name, n)
        XCTAssertEqual(tokenWithDefaultIssuer.issuer, "")

        let tokenWithAllDefaults = Token(generator: generator)
        XCTAssertEqual(tokenWithAllDefaults.name, "")
        XCTAssertEqual(tokenWithAllDefaults.issuer, "")
    }
}
