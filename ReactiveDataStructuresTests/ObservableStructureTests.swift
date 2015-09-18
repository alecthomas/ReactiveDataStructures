//
//  ObservableStructureTests.swift
//  ReactiveDataStructures
//
//  Created by Wes Billman on 9/17/15.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import XCTest
import RxSwift
@testable import ReactiveDataStructures

class TestStructure: ObservableStructure, CustomStringConvertible {
    private var publishPropertyChange = PublishSubject<String>()
    var propertyChanged: Observable<String> { return publishPropertyChange }
    
    var name: String { didSet(value) { publishPropertyChange.on(.Next("name")) } }
    var age: Int { didSet(value) { publishPropertyChange.on(.Next("age")) } }
    
    init(name: String, age: Int) {
        self.name = name
        self.age = age
    }
    
    var description: String {
        return "(\(name), \(age))"
    }
}

class ObservableStructureTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    func testElementChanged() {
        let a = TestStructure(name: "Arthur", age: 20)
        let b = TestStructure(name: "Bob", age: 20)
        
        let collection = ObservableArray<TestStructure>(source: [a])
        var events: [String] = []
        collection.elementChanged
            .subscribeNext({(e, f) in
                events.append("\(e).\(f)")
            })
        a.name = "Alec"
        XCTAssertEqual(events, ["(Alec, 20).name"])
        collection.append(b)
        b.age = 30
        XCTAssertEqual(events, ["(Alec, 20).name", "(Bob, 30).age"])
    }
}
