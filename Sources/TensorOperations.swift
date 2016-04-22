//
//  TensorOperations.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

//public func sumTest(tensor: Tensor<Float>, overModes: [Int]) -> Tensor<Float> {
//    let remainingModes = tensor.modeArray.removeValues(overModes)
//    var outputData = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
//    
////    tensor.perform({ (currentIndex, outerIndex, outputData, thisData) in
////        let sum = vectorSummation(thisData[slice: currentIndex].values)
////        outputData[slice: outerIndex] = Tensor<Float>(scalar: sum)
////        //outputData.printMemoryAdresses(printTitle: "--sum action output--", printThread: true)
////        print("current sum values: \(outputData.values)")
////        }, outerModes: remainingModes, outputData: &outputData)
//    
//    tensor.perform({ (currentIndex, outerIndex, outputData, thisData) in
//        outputData[slice: outerIndex] = Tensor<Float>(scalar: 1.0)
//        outputData.printMemoryAdresses(printTitle: "--sum action output--", printThread: true)
//        print("current sum values: \(outputData.values)")
//        }, outerModes: remainingModes, outputData: &outputData)
//    
//    return outputData
//}

public func sumTest2(tensor: Tensor<Float>, overModes: [Int]) -> Tensor<Float> {
    let remainingModes = tensor.modeArray.removeValues(overModes)
    var outputData = [Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)]
    
    tensor.performForOuterModes(remainingModes, outputData: &outputData,
                                calculate: ({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
                                    let sum = vectorSummation(sourceData[slice: currentIndex].values)
                                    return [Tensor<Float>(scalar: sum)]
    }),
                                writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
                                    outputData[0].printMemoryAdresses(printTitle: "--sum action output--", printThread: true)
                                    outputData[0][slice: outerIndex] = inputData[0]
                                    print("current sum values: \(outputData.first!.values)")
    }))
    
//    tensor.perform({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
//        let sum = vectorSummation(sourceData[slice: currentIndex].values)
//        return [Tensor<Float>(scalar: sum)]
//        }, syncAction: { (currentIndex, outerIndex, inputData, outputData) in
//            outputData[0].printMemoryAdresses(printTitle: "--sum action output--", printThread: true)
//            outputData[0][slice: outerIndex] = inputData[0]
//            print("current sum values: \(outputData.first!.values)")
//        }, outerModes: remainingModes, outputData: &outputData)
    
    return outputData.first!
}

public func add(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var sum = Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
//    var currentIndexSum = sum.modeSizes.map({0..<$0}) as [DataSliceSubscript]
    
    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB) { (indexA, indexB, outerIndex) in
        let sumVector = vectorAddition(vectorA: a[slice: indexA].values, vectorB: b[slice: indexB].values)
        sum[slice: outerIndex] = Tensor<Float>(modeSizes: sliceSizes, values: sumVector)
    }
    
//    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
//        currentIndexSum[indexNumber] = i...i
//        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
//            let sumVector = vectorAddition(vectorA: a[slice: currentIndexA].values, vectorB: b[slice: currentIndexB].values)
//            sum[slice: currentIndexSum] = Tensor<Float>(modeSizes: sliceSizes, values: sumVector)
//    })
    
    return sum
}

public func substract(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var difference = Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
//    var currentIndexDiff = difference.modeSizes.map({0..<$0}) as [DataSliceSubscript]
    
    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB) { (indexA, indexB, outerIndex) in
        let diffVector = vectorSubtraction(a[slice: indexA].values, vectorB: b[slice: indexB].values)
        difference[slice: outerIndex] = Tensor<Float>(modeSizes: sliceSizes, values: diffVector)
    }
    
//    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
//        currentIndexDiff[indexNumber] = i...i
//        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
//            let diffVector = vectorSubtraction(a[slice: currentIndexA].values, vectorB: b[slice: currentIndexB].values)
//            difference[slice: currentIndexDiff] = Tensor<Float>(modeSizes: sliceSizes, values: diffVector)
//    })
    
    return difference
}

