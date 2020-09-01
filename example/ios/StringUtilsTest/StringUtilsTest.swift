//
//  StringUtilsTest.swift
//  StringUtilsTest
//
//  Created by Rafael Setragni on 27/08/20.
//

import XCTest
import awesome_notifications

class StringUtilsTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() {

        var testSet:TreeSet = TreeSet<Int>.init()
        
        testSet.append(5)
        testSet.append(4)
        testSet.append(3)
        testSet.append(2)
        testSet.append(1)
        
        for val in testSet {
            print("\(val)")
        }
        
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

