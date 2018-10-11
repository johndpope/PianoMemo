//
//  Tests.swift
//  Tests
//
//  Created by hoemoon on 11/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import XCTest
@testable import Piano

class Tests: XCTestCase {

    override func setUp() {
    }

    override func tearDown() {
    }

    func testResolver() {
        let resolved1 = Resolver.merge(base: "aaa", mine: "aaa", theirs: "aaa")
        XCTAssert(resolved1 == "aaa")
        let resolved2 = Resolver.merge(base: "aaa", mine: "bbb", theirs: "aaa")
        XCTAssert(resolved2 == "bbb")
        let resolved3 = Resolver.merge(base: "aaa", mine: "bbb", theirs: "ccc")
        XCTAssert(resolved3 == "cccbbb")

        let base = """
Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let mine = """
Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitorA.
"""
        let theirs = """
Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitorB.
"""
        let _ = Resolver.merge(base: base, mine: mine, theirs: theirs)
        /* resolved4
         Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.\n\nMaecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitorBA.
         */
    }

    func testResolverWithEmoji() {

    }
}
