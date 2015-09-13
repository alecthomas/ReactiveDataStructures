//
//  ObservablesTests.swift
//  Reactive
//
//  Created by Wes Billman on 9/12/15.
//  Copyright © 2015 Wes Billman. All rights reserved.
//

import XCTest
import RxSwift
@testable import ReactiveDataStructures

class ObservablesTests: XCTestCase {
    var collection:ObservableArray<String>!

    override func setUp() {
        super.setUp()
        collection = ["stuff", "things"]
    }

    func testAppend() {
        let item = "item"
        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(location, actual):
                    XCTAssertEqual(actual, [item])
                    XCTAssertEqual(location.startIndex, 2)
                default: break
                }
        }
        collection.append(item)
        XCTAssertEqual(collection.last, item)
    }

    func testInsert() {
        let item = "item"
        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(location, insertedItems):
                    XCTAssertEqual(insertedItems, [item])
                    XCTAssertEqual(location.startIndex, 1)
                default: break
                }
        }
        collection.insert(item, atIndex: 1)
    }

    func testAppendContentsOf() {
        let items = ["item1", "item2"]
        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(range, elements):
                    XCTAssertEqual(range.startIndex, 2)
                    XCTAssertEqual(range.endIndex, 4)
                    XCTAssertEqual(elements.first, items.first)
                    XCTAssertEqual(elements.last, items.last)
                default: break
                }
        }
        collection.appendContentsOf(items)
    }

    func testRemoveAtIndex() {
        let item = "item"
        //first add an item to test with
        collection.append(item)

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Removed(location, removedItems):
                    XCTAssertEqual(removedItems, [item])
                    XCTAssertEqual(location.startIndex, 2)
                default: break
                }
        }
        collection.removeAtIndex(2)
    }

    func testRemoveFirst() {
        let first = collection.first

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Removed(location, removedItems):
                    XCTAssertEqual(removedItems, [first!])
                    XCTAssertEqual(location.startIndex, 0)
                default: break
                }
        }
        collection.removeFirst()
    }

    func testRemoveLast() {
        let last = collection.last

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Removed(location, removedItems):
                    XCTAssertEqual(removedItems, [last!])
                    XCTAssertEqual(location.startIndex, 1)
                default: break
                }
        }
        collection.removeLast()
    }

    func testRemoveAll() {
        let firstElement = collection.first
        let lastElement = collection.last
        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Removed(range, elements):
                    XCTAssertEqual(range.startIndex, 0)
                    XCTAssertEqual(range.endIndex, 2)
                    XCTAssertEqual(elements.first, firstElement)
                    XCTAssertEqual(elements.last, lastElement)
                default: break
                }
        }
        collection.removeAll()
    }

    func testReplaceRange() {
        let items = ["item1", "item2"]
        let firstElement = collection.first
        let lastElement = collection.last

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(range, elements):
                    XCTAssertEqual(range.startIndex, 0)
                    XCTAssertEqual(range.endIndex, 2)
                    XCTAssertEqual(elements.first, items.first)
                    XCTAssertEqual(elements.last, items.last)
                case let .Removed(range, elements):
                    XCTAssertEqual(range.startIndex, 0)
                    XCTAssertEqual(range.endIndex, 2)
                    XCTAssertEqual(elements.first, firstElement)
                    XCTAssertEqual(elements.last, lastElement)
                }
        }
    }

    func testPopLast() {
        let firstElement = collection.first
        let lastElement = collection.last
        XCTAssertEqual(collection.popLast(), lastElement)
        XCTAssertEqual(collection.popLast(), firstElement)
        XCTAssertEqual(collection.popLast(), nil)
    }

    func testSubscriptIndex() {
        let newValue = "newValue"
        let firstItem = collection.first!

        collection.collectionChanged
            .subscribeNext { event in
                switch event {
                case let .Added(location, insertedItems):
                    XCTAssertEqual(insertedItems, [newValue])
                    XCTAssertEqual(location.startIndex, 0)
                case let .Removed(location, removedItems):
                    XCTAssertEqual(removedItems, [firstItem])
                    XCTAssertEqual(location.startIndex, 0)
                }
        }

        XCTAssertEqual(collection[0], collection.first)
        collection[0] = newValue
    }
}
