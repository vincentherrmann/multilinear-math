//
//  DispatchPerformaceTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 22.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class DispatchPerformaceTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testNormalizeSimple() {
        let values = Array(0..<125000).map({return Float($0)})
        let tensor = Tensor<Float>(modeSizes: [50, 50, 50], values: values)
        
        self.measureBlock {
            let normalized = normalize(tensor, overModes: [0, 2])
        }
    }
    
    func testNormalizeDispatched() {
        let values = Array(0..<125000).map({return Float($0)})
        let tensor = Tensor<Float>(modeSizes: [50, 50, 50], values: values)
        
        self.measureBlock {
            let normalized = normalizeConcurrent(tensor, overModes: [0, 2])
        }
    }

}
