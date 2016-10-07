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
        
        self.measure { //0.046 / 0.01 sec //0.013 / 0.005 sec //0.021 / 0.003 sec
            let normalized = normalize(tensor, overModes: [0, 2])
        }
    }
    
    func testMode0Normalization() {
        let tensor = randomTensor(modeSizes: 5000, 100)
        
        self.measure { //4.7 / 0.74 sec //1.182 / 0.582 sec //2.0 / 0.128 sec
            let normalized = normalize(tensor, overModes: [0])
        }
        
    }
    
    func testMode1Normalization() {
        let tensor = randomTensor(modeSizes: 5000, 100)
        
        self.measure { //0.29 / 0.085 sec //0.277 / 0.15 sec //0.78 / 0.193 sec
            let normalized = normalize(tensor, overModes: [1])
        }
    }
    
    func testMode0NormalizationReverse() {
        let tensor = randomTensor(modeSizes: 100, 5000)
        
        self.measure { //4.5 / 0.89 sec //1.4 / 0.713 sec //2.462 / 0.265 sec
            let normalized = normalize(tensor, overModes: [0])
        }
    }
    
    func testMode1NormalizationReverse() {
        let tensor = randomTensor(modeSizes: 100, 5000)
        
        self.measure { //0.022 / 0.011 sec //0.048 / 0.043 sec //0.34 / 0.048 sec
            let normalized = normalize(tensor, overModes: [1])
        }
    }
    
    func testMode0Slicing() {
        let tensor = ones(10000, 30)
        
        self.measure { //0.07 / 0.039 sec //0.019 / 0.023 sec //0.032 / 0.002 sec
            let slice = tensor[all, 7...7]
            
        }
    }
    
    func testMode0SlicingRev() {
        let tensor = ones(30, 10000)
        
        self.measure {//0.000 sec //0.000 sec //0.000 sec //0.000 / 0.000 sec
            let slice = tensor[all, 7...7]
        }
    }
    
//    func testNormalizeDispatched() {
//        let values = Array(0..<125000).map({return Float($0)})
//        let tensor = Tensor<Float>(modeSizes: [50, 50, 50], values: values)
//        
//        self.measureBlock {
//            let normalized = normalizeConcurrent(tensor, overModes: [0, 2])
//        }
//    }

}
