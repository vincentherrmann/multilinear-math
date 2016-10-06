//
//  TensorOperations.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

// MARK: - Operations on a single tensor

/// sum tensor over the given modes
/// - Returns: a tensor with only the modes that were not summed over
public func sum(_ tensor: Tensor<Float>, overModes: [Int]) -> Tensor<Float> {
    let remainingModes = tensor.modeArray.removeValues(overModes)
    var outputData = [Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)]
    
    tensor.performForOuterModes(remainingModes, outputData: &outputData,
                                calculate: ({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
                                    let sum = vectorSummation(sourceData[slice: currentIndex].values)
                                    return [Tensor<Float>(scalar: sum)]
                                }),
                                writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
                                    outputData[0][slice: outerIndex] = inputData[0]
                                }))
    
    return outputData[0]
}

/// Normalize the elements of a tensor over the given modes.
/// - Returns:
/// `normalizedTensor`: <br> Normalized version of the given tensor, the elements along the given modes together have mean zero and a standard devation of one <br>
/// `meanTensor`: <br> Mean of the given tensor, itself a tensor with only the modes that were not normalized over <br>
/// `deviationTensor`: <br> Standard deviation of the given tensor, itself a tensor with only the modes that were not normalized over
public func normalize(_ tensor: Tensor<Float>, overModes normalizeModes: [Int]) -> (normalizedTensor: Tensor<Float>, mean: Tensor<Float>, standardDeviation: Tensor<Float>) {
    
    let remainingModes = tensor.modeArray.removeValues(normalizeModes)
    
    let normalizeModeSizes = normalizeModes.map({tensor.modeSizes[$0]})
    
    let normalizedTensor = Tensor<Float>(withPropertiesOf: tensor)
    let meanTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
    let deviationTensor = Tensor<Float>(withPropertiesOf: tensor, onlyModes: remainingModes)
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
    
    return (outputData[0], outputData[1], outputData[2])
}

/// Normalize the elements of a tensor over the given modes with fixed mean and standard deviation
public func normalize(_ tensor: Tensor<Float>, overModes: [Int], withMean mean: Tensor<Float>, deviation: Tensor<Float>) -> Tensor<Float> {
    
    let commonModes = tensor.modeArray.removeValues(overModes)
    //let deviationInverse = 1/deviation
    var deviationInverse = deviation
    deviationInverse.values = deviation.values.map({ ($0 != 0) ? 1/$0 : 1})
    
    let offsetTensor = substract(a: tensor, commonModesA: commonModes, outerModesA: overModes, b: mean, commonModesB: mean.modeArray, outerModesB: [])
    let scaledTensor = multiplyElementwise(a: offsetTensor, commonModesA: commonModes, outerModesA: overModes, b: deviationInverse, commonModesB: deviationInverse.modeArray, outerModesB: [])
    
    return scaledTensor
}

/// Inverse two modes with same size of a tensor
public func inverse(_ tensor: Tensor<Float>, rowMode: Int, columnMode: Int) -> Tensor<Float> {
    assert(rowMode != columnMode, "rowMode and columnMode cannot be the same")
    let remainingModes = tensor.modeArray.filter({$0 != rowMode && $0 != columnMode})
    
    let rows = tensor.modeSizes[rowMode]
    let columns = tensor.modeSizes[columnMode]
    assert(rows == columns, "mode \(rowMode) and \(columnMode) have not the same size")
    
    var inverseTensor = [Tensor<Float>(withPropertiesOf: tensor)]
    
    tensor.performForOuterModes(remainingModes, outputData: &inverseTensor, calculate: ({ (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
        let inverseSlice = sourceData[slice: currentIndex]
        let inverseVector = matrixInverse(inverseSlice.values, size: MatrixSize(rows: rows, columns: columns))
        return [Tensor<Float>(modeSizes: [rows, columns], values: inverseVector)]
    }), writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
        outputData[0][slice: currentIndex] = inputData[0]
    }))
    
    return inverseTensor[0]
}

/// Exponential of every element of the tensor
public func exp(_ tensor: Tensor<Float>) -> Tensor<Float> {
    let exp = Tensor<Float>(withPropertiesOf: tensor, values: vectorExponential(tensor.values))
    return exp
}

