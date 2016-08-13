//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath
import Accelerate


let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
QuickArrayPlot(array: db4)
var oldApprox = db4
var newApprox: [Float] = []

for _ in 0..<2 {
    newApprox = [Float](count: oldApprox.count * 2, repeatedValue: 0)
    for i in 0..<oldApprox.count {
        newApprox[2*i] = oldApprox[i]
    }
    oldApprox = newApprox
    for i in 0..<newApprox.count {
        var value: Float = 0
        for c in 0..<db4.count {
            if(i-c < 0) {continue}
            value += oldApprox[i-c] * db4[c]
        }
        newApprox[i] = value
        value = 0
    }
    oldApprox = newApprox
}


QuickArrayPlot(array: newApprox)

//create factor matrix
//example: db4 coeffients a0, a1, a2, a3
// a0-1  0    0    0
//  a2  a1-1  a0   0
//  0    a3  a2-1  a1
//  0    0    0   a3-1
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
factorMatrix.values

factorMatrix = randomTensor(min: -1, max: 1, modeSizes: 4, 4)
let results: [Float] = [Float](count: count-1, repeatedValue: 0) + [1]
var solution: [Float] = []
factorMatrix.values.withUnsafeBufferPointer { (a) -> () in
    results.withUnsafeBufferPointer({ (b) -> () in
        solution = solveLinearEquationSystem(a, factorMatrixSize: MatrixSize(rows: count, columns: count), results: b, resultsSize: MatrixSize(rows: count, columns: 1))
    })
}
solution
