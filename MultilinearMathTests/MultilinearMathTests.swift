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
    
}
