//
//  PlotTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 12.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class PlotTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testQuickLook() {
        let a: [Float] = [2.0, -1.0, 4.0, 1.0]
        let quickLook = QuickArrayPlot(array: a)
        let q = quickLook.customPlaygroundQuickLook()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
