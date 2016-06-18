//
//  UMPCA.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

//paper: H. Lu, K. N. Plataniotis, and A. N. Venetsanopoulos "Uncorrelated Multilinear Principal Component Analysis for Unsupervised Multilinear Subspace Learning" November 2009

import Foundation

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
    
    public func project(tensor: Tensor<Float>, skipProjectionModes: [Int] = []) -> Tensor<Float> {
        var currentProjection = tensor
        for m in modeArray.removeValues(skipProjectionModes) {
            currentProjection = currentProjection * projectionVectors[m]
        }
        return currentProjection
    }
}

/// Elementary multilinear projection. Projects a tensor to a scalar
public struct EMP {
    public var modeSizes: [Int]
    public var projectionVectors: [[Float]]
    /// number of modes
    var modeCount: Int {
        get {
            return modeSizes.count
        }
    }
    /// simply Array(0..<modeCount)
    var modeArray: [Int] {
        get {
            return Array(0..<modeCount)
        }
    }
    public var projectionTensor: Tensor<Float> {
        get {
            var currentOuterProduct: [Float] = [1]
            var currentMatrixSize = MatrixSize(rows: 1, columns: 1)
            for thisVector in projectionVectors {
                let thisSize = thisVector.count
                currentOuterProduct = matrixMultiplication(matrixA: currentOuterProduct, sizeA: currentMatrixSize, matrixB: thisVector, sizeB: MatrixSize(rows: 1, columns: thisSize))
                currentMatrixSize = MatrixSize(rows: currentMatrixSize.rows * thisSize, columns: 1)
            }
            return Tensor<Float>(modeSizes: modeSizes, values: currentOuterProduct)
        }
    }
    
    public init(projectionVectors: [[Float]]) {
        let sizes: [Int] = projectionVectors.map({$0.count})
        self.modeSizes = sizes
        self.projectionVectors = projectionVectors
    }
    public init(withUnitNormVectorsForModeSizes modeSizes: [Int]) {
        projectionVectors = []
        for thisSize in modeSizes {
            projectionVectors.append([Float](count: thisSize, repeatedValue: 1 / Float(thisSize)))
        }
        self.modeSizes = modeSizes
    }
    
    public func projectionTensorWithoutModes(skipModes: [Int]) -> Tensor<Float> {
        var currentOuterProduct: [Float] = [1]
        var currentMatrixSize = MatrixSize(rows: 1, columns: 1)
        var sizes: [Int] = []
        for n in 0..<modeCount {
            if(skipModes.contains(n)) {
                continue
            }
            currentOuterProduct = matrixMultiplication(matrixA: currentOuterProduct, sizeA: currentMatrixSize, matrixB: projectionVectors[n], sizeB: MatrixSize(rows: 1, columns: modeSizes[n]))
            currentMatrixSize = MatrixSize(rows: currentMatrixSize.rows * modeSizes[n], columns: 1)
            sizes.append(modeSizes[n])
        }
        return Tensor<Float>(modeSizes: sizes, values: currentOuterProduct)
    }
    