public func multiplyElementwise(a a: Tensor<Float>, commonModesA: [Int] = [], outerModesA: [Int] = [], b: Tensor<Float>, commonModesB: [Int] = [], outerModesB: [Int] = []) -> Tensor<Float> {
    
    var product = Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerModesA, outerModesB: outerModesB, innerModesA: commonModesA, innerModesB: [], repeatedValue: 0)
    
    let sliceSizes = commonModesA.map({a.modeSizes[$0]})
//    var currentIndexProduct = product.modeSizes.map({0..<$0}) as [DataSliceSubscript]
    
    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB) { (indexA, indexB, outerIndex) in
        let productVector = vectorElementWiseMultiplication(a[slice: indexA].values, vectorB: b[slice: indexB].values)
        product[slice: outerIndex] = Tensor<Float>(modeSizes: sliceSizes, values: productVector)
    }
    
//    combine(a: a, outerModesA: outerModesA, b: b, outerModesB: outerModesB, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
//        currentIndexProduct[indexNumber] = i...i
//        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
//            let productVector = vectorElementWiseMultiplication(a[slice: currentIndexA].values, vectorB: b[slice: currentIndexB].values)
//            product[slice: currentIndexProduct] = Tensor<Float>(modeSizes: sliceSizes, values: productVector)
//    })
    
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

infix operator °* {}
public func °*(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
    
    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)
    
    let product = multiplyElementwise(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)
    
    return product
}

/// add a scalar to every element of a tensor
public func +(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    let sum = Tensor<Float>.init(withPropertiesOf: lhs, values: vectorAddition(vector: lhs.values, add: rhs))
    return sum
}
/// add a scalar to every element of a tensor
public func +(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return rhs+lhs
}

/// multiply every element of a tensor with a scalar
public func *(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    let product = Tensor<Float>.init(withPropertiesOf: lhs, values: vectorMultiplication(lhs.values, factor: rhs))
    return product
}
/// multiply every element of a tensor with a scalar
public func *(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return rhs*lhs
}

public func sum(tensor: Tensor<Float>, overModes: [Int]) -> Tensor<Float> {
    let remainingModes = tensor.modeArray.removeValues(overModes)
    var summedTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
//    var currentRemainingIndex = [Int](count: remainingModes.count, repeatedValue: 0)
    
    tensor.perform(outerModes: remainingModes) { (currentIndex, outerIndex) in
        let sum = vectorSummation(tensor[slice: currentIndex].values)
        summedTensor[slice: outerIndex] = Tensor<Float>(scalar: sum)
    }
    
//    tensor.perform({ (currentIndex) in
//        let summationSlice = tensor[slice: currentIndex]
//        summedTensor[currentRemainingIndex] = vectorSummation(summationSlice.values)
//        }, indexUpdate: { (indexNumber, currentMode, i) in
//            currentRemainingIndex[indexNumber] = i
//        }, forModes: remainingModes)
    
    return summedTensor
}

public func normalize(tensor: Tensor<Float>, overModes normalizeModes: [Int]) -> (normalizedTensor: Tensor<Float>, mean: Tensor<Float>, standardDeviation: Tensor<Float>) {
    
    let remainingModes = tensor.modeArray.removeValues(normalizeModes)
    
    let normalizeModeSizes = normalizeModes.map({tensor.modeSizes[$0]})
    let remainingIndices = tensor.isIndexed ? remainingModes.map({tensor.indices[$0]}) : []
    
    var normalizedTensor = Tensor<Float>(withPropertiesOf: tensor)
    var meanTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    var deviationTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    
//    var currentRemainingIndex = [Int](count: remainingModes.count, repeatedValue: 0)
    
    tensor.perform(outerModes: remainingModes, action: { (currentIndex, outerIndex) in
//        print("normalize currentIndex: \(currentIndex)")
        
        let normalizationSlice = tensor[slice: currentIndex]
        let normalizedVector = vectorNormalization(normalizationSlice.values)
        normalizedTensor[slice: currentIndex] = Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector)
        deviationTensor[slice: outerIndex] = Tensor<Float>(scalar: normalizedVector.standardDeviation)
        meanTensor[slice: outerIndex] = Tensor<Float>(scalar: normalizedVector.mean)
    })
    
