//
//  StringUtilsTest.swift
//  StringUtilsTest
//
//  Created by Rafael Setragni on 27/08/20.
//

import XCTest

public class TreeSet<T: Hashable> {
    
    public typealias ComparisonMethod = (_ first:T,_ Second:T)  -> Bool
    
    var _set:Set<T>
    
    var _sortMethod:ComparisonMethod
    
    init(sortMethod:@escaping ComparisonMethod) {
        _sortMethod = sortMethod
        _set = Set<T>()
    }
    
    init(sortMethod:@escaping ComparisonMethod, initialSet:Set<T>) {
        _sortMethod = sortMethod
        _set = initialSet
    }
    
    public func insert(_ newElement:T){
        _set.insert(newElement)
        _set.sorted(by: _sortMethod)
    }
    
    public func remove(_ reference:T){
        _set.remove(reference)
    }
    
    public func remove(at:Int){
        _set.remove(at: _set.index(_set.startIndex, offsetBy: at))
    }
    
    public func removeAll(){
        _set.removeAll()
    }
    
    public func removeFirst(){
        _set.removeFirst()
    }
        
    public func removeLast(){
        _set.remove(at: self._set.index(_set.startIndex, offsetBy: _set.count))
    }
    
    var last:T? {
        get { return _set.isEmpty ? nil : _set[_set.index(_set.startIndex, offsetBy: _set.count)] }
    }
    
    var first:T? {
        get { return _set.isEmpty ? nil : _set.first }
    }
    
    func tail(s: T) -> T? {
        for val in _set {
            if(_sortMethod(val, s)){
                return val
            }
        }
        return nil
    }
    
    func toString() -> String {
        var result:String = ""
        var first:Bool = true
        
        for val in _set {
            result.append((first ? "" : ",") + "\(val)")
            first = false
        }
        
        return "[\(result)]"
    }
}


class StringUtilsTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {

        var sortMethod:TreeSet<Int>.ComparisonMethod = { first,second in return first > second }

        var testSet:TreeSet = TreeSet<Int>.init(sortMethod: sortMethod)
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

