//
//  Observables.swift
//  WatchIt
//
//  Created by Alec Thomas on 8/09/2015.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

public protocol ObservableEvent {}

public protocol ObservableStructure {
    var propertyChanged: Observable<String> { get }
}

public enum ObservableArrayEvent<Element>: ObservableEvent {
    case Added(range: Range<Int>, elements: [Element])
    case Removed(range: Range<Int>, elements: [Element])
}

public func  == <T: Equatable>(a: ObservableArrayEvent<T>, b: ObservableArrayEvent<T>) -> Bool {
    switch a {
    case let .Added(ai, ae):
        if case let .Added(bi, be) = b { return ai == bi && ae == be }
    case let .Removed(ai, ae):
        if case let .Removed(bi, be) = b { return ai == bi && ae == be }
    }
    return false
}

// Extend ObservableArray to allow observation of element changes
// iff the Element is an ObservableStructure.
public extension ObservableArray where Element: ObservableStructure {
    public var elementChanged: Observable<(Element, String)> {
        let publisher = PublishSubject<(Element, String)>()
        for element in self {
            element.propertyChanged.map({n in (element, n)}).subscribe(publisher)
        }
        return publisher
    }

    public var anyChange: Observable<Void> {
        return sequenceOf(
            // Check changed elements for validity.
            elementChanged
                .map({(i, _) in
                    return true
                })
                .filter({$0})
                .map({_ in ()}),
            collectionChanged.map({_ in ()})
            ).merge()
    }
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
        let range = Range<Int>(start: source.count - 1, end: source.count - 1)
        collectionChanged.on(.Next(.Added(range: range, elements: [element])))
    }

    public func removeAll() {
        let elements = source
        source.removeAll()
        collectionChanged.on(.Next(.Removed(range: Range(start: elements.startIndex, end: elements.endIndex), elements: elements)))
    }

    public func removeAtIndex(index: Int) -> Element {
        let element = source.removeAtIndex(index)
        collectionChanged.on(.Next(.Removed(range: Range(start: index, end: index), elements: [element])))
        return element
    }

    public func removeFirst() -> Element {
        let element = source.removeFirst()
        collectionChanged.on(.Next(.Removed(range: Range(start: 0, end: 0), elements: [element])))
        return element
    }

    public func removeLast() -> Element {
        let element = source.removeLast()
        collectionChanged.on(.Next(.Removed(range: Range(start: count, end: count), elements: [element])))
        return element
    }

    public func insert(element: Element, atIndex i: Int) {
        source.insert(element, atIndex: i)
        collectionChanged.on(.Next(.Added(range: Range(start: i, end: i), elements: [element])))
    }

    public func appendContentsOf<S : SequenceType where S.Generator.Element == Element>(newElements: S) {
        let index = source.count
        let elements = Array(newElements)
        source.appendContentsOf(newElements)
        collectionChanged.on(.Next(.Added(range: Range(start: index, end: index+elements.count), elements: elements)))
    }

    public func replaceRange<C : CollectionType where C.Generator.Element == Element>(range: Range<Int>, with elements: C) {
        let old = Array(source[range])
        let new = Array(elements)
        source.replaceRange(range, with: elements)
        collectionChanged.on(.Next(.Removed(range: range, elements: old)))
        collectionChanged.on(.Next(.Added(range: Range(start: range.startIndex, end: range.endIndex), elements: new)))
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
            let range = Range<Int>(start: index, end: index)
            source[index] = value
            collectionChanged.on(.Next(.Removed(range: range, elements: [old])))
            collectionChanged.on(.Next(.Added(range: range, elements: [value])))
        }
    }

    public subscript(range: Range<Int>) -> ArraySlice<Element> {
        get {
            return source[range]
        }
        set(value) {
            let old = Array(source[range])
            source[range] = value
            collectionChanged.on(.Next(.Removed(range: range, elements: old)))
            collectionChanged.on(.Next(.Added(range: Range(start: range.startIndex, end: range.startIndex), elements: Array(value))))
        }
    }
}