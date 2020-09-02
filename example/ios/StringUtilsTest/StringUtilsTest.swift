//
//  StringUtilsTest.swift
//  StringUtilsTest
//
//  Created by Rafael Setragni on 27/08/20.
//

import XCTest
@testable import awesome_notifications

class StringUtilsTest: XCTestCase {

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testTreeSet() {

        var testSet1:TreeSet = TreeSet<Int>.init()
        
        testSet1.insert(5)
        testSet1.insert(3)
        testSet1.insert(6)
        testSet1.insert(2)
        testSet1.insert(4)
        testSet1.insert(1)
        
        XCTAssertEqual(testSet1.first, 1)
        XCTAssertEqual(testSet1.last, 6)
        XCTAssertNil(testSet1.tail(reference: 6))
        XCTAssertEqual(testSet1.tail(reference: 3), 4)
        XCTAssertEqual(testSet1.tail(reference: 1), 2)

        var testSet2:TreeSet = TreeSet<Int>.init(reverse: true)
        
        testSet2.insert(5)
        testSet2.insert(3)
        testSet2.insert(6)
        testSet2.insert(2)
        testSet2.insert(4)
        testSet2.insert(1)
        
        XCTAssertEqual(testSet2.first, 6)
        XCTAssertEqual(testSet2.last, 1)
        XCTAssertNil(testSet2.tail(reference: 1))
        XCTAssertEqual(testSet2.tail(reference: 3), 2)
        XCTAssertEqual(testSet2.tail(reference: 6), 5)
        
    }

    func testCronParser() {
        
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * * * * * *"))
        XCTAssertTrue(CronExpression.validate(cronExpression: "* * * * * * *"))
        
        XCTAssertFalse(CronExpression.validate(cronExpression: "60 * * * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* 60 * * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * 24 * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * 7 * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * * 32 * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * * * 13 *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "* * * * * * 10000"))
        
        XCTAssertFalse(CronExpression.validate(cronExpression: "*/60 * * * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "60/1 * * * * * *"))
        XCTAssertFalse(CronExpression.validate(cronExpression: "0-60 * * * * * *"))
        
        XCTAssertTrue("*"    .matches(CronExpression.CronNotationType.AnyOne.rawValue))
        XCTAssertTrue("*/30" .matches(CronExpression.CronNotationType.Interval.rawValue))
        XCTAssertTrue("15/30".matches(CronExpression.CronNotationType.Interval.rawValue))
        XCTAssertTrue("1-5"  .matches(CronExpression.CronNotationType.Range.rawValue))
        XCTAssertTrue("1"    .matches(CronExpression.CronNotationType.List.rawValue))
        XCTAssertTrue("1,2,3".matches(CronExpression.CronNotationType.List.rawValue))

        let fixedDate:Date = "2016-04-14 10:44:00".toDate()!
        
        var cron:CronExpression?
        XCTAssertNoThrow(cron = try CronExpression.init("* */5 1-5 * * * ?", fixedDate:fixedDate))
        
        XCTAssertNil(cron!.filterSets[.second]?.first)
        XCTAssertNil(cron!.filterSets[.second]?.last)
        XCTAssertEqual(cron!.filterSets[.minute]?.array, [5,10,15,20,25,30,35,40,45,50,55])
        XCTAssertEqual(cron!.filterSets[.hour]?.array, [1,2,3,4,5])
        XCTAssertEqual(cron!.filterSets[.year]?.array, [2016])
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

