//
//  PianoTests.swift
//  PianoTests
//
//  Created by hoemoon on 04/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import XCTest
@testable import Piano

class PianoTests: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testResolver() {
        let resolver = ConflictResolver()
        let result1: String = resolver.positiveMerge(old: "큰 아버지가 방에 들어가시다", new: "아버지가 에 들어가시다")
        let result2: String = resolver
            .positiveMerge(old: "abd", new: "abc")

        print(result1)
        print(result2)

        let result3 = resolver.positiveMerge(old: NSAttributedString(string: "abcdefg"), new: "abcIdefg")

        print(result3)

//        XCTAssert(result1 == "b")
//        XCTAssert(result2 == "abc")

    }

}
