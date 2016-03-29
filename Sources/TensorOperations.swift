//
//  TensorOperations.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func add(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var sum = Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    var currentIndexSum = sum.modeSizes.map({0..<$0})
    
    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
        currentIndexSum[indexNumber] = i...i
        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
            let sumVector = vectorAddition(vectorA: a[slice: currentIndexA].values, vectorB: b[slice: currentIndexB].values)
            sum[currentIndexSum] = Tensor<Float>(modeSizes: sliceSizes, values: sumVector)
    })
    
    return sum
}

public func substract(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var difference = Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    var currentIndexDiff = difference.modeSizes.map({0..<$0})
    
    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
        currentIndexDiff[indexNumber] = i...i
        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
            let diffVector = vectorSubtraction(a[slice: currentIndexA].values, vectorB: b[slice: currentIndexB].values)
            difference[currentIndexDiff] = Tensor<Float>(modeSizes: sliceSizes, values: diffVector)
    })
    
    return difference
}

public func multiplyElementwise(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var product = Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
    var currentIndexProduct = product.modeSizes.map({0..<$0})
    
    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
        currentIndexProduct[indexNumber] = i...i
        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
            let diffVector = vectorSubtraction(a[slice: currentIndexA].values, vectorB: b[slice: currentIndexB].values)
            product[currentIndexProduct] = Tensor<Float>(modeSizes: sliceSizes, values: diffVector)
    })
    
    return product
}

public func +(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
    
    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)
    
    let sum = add(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)
    
    return sum
}
public func -(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
    
    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)
    
    let difference = substract(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)
    
    return difference
}

/// add a given scalar to every element of a tensor
public func +(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    var sum = Tensor<Float>.init(modeSizes: lhs.modeSizes, values: vectorAddition(vector: lhs.values, add: rhs))
    sum.indexAs(lhs.indices)
    sum.variances = lhs.variances
    return sum
}
public func +(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return rhs+lhs
}

/// multiply every element of a tensor with a given scalar
public func *(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    var product = Tensor<Float>.init(modeSizes: lhs.modeSizes, values: vectorMultiplication(lhs.values, factor: rhs))
    product.indexAs(lhs.indices)
    product.variances = lhs.variances
    return product
}
public func *(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return rhs*lhs
}

public func sum(tensor: Tensor<Float>, overIndex: TensorIndex) -> Tensor<Float> {
    //unfinished
    return tensor
}

public func normalize(tensor: Tensor<Float>, overModes normalizeModes: [Int]) -> (normalizedTensor: Tensor<Float>, mean: Tensor<Float>, standardDeviation: Tensor<Float>) {
    
    let remainingModes = tensor.modeArray.removeValues(normalizeModes)
    
    let normalizeModeSizes = normalizeModes.map({tensor.modeSizes[$0]})
    let remainingIndices = tensor.isIndexed ? remainingModes.map({tensor.indices[$0]}) : []
    
    //create normalized tensor
    var normalizedTensor = Tensor<Float>(modeSizes: tensor.modeSizes, repeatedValue: 0)
    normalizedTensor.indexAs(tensor.indices)
    normalizedTensor.variances = tensor.variances
    
    var meanTensor = Tensor<Float>(modeSizes: remainingModes.map({tensor.modeSizes[$0]}), repeatedValue: 0)
    meanTensor.indexAs(remainingIndices)
    
    var deviationTensor = Tensor<Float>(modeSizes: remainingModes.map({tensor.modeSizes[$0]}), repeatedValue: 0)
    deviationTensor.indexAs(remainingIndices)
    
    var currentRemainingIndex = [Int](count: remainingModes.count, repeatedValue: 0)
    
    tensor.perform( { (currentIndex: [DataSliceSubscript]) -> () in
        
        let normalizationSlice = tensor[slice: currentIndex]
        let normalizedVector = vectorNormalization(normalizationSlice.values)
        normalizedTensor[slice: currentIndex] = Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector)
        meanTensor[currentRemainingIndex] = normalizedVector.mean
        deviationTensor[currentRemainingIndex] = normalizedVector.standardDeviation
        
        }, indexUpdate: {(indexNumber: Int, currentMode: Int, i: Int) -> () in
            currentRemainingIndex[indexNumber] = i
        }, forModes: remainingModes)
    
    return (normalizedTensor, meanTensor, deviationTensor)
}

public func inverse(tensor: Tensor<Float>, rowMode: Int, columnMode: Int) -> Tensor<Float> {
    assert(rowMode != columnMode, "rowMode and columnMode cannot be the same")
    let remainingModes = tensor.modeArray.filter({$0 != rowMode && $0 != columnMode})
    
    let rows = tensor.modeSizes[rowMode]
    let columns = tensor.modeSizes[columnMode]
    assert(rows == columns, "mode \(rowMode) and \(columnMode) have not the same size")
    
    var inverseTensor = Tensor<Float>(modeSizes: tensor.modeSizes, repeatedValue: 0)
    inverseTensor.indexAs(tensor.indices)
    inverseTensor.variances = tensor.variances
    
    tensor.perform( { (currentIndex: [DataSliceSubscript]) -> () in
        
        let inverseSlice = tensor[slice: currentIndex]
        let inverseVector = matrixInverse(inverseSlice.values, size: MatrixSize(rows: rows, columns: columns))
        inverseTensor[slice: currentIndex] = Tensor<Float>(modeSizes: [rows, columns], values: inverseVector)
        
        }, forModes: remainingModes)
    
    return(inverseTensor)
}

infix operator °* {}
public func °*(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
    
    if(rhs.modeCount > lhs.modeCount) {
        return rhs °* lhs
    }
    
    let commonIndices = lhs.commonIndicesWith(rhs)
    
    assert(commonIndices.count == rhs.modeCount, "element wise tensor multiplication is only possible if the modes of one factor is a subset of the modes of the other factor")
    let remainingModes = lhs.modeArray.removeValues(commonIndices.map({$0.modeA}))
    
    var product = Tensor<Float>(modeSizes: lhs.modeSizes, repeatedValue: 0)
    product.indexAs(lhs.indices)
    product.variances = lhs.variances
    
    lhs.perform({ (currentIndex: [DataSliceSubscript]) -> () in
        
        let factorSlice = lhs[slice: currentIndex]
        let productVector = vectorElementWiseMultiplication(factorSlice.values, vectorB: rhs.values)
        product[slice: currentIndex] = Tensor<Float>(modeSizes: rhs.modeSizes, values: productVector)
        
        }, forModes: remainingModes)
    
    return product
}
