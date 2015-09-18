//
//  ObservablesTests.swift
//  Reactive
//
//  Created by Wes Billman on 9/12/15.
//  Copyright © 2015 Wes Billman. All rights reserved.
//

import XCTest
@testable import ReactiveDataStructures

class ObservableArrayTests: XCTestCase {
    var collection:ObservableArray<String>!
    var event:ObservableArrayEvent<String>?

    override func setUp() {
        super.setUp()
        collection = ["stuff", "things"]
        collection.collectionChanged.subscribeNext{ event in self.event = event }
    }

    func testInit() {
        XCTAssertNotNil(ObservableArray<String>())
        XCTAssertNotNil(ObservableArray<String>(source: ["test"]))
    }
    
    func testAppend() {
        let item = "item"
        let index = collection.count
        collection.append(item)
        assertAdded(event, elements: [item], index: index)
        XCTAssertEqual(collection.count, index + 1)
    }

    func testInsert() {
        let item = "item"
        let index = 1
        collection.insert(item, atIndex: index)
        assertAdded(event, elements: [item], index: index)
        XCTAssertEqual(collection.count, 3)
    }

    func testAppendContentsOf() {
        let items = ["item1", "item2"]
        let index = collection.count
        collection.appendContentsOf(items)
        assertAdded(event, elements: items, index: index)
        XCTAssertEqual(collection.count, index + items.count)
    }

    func testRemoveAtIndex() {
        let index = 1
        let item = collection[index]

        // append anther item so we can remove from the middle
        collection.append("item")
        
        collection.removeAtIndex(index)
        assertRemoved(event, elements: [item], index: index)
    }

    func testRemoveFirst() {
        let index = 0
        let item = collection[index]
        
        collection.removeFirst()
        assertRemoved(event, elements: [item], index: index)
    }

    func testRemoveLast() {
        let index = collection.count - 1
        let item = collection.last!

        collection.removeLast()
        assertRemoved(event, elements: [item], index: index)
    }

    func testRemoveAll() {
        let items = Array(collection)
        
        collection.removeAll()
        assertRemoved(event, elements: items, index: 0)
    }

    func testReplaceRange() {
        let items = ["item1", "item2"]
        let range = 0...1
        let oldItems = Array(collection[range])
        
        var added = false
        var removed = false

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(elements, index):
                    XCTAssertEqual(elements, items)
                    XCTAssertEqual(index, range.startIndex)
                    added = true
                case let .Removed(elements, index):
                    XCTAssertEqual(elements, oldItems)
                    XCTAssertEqual(index, range.startIndex)
                    removed = true
                }
        }
        
        collection.replaceRange(range, with: items)
        XCTAssert(added)
        XCTAssert(removed)
        XCTAssertEqual(Array(collection[range]), items)
    }

    func testPopLast() {
        let firstElement = collection.first
        let lastElement = collection.last
        XCTAssertEqual(collection.popLast(), lastElement)
        XCTAssertEqual(collection.popLast(), firstElement)
        XCTAssertEqual(collection.popLast(), nil)
    }

    func testSetSubscriptIndex() {
        let newValue = "newValue"
        let valueIndex = 0
        let firstItem = collection[valueIndex]
        var added = false
        var removed = false

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(elements, index):
                    XCTAssertEqual(elements, [newValue])
                    XCTAssertEqual(index, valueIndex)
                    added = true
                case let .Removed(elements, index):
                    XCTAssertEqual(elements, [firstItem])
                    XCTAssertEqual(index, valueIndex)
                    removed = true
                }
        }

        collection[0] = newValue
        XCTAssert(added)
        XCTAssert(removed)
        XCTAssertEqual(collection[valueIndex], newValue)
    }
    
    func testSetSubscriptRange() {
        let items = ["item1", "item2"]
        let range = 0...1
        let oldItems = Array(collection[range])
        
        var added = false
        var removed = false
        
        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(elements, index):
                    XCTAssertEqual(elements, items)
                    XCTAssertEqual(index, range.startIndex)
                    added = true
                case let .Removed(elements, index):
                    XCTAssertEqual(elements, oldItems)
                    XCTAssertEqual(index, range.startIndex)
                    removed = true
                }
        }
        
        collection[range] = items[range]
        XCTAssert(added)
        XCTAssert(removed)
        XCTAssertEqual(Array(collection[range]), items)
    }
    
    func testInsertedElement() {
        let item = "item"
        let atIndex = collection.count
        var inserted = false
        collection.collectionChanged
            .subscribeNext { event in
                if let (element, index) = event.insertedElement() {
                    XCTAssertEqual(element, item)
                    XCTAssertEqual(index, atIndex)
                    inserted = true
                }
        }
        collection.insert(item, atIndex: atIndex)
        XCTAssert(inserted)
    }
    
    func testRemovedElement() {
        let atIndex = 0
        let item = collection[atIndex]
        var removed = false
        collection.collectionChanged
            .subscribeNext { event in
                if let (element, index) = event.removedElement() {
                    XCTAssertEqual(element, item)
                    XCTAssertEqual(index, atIndex)
                    removed = true
                }
        }
        collection.removeAtIndex(atIndex)
        XCTAssert(removed)
    }
    
    func testEquatable() {
        let items = ["item1", "item2"]
        let index = 2
        let added1 = ObservableArrayEvent.Added(elements: items, atIndex: index)
        let added2 = ObservableArrayEvent.Added(elements: items, atIndex: index)
        let removed1 = ObservableArrayEvent.Removed(elements: items, atIndex: index)
        let removed2 = ObservableArrayEvent.Removed(elements: items, atIndex: index)
        
        XCTAssert(added1 == added2)
        XCTAssert(removed1 == removed2)
    }
    
//MARK: Custom assertions
    
    private func assertAdded(event:ObservableArrayEvent<String>?, elements:[String], index:Int) {
        XCTAssertNotNil(event)
        var added = false
        switch event! {
        case let .Added(e, i):
            XCTAssertEqual(e, elements)
            XCTAssertEqual(i, index)
            added = true
        case .Removed:
            XCTFail("Only .Added expected")
        }
        XCTAssert(added)
    }
    
    private func assertRemoved(event:ObservableArrayEvent<String>?, elements:[String], index:Int) {
        XCTAssertNotNil(event)
        var removed = false
        switch event! {
        case .Added:
            XCTFail("Only .Removed expected")
        case let .Removed(e, i):
            XCTAssertEqual(e, elements)
            XCTAssertEqual(i, index)
            removed = true
        }
        XCTAssert(removed)
    }

    
}
