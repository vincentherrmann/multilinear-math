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

    func testArrayBasedFastSlicing() {
        var originalTensor = zeros(5, 5, 5)
        let sliceTensor = ones(2, 3, 2)
        let subscripts: [DataSliceSubscript] = [[2, 4], [0, 1, 3], [1, 4]]

        //copyIndices(subscripts, modeSizes: [5, 5, 5])
        originalTensor.values.withUnsafeMutableBufferPointer { (pointer) -> () in
            //
            copySliceFrom(sliceTensor, to: originalTensor, targetPointer: pointer, subscripts: subscripts, copyFromSlice: true)
        }

    }

    func testRangeSlicing() {
        var testData = Tensor<Float>(modeSizes: [3, 4, 5], values: Array(0..<60).map({return Float($0)}))

        let testSlice1 = testData[1..<2, 3..<4, 2..<5]
        let compareValues1: [Float] = [37, 38, 39]
        XCTAssertEqual(testSlice1.values, compareValues1, "data slice 1D")

        let testSlice2 = testData[0...1, 2...2, 1...2]
        let compareValues2: [Float] = [11, 12, 31, 32]
        XCTAssertEqual(testSlice2.values, compareValues2, "data slice 2D")

        let testSlice3 = testData[1...2, [0, 1, 2], 3...4]
        let compareValues3: [Float] = [23, 24, 28, 29, 33, 34, 43, 44, 48, 49, 53, 54]
        XCTAssertEqual(testSlice3.values, compareValues3, "data slice 3D")

        let testSlice4 = testData[0..<1, 0..<4, 0..<1]
        let compareValues4: [Float] = [0, 5, 10, 15]
        XCTAssertEqual(testSlice4.values, compareValues4, "data slice with variadic subscript")

        let slice = Tensor<Float>(modeSizes: [2, 3, 2], values: Array(0..<12).map({return Float($0)}))
        testData[0...1, 1...3, [1, 4]] = slice
        XCTAssertEqual(testData[0, 1, 1], 0, "slice replacement 1")
        XCTAssertEqual(testData[0, 1, 4], 1, "slice replacement 2")
        XCTAssertEqual(testData[0, 2, 1], 2, "slice replacement 3")
        XCTAssertEqual(testData[1, 3, 4], 11, "slice replacement 4")
    }

}
