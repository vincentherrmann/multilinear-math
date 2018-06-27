//
//  MultilinearMathTests.swift
//  MultilinearMathTests
//
//  Created by Vincent Herrmann on 29.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class MultilinearMathTests: XCTestCase {

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

        var testArray: [Float] = []
        let reduceTest1 = testArray.reduce(1, {$0*$1})
        testArray = [1.0]
        let reduceTest2 = testArray.reduce(1, {$0*$1})
        testArray = [2.0, 1.0, 0.0]
        let reduceTest3 = testArray.reduce(1, {$0*$1})

    }

    func testPerform() {

        print("")
        let tensor = Tensor<Float>(modeSizes: [2, 3, 2], values: Array(0..<12).map({return Float($0)}))
        let sum1 = sum(tensor, overModes: [0])
        XCTAssertEqual(sum1.values, [6.0, 8.0, 10.0, 12.0, 14.0, 16.0], "sum over mode 0")
        print("")
        let sum2 = sum(tensor, overModes: [1])
        XCTAssertEqual(sum2.values, [6.0, 9.0, 24.0, 27.0], "sum over mode 1")
        print("")
        let sum3 = sum(tensor, overModes: [0, 1])
        XCTAssertEqual(sum3.values, [30.0, 36.0], "sum over mode 0 and 1")
        print("")
        let sum4 = sum(tensor, overModes: [0, 1, 2])
        XCTAssertEqual(sum4.values, [66.0], "sum over mode 0")
    }

}