//    tensor.perform( { (currentIndex: [DataSliceSubscript]) -> () in
//        
//        let normalizationSlice = tensor[slice: currentIndex]
//        let normalizedVector = vectorNormalization(normalizationSlice.values)
//        normalizedTensor[slice: currentIndex] = Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector)
//        meanTensor[currentRemainingIndex] = normalizedVector.mean
//        deviationTensor[currentRemainingIndex] = normalizedVector.standardDeviation
//        
//        }, indexUpdate: {(indexNumber: Int, currentMode: Int, i: Int) -> () in
//            currentRemainingIndex[indexNumber] = i
//        }, forModes: remainingModes)
    
    return (normalizedTensor, meanTensor, deviationTensor)
}

public func normalizeConcurrent(tensor: Tensor<Float>, overModes normalizeModes: [Int]) -> (normalizedTensor: Tensor<Float>, mean: Tensor<Float>, standardDeviation: Tensor<Float>) {
    
    let remainingModes = tensor.modeArray.removeValues(normalizeModes)
    
    let normalizeModeSizes = normalizeModes.map({tensor.modeSizes[$0]})
    
    var normalizedTensor = Tensor<Float>(withPropertiesOf: tensor)
    var meanTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    var deviationTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    var outputData = [normalizedTensor, meanTensor, deviationTensor]
    
    tensor.performForOuterModes(remainingModes, outputData: &outputData,
                                calculate: ({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
            let normalizationSlice = sourceData[slice: currentIndex]
            let normalizedVector = vectorNormalization(normalizationSlice.values)
            return [Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector),
                Tensor<Float>(scalar: normalizedVector.mean),
                Tensor<Float>(scalar: normalizedVector.standardDeviation)]
    }),
                                writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
            outputData[0][slice: currentIndex] = inputData[0]
            outputData[1][slice: outerIndex] = inputData[1]
            outputData[2][slice: outerIndex] = inputData[2]
    }))
    
//    tensor.perform({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
//            let normalizationSlice = sourceData[slice: currentIndex]
//            let normalizedVector = vectorNormalization(normalizationSlice.values)
//            return [Tensor<Float>(modeSizes: normalizeModeSizes, values: normalizedVector.normalizedVector),
//                    Tensor<Float>(scalar: normalizedVector.mean),
//                    Tensor<Float>(scalar: normalizedVector.standardDeviation)]
//        }, syncAction: { (currentIndex, outerIndex, inputData, outputData) in
//            outputData[0][slice: currentIndex] = inputData[0]
//            outputData[1][slice: outerIndex] = inputData[1]
//            outputData[2][slice: outerIndex] = inputData[2]
//        }, outerModes: remainingModes, outputData: &outputData)
    
    return (outputData[0], outputData[1], outputData[2])
}

public func inverse(tensor: Tensor<Float>, rowMode: Int, columnMode: Int) -> Tensor<Float> {
    assert(rowMode != columnMode, "rowMode and columnMode cannot be the same")
    let remainingModes = tensor.modeArray.filter({$0 != rowMode && $0 != columnMode})
    
    let rows = tensor.modeSizes[rowMode]
    let columns = tensor.modeSizes[columnMode]
    assert(rows == columns, "mode \(rowMode) and \(columnMode) have not the same size")
    
    var inverseTensor = Tensor<Float>(withPropertiesOf: tensor)
    
    tensor.perform(outerModes: remainingModes) { (currentIndex, outerIndex) in
        let inverseSlice = tensor[slice: currentIndex]
        let inverseVector = matrixInverse(inverseSlice.values, size: MatrixSize(rows: rows, columns: columns))
        inverseTensor[slice: currentIndex] = Tensor<Float>(modeSizes: [rows, columns], values: inverseVector)
    }
    
//    tensor.perform( { (currentIndex: [DataSliceSubscript]) -> () in
//        
//        let inverseSlice = tensor[slice: currentIndex]
//        let inverseVector = matrixInverse(inverseSlice.values, size: MatrixSize(rows: rows, columns: columns))
//        inverseTensor[slice: currentIndex] = Tensor<Float>(modeSizes: [rows, columns], values: inverseVector)
//        
//        }, forModes: remainingModes)
    
    return(inverseTensor)
}
