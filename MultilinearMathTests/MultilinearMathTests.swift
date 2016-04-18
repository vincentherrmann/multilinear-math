//
//  MultilinearMathTests.swift
//  MultilinearMathTests
//
//  Created by Vincent Herrmann on 29.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
@testable import MultilinearMath

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
        let reduceTest1 = testArray.reduce(1, combine: {$0*$1})
        testArray = [1.0]
        let reduceTest2 = testArray.reduce(1, combine: {$0*$1})
        testArray = [2.0, 1.0, 0.0]
        let reduceTest3 = testArray.reduce(1, combine: {$0*$1})
        
    }
    
    func testPerform() {
        
        print("")
        let tensor = Tensor<Float>(modeSizes: [2, 3, 2], values: Array(0..<12).map({return Float($0)}))
        let sum1 = sumTest(tensor, overModes: [0])
        XCTAssertEqual(sum1.values, [3.0, 5.0, 7.0], "sum over mode 0")
        print("")
        let sum2 = sumTest(tensor, overModes: [1])
        XCTAssertEqual(sum2.values, [3.0, 12.0], "sum over mode 1")
        print("")
        let sum3 = sumTest(tensor, overModes: [0, 1])
        XCTAssertEqual(sum3.values, [15.0], "sum over mode 0 and 1")
        print("")
        let sum4 = sumTest(tensor, overModes: [0, 1, 2])
        XCTAssertEqual(sum4.values, [3.0, 5.0, 7.0], "sum over mode 0")
    }
    
}
