//
//  TreeSet.swift
//  awesome_notifications
//
//  Created by Rafael Setragni on 31/08/20.
//

import Foundation

public class TreeSet<E: Comparable & Hashable>: Equatable, Collection, CustomStringConvertible {
    
    public typealias Element = E
    public typealias Index = Int
    
    private let reverse:Bool

  #if swift(>=4.1.50)
    public typealias Indices = Range<Int>
  #else
    public typealias Indices = CountableRange<Int>
  #endif

    internal var array: [Element]

    /// Creates an empty ordered set.
    public init() {
        self.reverse = false
        self.array = []
    }

    /// Creates an empty ordered set.
    public init(reverse:Bool) {
        self.reverse = reverse
        self.array = []
    }

    /// Creates an ordered set with the contents of `array`.
    ///
    /// If an element occurs more than once in `element`, only the first one
    /// will be included.
    public init(_ initialValues: [Element], reverse:Bool?) {
        self.reverse = reverse ?? false
        self.array = initialValues
        self.array = self.array.sorted(by: self.compare)
    }

    // MARK: Working with an ordered set
    /// The number of elements the ordered set stores.
    public var count: Int { return array.count }

    /// Returns `true` if the set is empty.
    public var isEmpty: Bool { return array.isEmpty }

    /// Returns the contents of the set as an array.
    public var contents: [Element] { return array }
    
    /// Returns the content inside a position.
    public func atIndex(_ index: Int) -> Element? {
        if(index < 0 || index >= array.count){ return nil }
        return array[index]
    }

    /// Returns `true` if the ordered set contains `member`.
    public func contains(_ member: Element) -> Bool {
        return array.contains(member)
    }
    
    /// Adds an element to the ordered set.
    ///
    /// If it already contains the element, then the set is unchanged.
    ///
    /// - returns: True if the item was inserted.
    public func insert(_ newElement: Element) -> Bool {
        let inserted = array.contains(newElement)
        if !inserted {
            self.array.append(newElement)
            self.array = self.array.sorted(by: self.compare)
        }
        return !inserted
    }

    private func compare(first:E, second:E) -> Bool {
        return reverse ? (first > second) : (first < second)
    }
    
    /// Remove and return the element at the beginning of the ordered set.
    public func removeFirst() -> Element {
        let firstElement = array.removeFirst()
        return firstElement
    }

    /// Remove and return the element at the end of the ordered set.
    public func removeLast() -> Element {
        let lastElement = array.removeLast()
        return lastElement
    }
    
    /// Remove all elements.
    public func removeAll(keepingCapacity keepCapacity: Bool) {
        array.removeAll(keepingCapacity: keepCapacity)
    }
    
    public func tail(reference:E) -> E? {
        if(isEmpty){ return nil }
        for val in array {
            if compare(first:reference, second:val) { return val }
        }
        return nil
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.array)
    }

    public var description: String { return "(TreeSet)\(self.array)" }
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
