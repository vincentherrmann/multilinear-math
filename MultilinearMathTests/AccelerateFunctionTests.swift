//
//  AccelerateFunctionTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 13.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class AccelerateFunctionTests: XCTestCase {

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
    
    func testLinearEquations() {
        let matrix: [Float] = [2, 4, -1, 1]
        let results: [Float] = [3, 0]
        var solution: [Float] = []
        matrix.withUnsafeBufferPointer { (a) -> () in
            results.withUnsafeBufferPointer({ (b) -> () in
                solution = solveLinearEquationSystem(a, factorMatrixSize: MatrixSize(rows: 2, columns: 2), results: b, resultsSize: MatrixSize(rows: 2, columns: 1))
            })
        }
        XCTAssert(solution == [0.5, 0.5], "error in linear equation system solution")
        //print("solution: \(solution)")
        
        let m1: [Float] = [1, 1, 1,
                           0, 2, 5,
                           2, 5, -1]
        let r1: [Float] = [6, -4, 27]
        let s1 = solveLinearEquationSystem(m1, factorMatrixSize: MatrixSize(rows: 3, columns: 3), results: r1, resultsSize: MatrixSize(rows: 3, columns: 1))
        print("solution: \(s1)")
        
        
        for size in 2..<8 {
            print("")
            print("size: \(size)")
            let m: [Float] = randomTensor(min: -1, max: 1, modeSizes: size, size).values
            let r: [Float] = randomTensor(min: -1, max: 1, modeSizes: size).values
            solveLinearEquationSystem(m, factorMatrixSize: MatrixSize(rows: size, columns: size), results: r, resultsSize: MatrixSize(rows: size, columns: 1))
        }
    }
    
    func testWaveletComputation() {
        let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
        let coefficients = db4
        let count = coefficients.count
        var factorMatrix = Tensor<Float>(modeSizes: [count, count], repeatedValue: 0)
        for r in 0..<count-1 {
            let coeff0Position = 2*r
            for c in 0..<count {
                let index = coeff0Position - c
                if(index < 0 || index >= count) {continue}
                factorMatrix[r, index] = coefficients[c]
            }
            factorMatrix[r, r] += -1
        }
        factorMatrix[count-1...count-1, all] = ones(4)
        print("factor matrix: \(factorMatrix.values)")
        
        //count = 5
        //factorMatrix = randomTensor(min: -1, max: 1, modeSizes: count, count)
        let results: [Float] = [Float](repeating: 0, count: count-1) + [1]
        var solution: [Float] = []
        factorMatrix.values.withUnsafeBufferPointer { (a) -> () in
            results.withUnsafeBufferPointer({ (b) -> () in
                solution = solveLinearEquationSystem(a, factorMatrixSize: MatrixSize(rows: count, columns: count), results: b, resultsSize: MatrixSize(rows: count, columns: 1))
            })
        }
        print("solution: \(solution)")
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measure {
            // Put the code you want to measure the time of here.
        }
    }

}