    //???
    public func inverse() -> EMP {
        var inverse: [[Float]] = []
        for thisVector in projectionVectors {
            let scale = 1 / Float(thisVector.count)
            let vectorInverse = thisVector.map({($0 == 0) ? 0 : scale/$0})
            inverse.append(vectorInverse)
        }
        return EMP(projectionVectors: inverse)
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
public func uncorrelatedMPCA(inputData: Tensor<Float>, featureCount: Int) -> (projectedData: Tensor<Float>, projections: [ElementaryMultilinearProjection]) {
    
    let data = inputData.uniquelyIndexed()
    let additionalIndices = TensorIndex.uniqueIndexArray(5, excludedIndices: data.indices)
    let (sample, feature, featureT, nMode, nModeT, nModeT2) = (data.indices[0], additionalIndices[0], additionalIndices[1], additionalIndices[2], additionalIndices[3], additionalIndices[4])
    
    //upper bound for featureCount: min(data.modeSizes)
    let maxFeatureCount = data.modeSizes.minElement()!
    assert(featureCount <= maxFeatureCount, "Cannot construct \(featureCount) uncorrelated features from data tensor with mode sizes \(data.modeSizes)")
    
    //data: [m, d0, d1, ...]
    //projectedData: [m, p]
    let maxLoops = 20
    let projectionDifferenceThreshold: Float = 0.001
    let sampleCount = data.modeSizes[0]
    let sampleModeCount = data.modeCount-1
    //let empModeSizes = Array(data.modeSizes[1..<data.modeCount])
    
    var projections: [ElementaryMultilinearProjection] = [] // [u0[p, d0], u1[p, d1], ..., uN-1[p, dN-1]]
    var projectedData = Tensor<Float>(modeSizes: [0, sampleCount], values: [])  //[p, m]
    projectedData.indices = [feature, sample]
    
    for p in 0..<featureCount { //calculate the pth uncorrelated feature
        
        var currentEMP = ElementaryMultilinearProjection(withUnitNormVectorsforTensor: data, onlyModes: Array(1..<data.modeCount))
        //var currentEMP = EMP(withUnitNormVectorsForModeSizes: empModeSizes) //the emp for mode p
        var currentG: Tensor<Float>! //vector of all samples projected to feature p
        var projectionScatter: Float = 0
        var newScatter: Float = FLT_MIN
        
        print("")
        print("calculating feature \(p) projection")
        
        for _ in 0..<maxLoops { //optimization
            projectionScatter = newScatter
            
            for n in 0..<sampleModeCount { //calculate the nth vector of the pth EMP
                let modeSize = data.modeSizes[n+1]
                
                //let partialProjectionTensor = currentEMP.projectionTensorWithoutModes([n])
                //let partialProjection = multiply(a: data, remainingModesA: [0, n+1], b: partialProjectionTensor, remainingModesB: []) //[m, d_n]
                let partialProjection = currentEMP.project(data, skipProjectionModes: [n])[sample, nMode] //[m, d_n]
                let scatterMatrix = partialProjection * partialProjection[sample, nModeT] //[nMode, nModeT]
                
                var optimizationMatrix: Tensor<Float>
                
                if(p > 0) {
//                    let yg = partialProjection[sample, nMode] * projectedData[feature, sample] // [nMode, feature]
//                    let phi = yg[nMode, feature] * yg[nMode, featureT] // [feature, featureT]
//                    let phiInverse = inverse(phi, rowMode: 0, columnMode: 1)
//                    let ygPhi = yg[nMode, feature] * phiInverse[feature, featureT] // [nMode, featureT]
//                    let product = ygPhi[nMode, feature] * yg[nModeT, feature] // [nMode, nModeT]
//                    let unitTensor = Tensor<Float>(diagonalWithModeSizes: [modeSize, modeSize])[nMode, nModeT]
//                    let psi = unitTensor - product // [nMode, nModeT]
//                    
//                    optimizationMatrix = psi[nMode, nModeT2] * scatterMatrix[nModeT2, nModeT] // [nMode, nModeT]
                    
                    let pp = partialProjection[sample, nMode] * projectedData[feature, sample] // [nMode, feature]
                    let pi = inverse(pp[nMode, feature] * pp[nMode, featureT], rowMode: 0, columnMode: 1) // [feature, featureT]
                    let pm = (pp * pi) * pp[nModeT, featureT] // [nMode, nModeT]
                    let ps = Tensor<Float>(diagonalWithModeSizes: [modeSize, modeSize])[nMode, nModeT] - pm
                    
                    optimizationMatrix = ps[nMode, nModeT2] * scatterMatrix[nModeT2, nModeT] // [nMode, nModeT]

//                    let yg = multiply(a: partialProjection, summationModesA: [0], b: projectedData, summationModesB: [1]) //[d_n, p-1]
//                    let phi = multiply(a: yg, summationModesA: [0], b: yg, summationModesB: [0]) //[p-1, p-1]
//                    let phiInverse = inverse(phi, rowMode: 0, columnMode: 1)
//                    let ygPhi = multiply(a: yg, summationModesA: [1], b: phiInverse, summationModesB: [0]) //[d_n, p-1]
//                    var product = multiply(a: ygPhi, summationModesA: [1], b: yg, summationModesB: [1]) //[d_n, d_n]
//                    var unitTensor = Tensor<Float>(diagonalWithModeSizes: [modeSize, modeSize])
//                    let psi = substract(a: unitTensor, commonModesA: [0, 1], b: product, commonModesB: [0, 1])
//                    
//                    optimizationMatrix = multiply(a: psi, summationModesA: [1], b: scatterMatrix, summationModesB: [0]) //[d_, d_n]
                } else {
                    optimizationMatrix = scatterMatrix
                }
                
                let eigen = eigendecomposition(optimizationMatrix.values, size: MatrixSize(rows: modeSize, columns: modeSize))
                let u = eigen.eigenvectors[0..<modeSize]
                print("mode \(n) biggest eigenvalue: \(eigen.eigenvalues[0])")
                
                currentEMP.projectionVectors[n].values = Array(u)
            } // n-loop
            
            
            currentG = currentEMP.project(data)
            //currentG = multiply(a: data, remainingModesA: [0], b: currentEMP.projectionTensor, remainingModesB: [])
            newScatter = (currentG * currentG).values[0]
            
            if((newScatter - projectionScatter) / projectionScatter < projectionDifferenceThreshold) {
                break
            } else {
                print("current scatter: \(newScatter)")
            }
        } // _-loop (optimization)
        
        print("final projectionScatter of feature \(p): \(newScatter)")
        projectedData.modeSizes[0] = p+1
        projectedData.values.appendContentsOf(currentG.values)
        projections.append(currentEMP)
        
    } // p-loop
    
    return (projectedData.reorderModes([1, 0]), projections)
}

public func uncorrelatedMPCAProject(data: Tensor<Float>, projections: [ElementaryMultilinearProjection]) -> Tensor<Float> {
    
    let featureCount = projections.count
    var projectedData = Tensor<Float>(modeSizes: [data.modeSizes[0], featureCount], repeatedValue: 0)
    projectedData.indices[0] = data.indices[0]
    
    for p in 0..<featureCount {
        projectedData[all, p...p] = projections[p].project(data)
    }
    
    return projectedData
}

public func uncorrelatedMPCAReconstruct(projectedData: Tensor<Float>, projections: [ElementaryMultilinearProjection]) -> Tensor<Float> {
    
    let featureCount = projections.count
    var currentReconstruction: Tensor<Float> = Tensor<Float>(modeSizes: [projectedData.modeSizes[0]] + projections[0].modeSizes, repeatedValue: 0)
    currentReconstruction.indices = [projectedData.indices[0]] + projections[0].projectionVectors.map({$0.indices[0]})
    
    for p in 0..<featureCount {
        let pReconstruction = projections[p].project(projectedData[all, p...p])
        currentReconstruction = currentReconstruction + pReconstruction
//        let pReconstruction = multiply(a: projectedData[all, p...p], remainingModesA: [0], b: projections[p].projectionTensor, summationModesB: [])
//        currentReconstruction = add(a: currentReconstruction, commonModesA: currentReconstruction.modeArray, b: pReconstruction, commonModesB: pReconstruction.modeArray)
    }
    
    return currentReconstruction
}
