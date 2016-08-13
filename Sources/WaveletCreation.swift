//
//  WaveletCreation.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 13.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

/// calculate the values of the wavelet function on the integer position from the filter coefficients. This is done by solving a system of linear equations constructed from the dilation equation
public func calculateIntegerWaveletValues(coefficients: [Float]) -> [Float] {
    let count = coefficients.count
    
    //calculate factor matrix (left side of the equation system)
    //example: db4 coeffients a0, a1, a2, a3
    // a0-1  0    0    0   =  0
    //  a2  a1-1  a0   0   =  0
    //  0    a3  a2-1  a1  =  0
    //  0    0    0   a3-1 =  0 //this last row is replaced by:
    //  1    1    1    1   =  1 //to create a unambiguous solution
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
    factorMatrix[count-1...count-1, all] = ones(count)
    let results = [Float](count: count-1, repeatedValue: 0) + [1]
    
    let solution = solveLinearEquationSystem(factorMatrix.values, factorMatrixSize: MatrixSize(rows: count, columns: count), results: results, resultsSize: MatrixSize(rows: count, columns: 1))
    
    return solution
}

public func newWaveletApproximation(currentApproximation: [Float], coefficients: [Float]) -> [Float] {
    let newLevel = 2 * (currentApproximation.count-1) / (coefficients.count-1)
    var newApproximation = [Float](count: (coefficients.count-1) * newLevel + 1, repeatedValue: 0)
    let newValueCount = (coefficients.count-1) * (newLevel/2)
    print("new level: \(newLevel), value count: \(newApproximation.count), new values: \(newValueCount)")
    
    for t in 0..<currentApproximation.count {
        newApproximation[2*t] = currentApproximation[t]
    }
    
    for n in 0..<newValueCount {
        var value: Float = 0
        for c in 0..<coefficients.count {
            let index = 2 + 4*n - newLevel*c
            if(index < 0 || index >= newApproximation.count) {continue}
            value += coefficients[c] * newApproximation[index]
        }
        newApproximation[2*n+1] = value
    }
    
//    for t in 1..<currentApproximation.count {
//        newApproximation[2*t] = currentApproximation[t]
//        var value: Float = 0
//        for c in 0..<coefficients.count {
//            let index = 2*t-1-c*level/2
//            if(index < 0 || index >= currentApproximation.count) {continue}
//            value += currentApproximation[index] * coefficients[c]
//        }
//        newApproximation[2*t-1] = value
//    }
    return newApproximation
}
