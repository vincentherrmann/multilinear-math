//
//  UMPCA.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

//paper: H. Lu, K. N. Plataniotis, and A. N. Venetsanopoulos "Uncorrelated Multilinear Principal Component Analysis for Unsupervised Multilinear Subspace Learning" November 2009

import Foundation

/// Elementary multilinear projection. Projects a tensor to a scalar
public struct ElementaryMultilinearProjection {
    public var projectionVectors: [Tensor<Float>]
    /// sizes of the individual modes
    public var modeSizes: [Int] {
        get {
            return projectionVectors.map({$0.modeSizes[0]})
        }
    }
    /// number of modes
    public var modeCount: Int {
        get {
            return projectionVectors.count
        }
    }
    /// simply Array(0..<modeCount)
    public var modeArray: [Int] {
        get {
            return Array(0..<modeCount)
        }
    }

    public init(withProjectionVectors: [Tensor<Float>]) {
        self.projectionVectors = withProjectionVectors
    }

    public init(withUnitNormVectorsforTensor tensor: Tensor<Float>, onlyModes: [Int]? = nil) {
        projectionVectors = []

        let modes = (onlyModes != nil) ? onlyModes! : tensor.modeArray
        for mode in modes {
            let size = Float(tensor.modeSizes[mode])
            projectionVectors.append(Tensor<Float>(withPropertiesOf: tensor, onlyModes: [mode], repeatedValue: (1/size)))
        }
    }

    public func project(_ tensor: Tensor<Float>, skipProjectionModes: [Int] = []) -> Tensor<Float> {
        var currentProjection = tensor
        for m in modeArray.removeValues(skipProjectionModes) {
            currentProjection = currentProjection * projectionVectors[m]
        }
        return currentProjection
    }
}

/// Uncorrelated Multilinear Principal Component Analysis. Extracts uncorrelated features from a collection of samples with arbitrary mode count and sizes.
///
/// - Parameter data: Sample tensor. The first mode enumerates the different samples. The remaining modes constitute the specific sample. All sample elements should be centered, i.e. have mean 0.
/// - Parameter featureCount: The number of uncorrelated features to extract. Has to be equal to or smaller than the smallest mode size of the data tensor (including the sample mode).
///
/// :
/// `projectedData`: <br> Each sample projected to a vector of uncorrelated features. <br>
/// `projections`: <br> Array of elementary multilinear projections, one for each resulting feature.
public func uncorrelatedMPCA(_ inputData: Tensor<Float>, featureCount: Int) -> (projectedData: Tensor<Float>, projections: [ElementaryMultilinearProjection]) {

    let data = inputData.uniquelyIndexed()
    let additionalIndices = TensorIndex.uniqueIndexArray(5, excludedIndices: data.indices)
    let (sample, feature, featureT, nMode, nModeT, nModeT2) = (data.indices[0], additionalIndices[0], additionalIndices[1], additionalIndices[2], additionalIndices[3], additionalIndices[4])

    //upper bound for featureCount: min(data.modeSizes)
    let maxFeatureCount = data.modeSizes.min()!
    assert(featureCount <= maxFeatureCount, "Cannot construct \(featureCount) uncorrelated features from data tensor with mode sizes \(data.modeSizes)")

    //data: [m, d0, d1, ...]
    //projectedData: [m, p]
    let maxLoops = 20
    let projectionDifferenceThreshold: Float = 0.001
    let sampleCount = data.modeSizes[0]
    let sampleModeCount = data.modeCount-1

    var projections: [ElementaryMultilinearProjection] = [] // [u0[p, d0], u1[p, d1], ..., uN-1[p, dN-1]]
    var projectedData = Tensor<Float>(modeSizes: [0, sampleCount], values: [])  //[p, m]
    projectedData.indices = [feature, sample]

    for p in 0..<featureCount { //calculate the pth uncorrelated feature

        var currentEMP = ElementaryMultilinearProjection(withUnitNormVectorsforTensor: data, onlyModes: Array(1..<data.modeCount))
        var currentG: Tensor<Float>! //vector of all samples projected to feature p
        var projectionScatter: Float = 0
        var newScatter: Float = FLT_MIN

        print("")
        print("calculating feature \(p) projection")

        for _ in 0..<maxLoops { //optimization
            projectionScatter = newScatter

            for n in 0..<sampleModeCount { //calculate the nth vector of the pth EMP
                let modeSize = data.modeSizes[n+1]

                let partialProjection = currentEMP.project(data, skipProjectionModes: [n])[sample, nMode] //[m, d_n]
                let scatterMatrix = partialProjection * partialProjection[sample, nModeT] //[nMode, nModeT]

                var optimizationMatrix: Tensor<Float>

                if(p > 0) {
                    //formula for the optimization matrix
                    let pp = partialProjection[sample, nMode] * projectedData[feature, sample] // [nMode, feature]
                    let pi = inverse(pp[nMode, feature] * pp[nMode, featureT], rowMode: 0, columnMode: 1) // [feature, featureT]
                    let pm = (pp * pi) * pp[nModeT, featureT] // [nMode, nModeT]
                    let ps = Tensor<Float>(diagonalWithModeSizes: [modeSize, modeSize])[nMode, nModeT] - pm

                    optimizationMatrix = ps[nMode, nModeT2] * scatterMatrix[nModeT2, nModeT] // [nMode, nModeT]
                } else {
                    optimizationMatrix = scatterMatrix
                }

                let eigen = eigendecomposition(optimizationMatrix.values, size: MatrixSize(rows: modeSize, columns: modeSize))
                let u = eigen.eigenvectors[0..<modeSize]
                print("mode \(n) biggest eigenvalue: \(eigen.eigenvalues[0])")

                currentEMP.projectionVectors[n].values = Array(u)
            } // n-loop


            currentG = currentEMP.project(data)
            newScatter = (currentG * currentG).values[0]

            if((newScatter - projectionScatter) / projectionScatter < projectionDifferenceThreshold) {
                break
            } else {
                print("current scatter: \(newScatter)")
            }
        } // _-loop (optimization)

        print("final projectionScatter of feature \(p): \(newScatter)")
        projectedData.modeSizes[0] = p+1
        projectedData.values.append(contentsOf: currentG.values)
        projections.append(currentEMP)

    } // p-loop

    return (projectedData.reorderModes([1, 0]), projections)
}

/// Project multidimensional data to vectors using multiple independent elementary multilinear projections
public func uncorrelatedMPCAProject(_ data: Tensor<Float>, projections: [ElementaryMultilinearProjection]) -> Tensor<Float> {

    let featureCount = projections.count
    var projectedData = Tensor<Float>(modeSizes: [data.modeSizes[0], featureCount], repeatedValue: 0)
    projectedData.indices[0] = data.indices[0]

    for p in 0..<featureCount {
        projectedData[all, p...p] = projections[p].project(data)
    }

    return projectedData
}

/// Reconstruct data from vectors using the elementary multilinear projections that created them
public func uncorrelatedMPCAReconstruct(_ projectedData: Tensor<Float>, projections: [ElementaryMultilinearProjection]) -> Tensor<Float> {

    let featureCount = projections.count
    var currentReconstruction: Tensor<Float> = Tensor<Float>(modeSizes: [projectedData.modeSizes[0]] + projections[0].modeSizes, repeatedValue: 0)
    currentReconstruction.indices = [projectedData.indices[0]] + projections[0].projectionVectors.map({$0.indices[0]})

    for p in 0..<featureCount {
        let pReconstruction = projections[p].project(projectedData[all, p...p])
        currentReconstruction = currentReconstruction + pReconstruction
    }

    return currentReconstruction
}
