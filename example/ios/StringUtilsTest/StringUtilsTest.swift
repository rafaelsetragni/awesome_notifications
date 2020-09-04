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

    func testCronNextDate(){
        do {
            let fixedDate:Date = "2020-08-05 14:00:00".toDate()!
            
            // test all valid
            let cron1:CronExpression = try CronExpression.init("* * * * * * *", fixedDate:fixedDate)
            let nextDate1 = cron1.getNextValidDate(referenceDate: fixedDate)
            XCTAssertEqual(nextDate1, "2020-08-05 14:00:01".toDate()!)
            
            // test the bottom update
            let cron2:CronExpression = try CronExpression.init("5 * * * * * *", fixedDate:fixedDate)
            let nextDate2 = cron2.getNextValidDate(referenceDate: fixedDate)
            XCTAssertEqual(nextDate2, "2020-08-05 14:00:05".toDate()!)
            
            // test the second level update
            let cron3:CronExpression = try CronExpression.init("5 1-5 * * * * *", fixedDate:fixedDate)
            let nextDate3 = cron3.getNextValidDate(referenceDate: fixedDate)
            XCTAssertEqual(nextDate3, "2020-08-05 14:01:05".toDate()!)
            
            // test a invalid date (past)
            let cron4:CronExpression = try CronExpression.init("59 59 23 * 31 12 2019", fixedDate:fixedDate)
            let nextDate4 = cron4.getNextValidDate(referenceDate: fixedDate)
            XCTAssertNil(nextDate4)
            
            // test the limit of an invalid date (past)
            let cron5:CronExpression = try CronExpression.init("0 0 14 * 5 8 2020", fixedDate:fixedDate)
            let nextDate5 = cron5.getNextValidDate(referenceDate: fixedDate)
            XCTAssertNil(nextDate5)
            
            // test the limit of top level update
            let cron6:CronExpression = try CronExpression.init("0 0 14 * 5 8 *", fixedDate:fixedDate)
            let nextDate6 = cron6.getNextValidDate(referenceDate: fixedDate)
            XCTAssertEqual(nextDate6, "2021-08-05 14:00:00".toDate()!)
            
            // test the limit of valid bottom update
            let cron7:CronExpression = try CronExpression.init("* 0 14 * 5 8 *", fixedDate:fixedDate)
            let nextDate7 = cron7.getNextValidDate(referenceDate: "2020-08-05 13:59:58".toDate()!)
            XCTAssertEqual(nextDate7, "2020-08-05 14:00:00".toDate()!)
            
            // test the limit of "out of range" component update
            let cron8:CronExpression = try CronExpression.init("0 * 13-14 * 5 8 *", fixedDate:fixedDate)
            let nextDate8 = cron8.getNextValidDate(referenceDate: "2020-08-05 13:59:58".toDate()!)
            XCTAssertEqual(nextDate8, "2020-08-05 14:00:00".toDate()!)
            
            // test the limit of "out of range" component update
            let cron9:CronExpression = try CronExpression.init("59 59 23 * 29 2 *", fixedDate:fixedDate)
            let nextDate9 = cron9.getNextValidDate(referenceDate: "2020-02-29 23:59:59".toDate()!)
            XCTAssertEqual(nextDate9, "2024-02-29 23:59:59".toDate()!)
            
        } catch {
            XCTFail("Unexpected error")
        }
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        measure {
            // Put the code you want to measure the time of here.
        }
    }

}

