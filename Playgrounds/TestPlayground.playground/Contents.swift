//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let inputData = zeros(20, 4, 5)
let projectionModeSizes = [3, 3]

let data = inputData.uniquelyIndexed()
let sampleModeCount = data.modeCount-1

var projectionMatrices: [Tensor<Float>] = []
let projectionModeIndices = TensorIndex.uniqueIndexArray(sampleModeCount, excludedIndices: data.indices)

for n in 0..<sampleModeCount {
    let modeSizes = [projectionModeSizes[n], data.modeSizes[n+1]]
    var thisProjectionMatrix = Tensor<Float>(diagonalWithModeSizes: modeSizes, repeatedValue: 1.0)
    thisProjectionMatrix.indices = [projectionModeIndices[n], data.indices[n+1]]
    projectionMatrices.append(thisProjectionMatrix)
}

public func multilinearPCAProjectionP(data data: Tensor<Float>, projectionMatrices: [Tensor<Float>], doNotProjectModes: [Int] = []) -> Tensor<Float> {
    
    var currentData = data
    for n in 0..<data.modeCount-1 {
        if(doNotProjectModes.contains(n) == false) {
            currentData = currentData * projectionMatrices[n]
        } else {
            //do not project mode n, just reorder the data (as if the projectionMatrix was the identity matrix)
            currentData = currentData.reorderModes([0] + Array(2..<data.modeCount) + [1])
        }
    }
    
    return currentData
}

var projectedData = multilinearPCAProjectionP(data: data, projectionMatrices: projectionMatrices)
var projectionScatter: Float = 0
var newScatter = (projectedData * projectedData).values[0]

//Local Optimization
for _ in 0..<1 {
    projectionScatter = newScatter
    
    
}
