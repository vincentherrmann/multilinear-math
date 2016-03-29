//
//  DataSlicingTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 29.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class DataSlicingTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }
    
    func testRangeSlicing() {
        var testData = Tensor<Float>(modeSizes: [3, 4, 5], values: Array(0..<60).map({return Float($0)}))
        
        let testSlice1 = testData[1...1, 3...3, 2...4]
        let compareValues1: [Double] = [37, 38, 39]
        XCTAssertEqual(testSlice1.values, compareValues1, "data slice 1D")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