/// Natural logarithm of every element of the tensor
public func log(_ tensor: Tensor<Float>) -> Tensor<Float> {
    let log = Tensor<Float>(withPropertiesOf: tensor, values: vectorLogarithm(tensor.values))
    return log
}

//Should be a function for all MuldimensionalData, but the generics don't seem to work!
/// Change the order of one mode in a tensor
public func changeOrderOfModeIn(_ tensor: Tensor<Float>, mode: Int, newOrder: [Int]) -> Tensor<Float> {
    let outerModes = [mode]
    var outputData = [Tensor<Float>(withPropertiesOf: tensor)]
    
    tensor.performForOuterModes(outerModes, outputData: &outputData, calculate: ({ (currentIndex, outerIndex, sourceData) -> ([Tensor<Float>]) in
        let indexPosition = (currentIndex[mode] as! CountableRange<Int>).startIndex
        var newCurrentIndex = currentIndex
        newCurrentIndex[mode] = newOrder[indexPosition]...newOrder[indexPosition]
        let currentSlice = sourceData[slice: newCurrentIndex]
        return [currentSlice]
    }), writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
        outputData[0][slice: currentIndex] = inputData[0]
    }))
    
    return outputData[0]
}

/// - Returns: The index (as Float) of the maximum element in the given mode
public func findMaximumElementOf(_ tensor: Tensor<Float>, inMode: Int) -> Tensor<Float> {
    let outerModes = tensor.modeArray.removeValues([inMode])
    var outputData = [Tensor<Float>(withPropertiesOf: tensor, onlyModes: outerModes)]
    
    tensor.performForOuterModes(outerModes, outputData: &outputData, calculate: ({ (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
        let slice = sourceData[slice: currentIndex]
        let maxIndex = slice.values.index(of: (slice.values.max()!))!
        return [Tensor<Float>(scalar: Float(maxIndex))]
    }), writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
        outputData[0][slice: outerIndex] = inputData[0]
    }))
    
    return outputData[0]
}

/// Zero padding for greater sizes, cutting away for smaller sizes
public func changeModeSizes(_ tensor: Tensor<Float>, targetSizes: [Int]) -> Tensor<Float> {
    if(tensor.modeSizes == targetSizes) {
        return tensor
    }
    if(targetSizes.count != tensor.modeSizes.count) {
        print("wrong number of moe sizes!")
        return tensor
    }
    
    var newTensor = Tensor<Float>(modeSizes: targetSizes, repeatedValue: 0)
    let writeSizes: [DataSliceSubscript] = zip(tensor.modeSizes, targetSizes).map({min($0.0, $0.1)}).map({0..<$0})
    newTensor.setSlice(getSlice(from: tensor, modeSubscripts: writeSizes), modeSubscripts: writeSizes)
    return newTensor
}


// MARK: - Operations combining two tensors
/// Concatenate two tensors. The content of tensor `b` gets appended to `a` in direction of the given mode. Both `a` and `b` must have the same mode sizes in all modes but `alongMode`. One of the tensors may have one mode less than the other, then the additional `alongMode` of size one is amended.
public func concatenate(a: Tensor<Float>, b: Tensor<Float>, alongMode: Int) -> Tensor<Float> {
    var newModeSizes: [Int]
    var sliceA: [DataSliceSubscript]
    var sliceB: [DataSliceSubscript]
    
    if(a.modeCount == b.modeCount) {
        sliceA = a.modeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = CountableRange(start: a.modeSizes[alongMode], distance: b.modeSizes[alongMode])
        
        newModeSizes = a.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + b.modeSizes[alongMode]
    } else if(a.modeCount == b.modeCount+1) {
        sliceA = a.modeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = CountableRange(start: a.modeSizes[alongMode], distance: 1)
        
        newModeSizes = a.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + 1
    } else if(a.modeCount == b.modeCount-1) {
        var aModeSizes = a.modeSizes
        aModeSizes.insert(1, at: alongMode)
        sliceA = aModeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = CountableRange(start: 1, distance: b.modeSizes[alongMode])
        newModeSizes = b.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + 1
    } else {
        print("tensors with mode sizes \(a.modeSizes) and \(b.modeSizes) cannot be concatenated along mode \(alongMode)")
        return a
    }
    
    var concatTensor = Tensor<Float>(modeSizes: newModeSizes, repeatedValue: 0)
    concatTensor[slice: sliceA] = a
    concatTensor[slice: sliceB] = b
    
    return concatTensor
}


