//
//  TreeSet.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 31/08/20.
//

import Foundation

public struct TreeSet<E: Comparable & Hashable>: Equatable, Collection {
    public typealias Element = E
    public typealias Index = Int
    
    private let reverse:Bool

  #if swift(>=4.1.50)
    public typealias Indices = Range<Int>
  #else
    public typealias Indices = CountableRange<Int>
  #endif

    private var array: [Element]
    private var set: Set<Element>

    /// Creates an empty ordered set.
    public init(reverse:Bool?) {
        self.reverse = reverse ?? false
        self.array = []
        self.set = Set()
    }

    /// Creates an ordered set with the contents of `array`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(_ array: [Element], reverse:Bool?) {
        self.init(reverse:reverse)
        for element in array {
            insert(element)
        }
    }

    // MARK: Working with an ordered set
    /// The number of elements the ordered set stores.
    public var count: Int { return array.count }

    /// Returns `true` if the set is empty.
    public var isEmpty: Bool { return array.isEmpty }

    /// Returns the contents of the set as an array.
    public var contents: [Element] { return array }

    /// Returns `true` if the ordered set contains `member`.
    public func contains(_ member: Element) -> Bool {
        return set.contains(member)
    }

    /// Adds an element to the ordered set.
    ///
    /// If it already contains the element, then the set is unchanged.
    ///
    /// - returns: True if the item was inserted.
    @discardableResult
    public mutating func insert(_ newElement: Element) -> Bool {
        let inserted = set.insert(newElement).inserted
        if inserted {
            array.append(newElement)
        }
        array = array.sorted(by: compare)
        return inserted
    }

    private func compare(first:E, second:E) -> Bool {
        return reverse ? (first > second) : (first < second)
    }
    
    /// Remove and return the element at the beginning of the ordered set.
    public mutating func removeFirst() -> Element {
        let firstElement = array.removeFirst()
        set.remove(firstElement)
        return firstElement
    }

    /// Remove and return the element at the end of the ordered set.
    public mutating func removeLast() -> Element {
        let lastElement = array.removeLast()
        set.remove(lastElement)
        return lastElement
    }

    /// Remove all elements.
    public mutating func removeAll(keepingCapacity keepCapacity: Bool) {
        array.removeAll(keepingCapacity: keepCapacity)
        set.removeAll(keepingCapacity: keepCapacity)
    }
    
    public func tail(reference:E) -> E? {
        if(isEmpty){ return nil }
        for val in array {
            if compare(first:reference, second:val) { return val }
        }
        return nil
    }
}

extension TreeSet: ExpressibleByArrayLiteral {
    /// Create an instance initialized with `elements`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(arrayLiteral elements: Element...) {
        self.init(elements, reverse:false)
    }
}

extension TreeSet: RandomAccessCollection {
    public var startIndex: Int { return contents.startIndex }
    public var endIndex: Int { return contents.endIndex }
    public subscript(index: Int) -> Element {
      return contents[index]
    }
}

public func == <T>(lhs: TreeSet<T>, rhs: TreeSet<T>) -> Bool {
    return lhs.contents == rhs.contents
}

extension TreeSet: Hashable where Element: Hashable { }
