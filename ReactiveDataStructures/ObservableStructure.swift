//
//  ObservableStructure.swift
//  ReactiveDataStructures
//
//  Created by Wes Billman on 9/17/15.
//  Copyright © 2015 SwapOff. All rights reserved.
//

import Foundation
import RxSwift

public protocol ObservableStructure {
    var propertyChanged: Observable<String> { get }
}

// Extend ObservableArray to allow observation of element changes
// if the Element is an ObservableStructure.
public extension ObservableArray where Element: ObservableStructure {
    public var elementChanged: Observable<(Element, String)> {
        let publisher = PublishSubject<(Element, String)>()
        for element in self {
            element.propertyChanged.map({n in (element, n)}).subscribe(publisher)
        }
        self.collectionChanged
            .subscribeNext({event in
                switch event {
                case let .Added(elements, _):
                    for element in elements {
                        element.propertyChanged.map({n in (element, n)}).subscribe(publisher)
                    }
                case .Removed:
                    break
                }
            })
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