public func add(a: Tensor<Float>, commonModesA: [Int]? = nil, outerModesA: [Int]? = nil, b: Tensor<Float>, commonModesB: [Int]? = nil, outerModesB: [Int]? = nil) -> Tensor<Float> {
    
    let (commonA, outerA) = a.inferModes(commonModes: commonModesA, outerModes: outerModesA)
    let (commonB, outerB) = b.inferModes(commonModes: commonModesB, outerModes: outerModesB)
    
    var sum = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerA, outerModesB: outerB, innerModesA: commonA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerA, with: b, forOuterModes: outerB, outputData: &sum,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let sumVector = vectorAddition(vectorA: a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: sumVector)]
    }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
    }))

    return sum[0]
}

public func substract(a: Tensor<Float>, commonModesA: [Int]? = nil, outerModesA: [Int]? = nil, b: Tensor<Float>, commonModesB: [Int]? = nil, outerModesB: [Int]? = nil) -> Tensor<Float> {
    
    let (commonA, outerA) = a.inferModes(commonModes: commonModesA, outerModes: outerModesA)
    let (commonB, outerB) = b.inferModes(commonModes: commonModesB, outerModes: outerModesB)
    
    var difference = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerA, outerModesB: outerB, innerModesA: commonA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerA, with: b, forOuterModes: outerB, outputData: &difference,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let differenceVector = vectorSubtraction(a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: differenceVector)]
            }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
            }))
    
    return difference[0]
}

public func multiplyElementwise(a: Tensor<Float>, commonModesA: [Int]? = nil, outerModesA: [Int]? = nil, b: Tensor<Float>, commonModesB: [Int]? = nil, outerModesB: [Int]? = nil) -> Tensor<Float> {
    
    let (commonA, outerA) = a.inferModes(commonModes: commonModesA, outerModes: outerModesA)
    let (commonB, outerB) = b.inferModes(commonModes: commonModesB, outerModes: outerModesB)
    
    var product = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerA, outerModesB: outerB, innerModesA: commonA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerA, with: b, forOuterModes: outerB, outputData: &product,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let productVector = vectorElementWiseMultiplication(a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: productVector)]
            }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
            }))
    
    return product[0]
}

public func divide(a: Tensor<Float>, commonModesA: [Int]? = nil, outerModesA: [Int]? = nil, b: Tensor<Float>, commonModesB: [Int]? = nil, outerModesB: [Int]? = nil) -> Tensor<Float> {
    
    let (commonA, outerA) = a.inferModes(commonModes: commonModesA, outerModes: outerModesA)
    let (commonB, outerB) = b.inferModes(commonModes: commonModesB, outerModes: outerModesB)
    
    var quotient = [Tensor<Float>(combinationOfTensorA: a, tensorB: b, outerModesA: outerA, outerModesB: outerB, innerModesA: commonA, innerModesB: [], repeatedValue: 0)]
    
    let sliceSizes = commonA.map({a.modeSizes[$0]})
    
    combine(a, forOuterModes: outerA, with: b, forOuterModes: outerB, outputData: &quotient,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let quotientVector = vectorDivision(a[slice: indexA].values, vectorB: b[slice: indexB].values)
                return [Tensor<Float>(modeSizes: sliceSizes, values: quotientVector)]
            }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex] = inputData[0]
            }))
    
    return quotient[0]
}

//public func multiplyComplex(a a: Tensor<Float>, complexModeA: Int = 0, b: Tensor<Float>, complexModeB: Int = 0) -> {
//    assert(a.modeSizes[complexModeA] == b.modeSizes[complexModeB] && b.modeSizes[complexModeB] == 2)
//    var outerA = a.modeArray.filter({$0 != complexModeA})
//    var outerB = b.modeArray.filter({$0 != complexModeB})
//    combine(a, forOuterModes: outerA, with: b, forOuterModes: outerB, outputData: &<#T##[T]#>, calculate: <#T##(indexA: [DataSliceSubscript], indexB: [DataSliceSubscript], outerIndex: [DataSliceSubscript], sourceA: T, sourceB: T) -> [T]#>, writeOutput: <#T##(indexA: [DataSliceSubscript], indexB: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inputData: [T], inout outputData: [T]) -> ()#>)
//}
