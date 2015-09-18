//
//  Observables.swift
//  WatchIt
//
//  Created by Alec Thomas on 8/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

public enum ObservableArrayEvent<Element> {
    case Added(elements: [Element], atIndex: Int)
    case Removed(elements: [Element], atIndex: Int)

    // Returns non-nil if the event is a single element insert.
    public func insertedElement() -> (Element, Int)? {
        switch self {
        case let .Added(elements, atIndex):
            if elements.count == 1 {
                return (elements[0], atIndex)
            }
        case .Removed:
            break
        }
        return nil
    }

    // Returns non-nil if the event is a single element delete.
    public func removedElement() -> (Element, Int)? {
        switch self {
        case .Added:
            break
        case let .Removed(elements, atIndex):
            if elements.count == 1 {
                return (elements[0], atIndex)
            }
        }
        return nil
    }
}

public func == <T: Equatable>(a: ObservableArrayEvent<T>, b: ObservableArrayEvent<T>) -> Bool {
    switch a {
    case let .Added(ai, ae):
        if case let .Added(bi, be) = b { return ai == bi && ae == be }
    case let .Removed(ai, ae):
        if case let .Removed(bi, be) = b { return ai == bi && ae == be }
    }
    return false
}

// An Array-ish object that is observable.
public class ObservableArray<Element>: CollectionType, ArrayLiteralConvertible {
    public let collectionChanged = PublishSubject<ObservableArrayEvent<Element>>()

    private var source: [Element]

    public var count: Int { return source.count }
    public var startIndex: Int { return source.startIndex }
    public var endIndex: Int { return source.endIndex }

    public init() {
        self.source = []
    }

    public init(source: [Element]) {
        self.source = source
    }

    deinit {
        collectionChanged.on(.Completed)
        collectionChanged.dispose()
    }

    public required init(arrayLiteral elements: Element...) {
        self.source = elements
    }

    public func append(element: Element) {
        source.append(element)
        collectionChanged.on(.Next(.Added(elements: [element], atIndex: count - 1)))
    }

    public func removeAll() {
        let elements = source
        source.removeAll()
        collectionChanged.on(.Next(.Removed(elements: elements, atIndex: 0)))
    }

    public func removeAtIndex(index: Int) -> Element {
        let element = source.removeAtIndex(index)
        collectionChanged.on(.Next(.Removed(elements: [element], atIndex: index)))
        return element
    }

    public func removeFirst() -> Element {
        let element = source.removeFirst()
        collectionChanged.on(.Next(.Removed(elements: [element], atIndex: 0)))
        return element
    }

    public func removeLast() -> Element {
        let element = source.removeLast()
        collectionChanged.on(.Next(.Removed(elements: [element], atIndex: count)))
        return element
    }

    public func insert(element: Element, atIndex i: Int) {
        source.insert(element, atIndex: i)
        collectionChanged.on(.Next(.Added(elements: [element], atIndex: i)))
    }

    public func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let index = source.count
        let elements = Array(newElements)
        source.appendContentsOf(newElements)
        collectionChanged.on(.Next(.Added(elements: elements, atIndex: index)))
    }

    public func replaceRange<C : CollectionType where C.Generator.Element == Element>(range: Range<Int>, with elements: C) {
        let old = Array(source[range])
        let new = Array(elements)
        source.replaceRange(range, with: elements)
        collectionChanged.on(.Next(.Removed(elements: old, atIndex: range.startIndex)))
        collectionChanged.on(.Next(.Added(elements: new, atIndex: range.startIndex)))
    }

    public func popLast() -> Element? {
        return source.count == 0 ? nil : removeLast()
    }

    public subscript(index: Int) -> Element {
        get {
            return source[index]
        }
        set(value) {
            let old = source[index]
            source[index] = value
            collectionChanged.on(.Next(.Removed(elements: [old], atIndex: index)))
            collectionChanged.on(.Next(.Added(elements: [value], atIndex: index)))
        }
    }

    public subscript(range: Range<Int>) -> ArraySlice<Element> {
        get {
            return source[range]
        }
        set(value) {
            let old = Array(source[range])
            source[range] = value
            collectionChanged.on(.Next(.Removed(elements: old, atIndex: range.startIndex)))
            collectionChanged.on(.Next(.Added(elements: Array(value), atIndex: range.startIndex)))
        }
    }
}