//
//  StringTest.swift
//  StringUtilsTest
//
//  Created by Rafael Setragni on 18/09/20.
//

import XCTest

extension String {
    func matches2(_ regex: String) -> Bool {
        return self.range(of: regex, options: .regularExpression, range: nil, locale: nil) != nil
    }
}

class StringTest: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testExample() throws {
        XCTAssertTrue("http://images.freeimages.com/images/large-previews/d32/space-halo-2-1626962.jpg".matches("https?:\\/\\/"))
        XCTAssertTrue("https://images.freeimages.com/images/large-previews/d32/space-halo-2-1626962.jpg".matches("https?:\\/\\/"))
        XCTAssertFalse("hettp://images.freeimages.com/images/large-previews/d32/space-halo-2-1626962.jpg".matches("https?:\\/\\/"))
        
        
        XCTAssertTrue("http://images.freeimages.com/images/large-previews/d32/space-halo-2-1626962.jpg".matches2("^https?:\\/\\/"))
    }

    func testPerformanceExample() throws {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
