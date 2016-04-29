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
public func uncorrelatedMPCA(data: Tensor<Float>, featureCount: Int) -> (projectedData: Tensor<Float>, projections: [EMP]) {
    //upper bound for featureCount: min(data.modeSizes)
    let maxFeatureCount = data.modeSizes.minElement()!
    assert(featureCount <= maxFeatureCount, "Cannot construct \(featureCount) uncorrelated features from data tensor with mode sizes \(data.modeSizes)")
    
    //data: [m, d0, d1, ...]
    //projectedData: [m, p]
    let maxLoops = 20
    let projectionDifferenceThreshold: Float = 0.001
    let sampleCount = data.modeSizes[0]
    let sampleModeCount = data.modeCount-1
    let empModeSizes = Array(data.modeSizes[1..<data.modeCount])
    
    var projections: [EMP] = [] // [u0[p, d0], u1[p, d1], ..., uN-1[p, dN-1]]
    var projectedData = Tensor<Float>(modeSizes: [0, sampleCount], values: [])  //[p, m]
    
    
    for p in 0..<featureCount { //calculate the pth uncorrelated feature
        
        var currentEMP = EMP(withUnitNormVectorsForModeSizes: empModeSizes) //the emp for mode p
        var currentG: Tensor<Float>! //vector of all samples projected to feature p
        var projectionScatter: Float = 0
        var newScatter: Float = FLT_MIN
        
        print("")
        print("calculating feature \(p) projection")
        
        for _ in 0..<maxLoops { //optimization
            projectionScatter = newScatter
            
            for n in 0..<sampleModeCount { //calculate the nth vector of the pth EMP
                let modeSize = data.modeSizes[n+1]
                
                let partialProjectionTensor = currentEMP.projectionTensorWithoutModes([n])
                let partialProjection = multiply(a: data, remainingModesA: [0, n+1], b: partialProjectionTensor, remainingModesB: []) //[m, d_n]
                
                let scatterMatrix = multiply(a: partialProjection, summationModesA: [0], b: partialProjection, summationModesB: [0]) //[d_n, d_n]
                
                var optimizationMatrix: Tensor<Float>
                
                if(p > 0) {
                    //
                    let yg = multiply(a: partialProjection, summationModesA: [0], b: projectedData, summationModesB: [1]) //[d_n, p-1]
                    let phi = multiply(a: yg, summationModesA: [0], b: yg, summationModesB: [0]) //[p-1, p-1]
                    let phiInverse = inverse(phi, rowMode: 0, columnMode: 1)
                    let ygPhi = multiply(a: yg, summationModesA: [1], b: phiInverse, summationModesB: [0]) //[d_n, p-1]
                    var product = multiply(a: ygPhi, summationModesA: [1], b: yg, summationModesB: [1]) //[d_n, d_n]
                    var unitTensor = Tensor<Float>(diagonalWithModeSizes: [modeSize, modeSize])
                    let psi = substract(a: unitTensor, commonModesA: [0, 1], b: product, commonModesB: [0, 1])
                    //let psi = unitTensor[.a, .b] - product[.a, .b]
                    
                    optimizationMatrix = multiply(a: psi, summationModesA: [1], b: scatterMatrix, summationModesB: [0]) //[d_, d_n]
                } else {
                    optimizationMatrix = scatterMatrix
                }
                
                let eigen = eigendecomposition(optimizationMatrix.values, size: MatrixSize(rows: modeSize, columns: modeSize))
                let u = eigen.eigenvectors[0..<modeSize]
                print("mode \(n) biggest eigenvalue: \(eigen.eigenvalues[0])")
                
                currentEMP.projectionVectors[n] = Array(u)
            } // n-loop
            
            currentG = multiply(a: data, remainingModesA: [0], b: currentEMP.projectionTensor, remainingModesB: [])
            newScatter = scatterOf(currentG)
            
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

public func uncorrelatedMPCAProject(data: Tensor<Float>, projections: [EMP]) -> Tensor<Float> {
    
    let featureCount = projections.count
    var projectedData = Tensor<Float>(modeSizes: [data.modeSizes[0], featureCount], repeatedValue: 0)
    
    for p in 0..<featureCount {
        projectedData[all, p...p] = multiply(a: data, remainingModesA: [0], b: projections[p].projectionTensor, remainingModesB: [])
    }
    
    return projectedData
}

public func uncorrelatedMPCAReconstruct(projectedData: Tensor<Float>, projections: [EMP]) -> Tensor<Float> {
    
    let featureCount = projections.count
    var currentReconstruction: Tensor<Float> = Tensor<Float>(modeSizes: [projectedData.modeSizes[0]] + projections[0].modeSizes, repeatedValue: 0)
    
    for p in 0..<featureCount {
        let pReconstruction = multiply(a: projectedData[all, p...p], remainingModesA: [0], b: projections[p].projectionTensor, summationModesB: [])
        currentReconstruction = add(a: currentReconstruction, commonModesA: currentReconstruction.modeArray, b: pReconstruction, commonModesB: pReconstruction.modeArray)
    }
    
    return currentReconstruction
}
