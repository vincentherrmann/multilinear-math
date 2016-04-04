//
//  TensorMultiplication.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

/// - Returns: The product of the two tensors, summed over modes with the same index
public func *(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {
    
    //get common indices and their modes
    let commonIndices = lhs.commonIndicesWith(rhs)
    
    //check if the tensors are non-cartesian
    if(lhs.isCartesian && rhs.isCartesian == false) {
        for commonIndex in commonIndices {
            assert(lhs.variances[commonIndex.modeA] != rhs.variances[commonIndex.modeB], "For non-cartesian tensor multiplication, common indices must have opposite variance")
        }
    }
    
    let modesA = commonIndices.map({$0.modeA})
    let modesB = commonIndices.map({$0.modeB})
    
    return multiply(a: lhs, summationModesA: modesA, b: rhs, summationModesB: modesB)
}

/// Multiply two tensors, while summing some specified modes.
///
/// - Parameter a: First tensor factor
/// - Parameter summationModesA: The modes of tensor a that will be summed over during the multiplication. These modes have to be common with tensor b, but not in the same order or in one streak. If `nil`, the summation modes of a will be inferred from the `remainingModesA`. Default is `nil`.
/// - Parameter remainingModesA: The modes of tensor a that will remain in the product (modes that will not be summed over). If `nil`, the remaining modes of a will be inferred from the `summationModesA`. If both `summationModesA` and `remainingModesA` are nil, all modes of a will remain in the product. Default is `nil`.
/// - Parameter b: Second tensor factor
/// - Parameter summationModesB: analogous to `summationModesA`
/// - Parameter remainingModesB: analogous to `remainingModesA`
///
/// - Returns: The product of the two tensors. The modes of the product will have a specific order: First the remaining modes from a in the same order as in a, then the remaining modes from b, also in the same order.
public func multiply(a a: Tensor<Float>, summationModesA: [Int]? = nil, remainingModesA: [Int]? = nil, b: Tensor<Float>, summationModesB: [Int]? = nil, remainingModesB: [Int]? = nil) -> Tensor<Float> {
    
    //set summation modes
    var modesA: [Int] = [] //default: no summation modes, outer tensor product
    var modesB: [Int] = []
    
    if(summationModesA != nil) {
        modesA = summationModesA!
    } else if(remainingModesA != nil) {
        modesA = a.modeArray.removeValues(remainingModesA!)
    }
    if(summationModesB != nil) {
        modesB = summationModesB!
    } else if(remainingModesB != nil) {
        modesB = b.modeArray.removeValues(remainingModesB!)
    }
    
    let streakSize = modesA.count
    var streakA = modesA.combineWith(Array(0..<streakSize), combineFunction: {(mode: $0, position: $1)}).sort({$0.0 < $1.0})
    var streakB = modesB.combineWith(Array(0..<streakSize), combineFunction: {(mode: $0, position: $1)}).sort({$0.0 < $1.0})
    
    
    //choose ideal reordering for the tensors to make them compatible with efficient matrix multiplication
    let aOptimalOrderForA = a.optimalOrderForModeStreak(streakA.map({$0.mode}))
    let aOptimalOrderForB = b.optimalOrderForModeStreak(streakA.map({modesB[$0.position]}))
    let aOptimalOrderComplexity = a.reorderComplexity(aOptimalOrderForA.newToOld) + b.reorderComplexity(aOptimalOrderForB.newToOld)
    
    let bOptimalOrderForA = a.optimalOrderForModeStreak(streakB.map({modesA[$0.position]}))
    let bOptimalOrderForB = b.optimalOrderForModeStreak(streakB.map({$0.mode}))
    let bOptimalOrderComplexity = a.reorderComplexity(bOptimalOrderForA.newToOld) + b.reorderComplexity(bOptimalOrderForB.newToOld)
    
    var optimalOrderForA: (newToOld: [Int], oldToNew: [Int], streakRange: Range<Int>)
    var optimalOrderForB: (newToOld: [Int], oldToNew: [Int], streakRange: Range<Int>)
    
    if(aOptimalOrderComplexity <= bOptimalOrderComplexity) {
        //use aOptimalOrder
        optimalOrderForA = aOptimalOrderForA
        optimalOrderForB = aOptimalOrderForB
    } else {
        //use bOptimalOrder
        optimalOrderForA = bOptimalOrderForA
        optimalOrderForB = bOptimalOrderForB
    }
    
    var tensorA = a.reorderModes(optimalOrderForA.newToOld)
    var tensorB = b.reorderModes(optimalOrderForB.newToOld)
    
    
    /// properties of a matrix constructed out of a tensor for efficient multiplication
    struct MatrixProperties {
        var rowModes: [Int]
        var columnModes: [Int]
        ///the modes of the tensor that do not fit in the matrix
        var remainingModes: [Int]
        var size: MatrixSize
        var transpose: Bool
        var isLhs: Bool
        
        ///modes that will be summed over in the matrix multiplication
        var summationModes: [Int] {
            get {
                return (isLhs != transpose) ? columnModes : rowModes
            }
        }
        ///modes that will end up in the product tensor after the matrix multiplication
        var productModes: [Int] {
            get {
                return (isLhs != transpose) ? rowModes : columnModes
            }
        }
    }
    
    /// - Returns: The properties of a matrix for matrix multiplication constructed with the given index order
    func computeMatrixProperties(streakModes: Range<Int>, isLhs: Bool) -> MatrixProperties {
        
        var matrixProps = MatrixProperties(rowModes: [], columnModes: [], remainingModes: [], size: MatrixSize(rows: 0, columns: 0), transpose: false, isLhs: true)
        let streakStart = streakModes.startIndex
        let streakLength = streakModes.count
        let modeCount = (isLhs ? a : b).modeCount
        
        if(streakModes.endIndex < modeCount) { //the streak and the modes after the streak can be seen as rows and columns of a matrix, the modes before the streak (if there are any) are the remaining modes
            matrixProps.rowModes = Array(streakStart..<streakStart+streakLength)
            matrixProps.columnModes = Array(streakStart+streakLength..<modeCount)
            matrixProps.remainingModes = Array(0..<streakStart) //might be empty
            matrixProps.transpose = isLhs ? true : false
        } else { //no modes after the streak means the tensor can be seen as a matrix, no remaining modes required
            matrixProps.rowModes = Array(0..<streakStart)
            matrixProps.columnModes = Array(streakStart..<(isLhs ? a : b).modeCount)
            matrixProps.remainingModes = []
            matrixProps.transpose = isLhs ? false : true
        }
        
        if(isLhs) {
            let rows = matrixProps.rowModes.map({tensorA.modeSizes[$0]}).reduce(1, combine: {$0*$1})
            let columns = matrixProps.columnModes.map({tensorA.modeSizes[$0]}).reduce(1, combine: {$0*$1})
            matrixProps.size = MatrixSize(rows: rows, columns: columns)
        } else {
            let rows = matrixProps.rowModes.map({tensorB.modeSizes[$0]}).reduce(1, combine: {$0*$1})
            let columns = matrixProps.columnModes.map({tensorB.modeSizes[$0]}).reduce(1, combine: {$0*$1})
            matrixProps.size = MatrixSize(rows: rows, columns: columns)
            matrixProps.isLhs = false
        }
        
        return matrixProps
    }
    
    let matrixA = computeMatrixProperties(optimalOrderForA.streakRange, isLhs: true)
    let matrixB = computeMatrixProperties(optimalOrderForB.streakRange, isLhs: false)
    
    /// number of elements in the result of the matrix multiplication
    let productMatrixElements = (matrixA.transpose ? matrixA.size.columns : matrixA.size.rows) * (matrixB.transpose ? matrixB.size.rows : matrixB.size.columns)
    
    var productTensor = Tensor<Float>(combinationOfTensorA: tensorA, tensorB: tensorB, outerModesA: matrixA.remainingModes, outerModesB: matrixB.remainingModes, innerModesA: matrixA.productModes, innerModesB: matrixB.productModes, repeatedValue: 0)
    
    let modesFromA = a.modeArray.removeValues(matrixA.summationModes)
    let modesFromB = b.modeArray.removeValues(matrixB.summationModes)
    let oldToNewRemaining = matrixA.remainingModes.map({modesFromA.indexOf($0)!}) + matrixB.remainingModes.map({modesFromB.indexOf($0)! + modesFromA.count})
    let oldToNewFromMatrix = matrixA.productModes.map({modesFromA.indexOf($0)!}) + matrixB.productModes.map({modesFromB.indexOf($0)! + modesFromA.count})
    let productOldToNew = oldToNewRemaining + oldToNewFromMatrix
    
    
    
    //recursive approach for calculating values for modes not covered by the multiplication of the two matrices
//    var currentProductIndex = [Int](count: max(productTensor.modeCount, 1), repeatedValue: 0)
    
    let productSliceSizes = matrixA.productModes.map({tensorA.modeSizes[$0]}) + matrixB.productModes.map({tensorB.modeSizes[$0]})
    
    combine(a: tensorA, outerModesA: matrixA.remainingModes, b: tensorB, outerModesB: matrixB.remainingModes) { (indexA, indexB, outerIndex) in
        let sliceA = tensorA[slice: indexA]
        let sliceB = tensorB[slice: indexB]
        let productVector = matrixMultiplication(matrixA: sliceA.values, sizeA: matrixA.size, transposeA: matrixA.transpose, matrixB: sliceB.values, sizeB: matrixB.size, transposeB: matrixB.transpose, useBLAS: true)
        productTensor[slice: outerIndex] = Tensor<Float>(modeSizes: productSliceSizes, values: productVector)
    }
    
//    combine(a: tensorA, outerModesA: matrixA.remainingModes, b: tensorB, outerModesB: matrixB.remainingModes, indexUpdate: { (indexNumber, currentMode, currentModeIsA, i) -> () in
//        
//        currentProductIndex[indexNumber] = i
//        
//        }, combineFunction: { (currentIndexA, currentIndexB) -> () in
//            
//            let sliceA = tensorA[slice: currentIndexA]
//            let sliceB = tensorB[slice: currentIndexB]
//            let productVector = matrixMultiplication(matrixA: sliceA.values, sizeA: matrixA.size, transposeA: matrixA.transpose, matrixB: sliceB.values, sizeB: matrixB.size, transposeB: matrixB.transpose, useBLAS: true)
//            
//            let productFlatIndex = productTensor.flatIndex(currentProductIndex)
//            productTensor.values.replaceRange(Range(start: productFlatIndex, distance: productMatrixElements), with: productVector)
//            
//    })
    
    let reorderA = matrixA.remainingModes.map({optimalOrderForA.newToOld.indexOf($0)!})
    let productOrderA = reorderA.combineWith(Array(0..<reorderA.count), combineFunction: {($0, $1)}).sort({$0.0 < $1.0})
    let reorderB = matrixB.remainingModes.map({optimalOrderForB.newToOld.indexOf($0)})
    let productOrderB = reorderB.combineWith(Array(reorderA.count..<productTensor.modeCount), combineFunction: {($0, $1)}).sort({$0.0 < $1.0})
    
    productTensor = productTensor.reorderModes(productOldToNew)
    
    return productTensor
}

