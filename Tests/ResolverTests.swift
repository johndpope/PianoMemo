//
//  Tests.swift
//  Tests
//
//  Created by hoemoon on 11/10/2018.
//  Copyright © 2018 Piano. All rights reserved.
//

import XCTest
@testable import Piano

class ResolverTests: XCTestCase {

    func _testResolver() {
        let resolved1 = Resolver.merge(base: "aaa", mine: "aaa", their: "aaa")
        XCTAssert(resolved1 == "aaa")
        let resolved2 = Resolver.merge(base: "aaa", mine: "bbb", their: "aaa")
        XCTAssert(resolved2 == "bbb")
        let resolved3 = Resolver.merge(base: "aaa", mine: "bbb", their: "ccc")
        XCTAssert(resolved3 == "cccbbb")

        let base = """
Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let mine = """
Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitorA.
"""
        let their = """
Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitorB.
"""
        let _ = Resolver.merge(base: base, mine: mine, their: their)
        /* resolved4
         Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.\n\nMaecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitorBA.
         */
    }

    func _testResolverWithEmoji_Conflict() {
        let base = """
🤗Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let mine = """
😈Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let their = """
🤢Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let resolved = Resolver.merge(base: base, mine: mine, their: their)
        let expected = """
🤢Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

😈Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        XCTAssert(resolved == expected)
    }

    func testResolverWithEmoji_No_Conflict() {
        let base = """
🤗Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let mine = """
😈Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let their = """
🤗Sed posuere consectetur est at lobortis. Donec sed odio dui. Cras mattis consectetur purus sit amet fermentum. Vivamus sagittis lacus vel augue laoreet rutrum faucibus dolor auctor.

Maecenas faucibus mollis interdum. Cum sociis natoque penatibus et magnis dis parturient montes, nascetur ridiculus mus. Cras mattis consectetur purus sit amet fermentum. Curabitur blandit tempus porttitor.
"""
        let resolved = Resolver.merge(base: base, mine: mine, their: their)
        XCTAssert(resolved == mine)
    }
}
