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
        
        self.measureBlock { //0.046 sec //0.01 sec //0.013 sec //0.005 sec
            let normalized = normalize(tensor, overModes: [0, 2])
        }
    }
    
    func testMode0Normalization() {
        let tensor = randomTensor(5000, 100)
        
        self.measureBlock { //4.7 sec //0.74 sec //1.182 //0.582 sec
            let normalized = normalize(tensor, overModes: [0])
        }
        
    }
    
    func testMode1Normalization() {
        let tensor = randomTensor(5000, 100)
        
        self.measureBlock { //0.29 sec //0.085 sec //0.277 //0.15 sec
            let normalized = normalize(tensor, overModes: [1])
        }
    }
    
    func testMode0NormalizationReverse() {
        let tensor = randomTensor(100, 5000)
        
        self.measureBlock { //4.5 sec //0.89 sec //1.4 sec //0.713 sec
            let normalized = normalize(tensor, overModes: [0])
        }
    }
    
    func testMode1NormalizationReverse() {
        let tensor = randomTensor(100, 5000)
        
        self.measureBlock { //0.022 sec //0.011 sec //0.048 //0.043 sec
            let normalized = normalize(tensor, overModes: [1])
        }
    }
    
    func testMode0Slicing() {
        let tensor = ones(10000, 30)
        
        self.measureBlock { //0.07 sec //0.039 sec //0.019 sec //0.023 sec
            let slice = tensor[all, 7...7]
            
        }
    }
    
    func testMode0SlicingRev() {
        let tensor = ones(30, 10000)
        
        self.measureBlock {//0.000 sec //0.000 sec //0.000 sec //0.000 sec
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
