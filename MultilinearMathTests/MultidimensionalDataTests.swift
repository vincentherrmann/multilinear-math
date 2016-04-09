//
//  MultidimensionalDataTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 09.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class MultidimensionalDataTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testModeReordering() {
        var t = Tensor<Float>(modeSizes: [2, 3, 4], values: Array(0..<24).map({return Float($0)}))
        var indices: [TensorIndex] = [.a, .b, .c]
        t.indices = indices
        
        var reorderedT = t.reorderModes([2, 0, 1])
        XCTAssertEqual(t[0, 1, 2], reorderedT[2, 0, 1], "random order")
        
        
        t = Tensor<Float>(modeSizes: [2, 3, 4, 5, 6, 7], values: Array(0..<5040).map({return Float($0)}))
        indices = [.a, .b, .c, .d, .e, .f]
        t.indices = indices
        
        reorderedT = t.reorderModes([0, 1, 2, 4, 3, 5])
        XCTAssertEqual(t[0, 1, 2, 3, 4, 5], reorderedT[0, 1, 2, 4, 3, 5], "swap .d and .e")
        
        reorderedT = t.reorderModes([4, 5, 0, 2, 3, 1])
        XCTAssertEqual(t[0, 1, 2, 3, 4, 5], reorderedT[4, 5, 0, 2, 3, 1], "random order")
        
        reorderedT = t.reorderModes([5, 4, 3, 2, 1, 0])
        XCTAssertEqual(t[0, 1, 2, 3, 2, 1], reorderedT[1, 2, 3, 2, 1, 0], "inverse order")
    }

}
