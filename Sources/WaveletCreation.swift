//
//  WaveletCreation.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 13.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func scalingFunction(from coefficients: [Float], levels: Int) -> [Float] {
    var wavelet = calculateIntegerWaveletValues(coefficients)
    for _ in 0..<levels {
        wavelet = newWaveletApproximation(wavelet, coefficients: coefficients)
    }
    return wavelet
}

public func waveletFunction(scalingFunction: [Float], coefficients: [Float]) -> [Float] {
    print("calculate wavelet function with \(scalingFunction.count) values")
    let distance = (scalingFunction.count-1) / (coefficients.count - 1)
    print("distance: \(distance)")
    var waveletFunction = [Float](repeating: 0, count: scalingFunction.count)
    
    for t in 0..<waveletFunction.count {
        var currentValue: Float = 0
        for k in 0..<coefficients.count {
            let index = 2*t - k*distance
            if(index < 0 || index >= scalingFunction.count) {continue}
            currentValue += scalingFunction[index] * coefficients[k]
        }
        waveletFunction[t] = currentValue
    }
    
    return waveletFunction
}

/// calculate the values of the wavelet function on the integer position from the filter coefficients. This is done by solving a system of linear equations constructed from the dilation equation
public func calculateIntegerWaveletValues(_ coefficients: [Float]) -> [Float] {
    let count = coefficients.count
    
    //calculate factor matrix (left side of the equation system)
    //example: db4 coeffients a0, a1, a2, a3
    // a0-1  0    0    0   =  0
    //  a2  a1-1  a0   0   =  0
    //  0    a3  a2-1  a1  =  0
    //  0    0    0   a3-1 =  0
    //  1    1    1    1   =  1 //this last equation is added to each row to get an unambiguous solution
    var factorMatrix = Tensor<Float>(modeSizes: [count, count], repeatedValue: 0)
    for r in 0..<count {
        let coeff0Position = 2*r
        for c in 0..<count {
            let index = coeff0Position - c
            if(index < 0 || index >= count) {continue}
            factorMatrix[r, index] = coefficients[c]
        }
        factorMatrix[r, r] += -1
    }
    factorMatrix = factorMatrix + 1
    let results = [Float](repeating: 1, count: count-1) + [1]
    
    print("count: \(count)")
    print("factor matrix: \(factorMatrix.values)")
    print("results: \(results)")
    let solution = solveLinearEquationSystem(factorMatrix.values, factorMatrixSize: MatrixSize(rows: count, columns: count), results: results, resultsSize: MatrixSize(rows: count, columns: 1))
    
    let testResults = matrixMultiplication(matrixA: factorMatrix.values, sizeA: MatrixSize(rows: count, columns: count), matrixB: solution, sizeB: MatrixSize(rows: count, columns: 1))
    print("test result: \(testResults)")
    
    return solution
}

public func newWaveletApproximation(_ currentApproximation: [Float], coefficients: [Float]) -> [Float] {
    let newLevel = 2 * (currentApproximation.count-1) / (coefficients.count-1)
    var newApproximation = [Float](repeating: 0, count: (coefficients.count-1) * newLevel + 1)
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
    return newApproximation
}

public func newFilterApproximation(_ currentApproximation: [Float], coefficients: [Float]) -> [Float] {
    let newValueCount = 2*currentApproximation.count + coefficients.count - 2
    var newApproximation = [Float](repeating: 0, count: newValueCount)
    
    for j in 0..<newValueCount {
        var currentValue: Float = 0
        for k in 0..<coefficients.count {
            if((j+k) % 2 == 0) {
                let index = (j-k)/2
                if(index >= 0 && index < currentApproximation.count) {
                    currentValue += coefficients[k] * currentApproximation[index]
                }
                
            }
        }
        newApproximation[j] = currentValue
    }
    
    return newApproximation
}
