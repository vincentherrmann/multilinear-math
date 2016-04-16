//
//  MPCA.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

//paper: H. Lu, K. N. Plataniotis, and A. N. Venetsanopoulos "MPCA: Multilinear Principal Component Analysis of Tensor Objects" July 2012

import Foundation

/// Multilinear Principal Component Analysis. Performs feature extraction by projecting a collection of samples with arbitrary mode count and sizes to a subspace while capturing most of the original variance.
///
/// - Parameter data: Sample tensor. The first mode enumerates the different samples. The remaining modes constitute the specific sample. All sample elements should be centered, i.e. have mean 0.
/// - Parameter projectionModeSizes: The mode sizes of the projected sample. Every mode has to be smaller of the as the corresponding mode in the original samples. `projectionModeSizes.count` = `data.modeCount-1`
///
/// - Returns:
/// `projectedData`: <br> The data projected to a subspace with the given mode sizes. <br>
/// `projectionMatrices`: <br> One matrix for each sample mode
public func multilinearPCA(data: Tensor<Float>, projectionModeSizes: [Int]) -> (projectedData: Tensor<Float>, projectionMatrices: [Tensor<Float>]) {
    
    //Initialization
    let sampleModeCount = data.modeCount - 1
    let maxLoops = sampleModeCount == 1 ? 1 : 20 //the simple PCA (sampleModeCount = 1) has a closed form solution
    let projectionDifferenceThreshold: Float = 0.001
    
    var projectionMatrices: [Tensor<Float>] = [] // U_n
    for n in 0..<sampleModeCount {
        //initialize as diagonal matrices
        let modeSizes = [projectionModeSizes[n], data.modeSizes[n+1]]
        projectionMatrices.append(Tensor<Float>(diagonalWithModeSizes: modeSizes, repeatedValue: 1.0))
    }
    var projectedData: Tensor<Float> = multilinearPCAProjection(data: data, projectionMatrices: projectionMatrices)
    var projectionScatter: Float = 0
    var newScatter = scatterOf(projectedData)
    print("multilinearPCA")
    print("initial projectionScatter: \(newScatter)")
    
    //Local Optimization
    for _ in 0..<maxLoops {
        projectionScatter = newScatter
        
        projectionMatrices = constructNewProjectionMatrices(data: data, oldProjectionMatrices: projectionMatrices)
        projectedData = multilinearPCAProjection(data: data, projectionMatrices: projectionMatrices)
        
        newScatter = scatterOf(projectedData)
        
        if((newScatter - projectionScatter) / projectionScatter < projectionDifferenceThreshold) {
            break
        }
    }
    print("final projectionScatter: \(newScatter)")
    print("")
    
    return (projectedData, projectionMatrices)
}

private func constructNewProjectionMatrices(data data: Tensor<Float>, oldProjectionMatrices: [Tensor<Float>]) -> [Tensor<Float>] {
    
    var newProjectionMatrices: [Tensor<Float>] = []
    
    //construct a new projectionMatrix for each mode
    for n in 0..<data.modeCount-1 {
        
        let projectionWithoutModeN = multilinearPCAProjection(data: data, projectionMatrices: oldProjectionMatrices, doNotProjectModes: [n])
        //let summationModes = data.modeArray.removeValues([n+1])
        let sampleCovariance = multiply(a: projectionWithoutModeN, remainingModesA: [n+1], b: projectionWithoutModeN, remainingModesB: [n+1])
        
        
        let thisModeSize = data.modeSizes[n+1]
        let (eigenvalues, eigenvectors) = eigendecomposition(sampleCovariance.values, size: MatrixSize(rows: thisModeSize, columns: thisModeSize))
        
        let evSum = eigenvalues.reduce(0, combine: {$0 + $1})
        let capturedSum = eigenvalues[0..<oldProjectionMatrices[n].modeSizes[0]].reduce(0, combine: {$0 + $1})
        let energyPercentage = capturedSum / evSum
        print("Energy captured in mode \(n): \(energyPercentage*100)%")
        
        //create the projection matrix for mode n from the first eigenvectors
        var thisProjectionMatrix = Tensor<Float>(modeSizes: oldProjectionMatrices[n].modeSizes, repeatedValue: 0)
        thisProjectionMatrix.values = Array(eigenvectors[0..<thisProjectionMatrix.elementCount])
        newProjectionMatrices.append(thisProjectionMatrix)
    }
    
    return newProjectionMatrices
}

/// Project the data tensor to a space with different dimensionality via the given projection matrices.
///
/// - Parameter data: Sample tensor. The first mode enumerates the different samples. The remaining modes constitute the specific sample.
/// - Parameter projectionMatrices: One projection matrix for each sample mode (either the MPCA projection matrices or the reconstruction matrices)
/// - Parameter doNotProjectModes: The projection of these modes will be skipped. Althoug the content does not matter, a projection matrix is required nonetheless for these modes. The default value is an empty array.
///
/// - Returns: The data projected with the given projection matrices.
public func multilinearPCAProjection(data data: Tensor<Float>, projectionMatrices: [Tensor<Float>], doNotProjectModes: [Int] = []) -> Tensor<Float> {
    
    var currentData = data
    for n in 0..<data.modeCount-1 {
        if(doNotProjectModes.contains(n) == false) {
            //data: [m, d0, d1, d2]
            //pM:   [p0, d0], [p1, d1], [p2, d2]
            //n=0:  [m, d0, d1, d2] * [p0, d0] = [m, d1, d2, p0]
            //n=1:  [m, d1, d2, p0] * [p1, d1] = [m, d2, p0, p1]
            //n=2:  [m, d2, p0, p1] * [p2, d2] = [m, p0, p1, p2]
            
            //n=2:  [d2, p2] * [m, d0, d1, d2] = [p2, m, d0, d1]
            currentData = multiply(a: currentData, summationModesA: [1], b: projectionMatrices[n], summationModesB: [1])
        } else {
            //do not project mode n, just reorder the data (as if the projectionMatrix was the identity matrix)
            currentData = currentData.reorderModes([0] + Array(2..<data.modeCount) + [1])
        }
    }
    
    return currentData
}

/// Generate the reconstruction matrices of a MPCA by calculating the pseudoinverse of the projection matrices.
public func multilinearPCAReconstructionMatrices(projectionMatrices: [Tensor<Float>]) -> [Tensor<Float>] {
    var reconstructionMatrices: [Tensor<Float>] = []
    for thisMatrix in projectionMatrices {
        let size = MatrixSize(rows: thisMatrix.modeSizes[0], columns: thisMatrix.modeSizes[1])
        let values = pseudoInverse(thisMatrix.values, size: size)
        reconstructionMatrices.append(Tensor<Float>(modeSizes: [size.columns, size.rows], values: values))
    }
    return reconstructionMatrices
}

/// - Returns: The scatter of the given tensor, i.e. the square of the Frobenius norm.
public func scatterOf(tensor: Tensor<Float>) -> Float {
    return multiply(a: tensor, remainingModesA: [], b: tensor, remainingModesB: []).values[0]
}

