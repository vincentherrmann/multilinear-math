//
//  LogisticRegression.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func sigmoid(t: Tensor<Float>) -> Tensor<Float> {
    return 1 / (1 + exp(-t))
}

public func sigmoidDerivative(t: Tensor<Float>) -> Tensor<Float> {
    let s = sigmoid(t)
    return s * (1 - s)
}

public func logisticRegression(x x: Tensor<Float>, y: Tensor<Float>, regularize: Float = 0) -> Tensor<Float> {
    
    let example = TensorIndex.a
    let feature = TensorIndex.b
    
    let exampleCount = x.modeSizes[0]
    let featureCount = x.modeSizes[1]
    
    var samples = ones(exampleCount, featureCount + 1)
    samples[all, 1...featureCount] = x
    var parameters = Tensor<Float>(modeSizes: [featureCount + 1], repeatedValue: 0)
    
    let costFunction = {(theta: Tensor<Float>) -> Float in
        let hypothesis = sigmoid(theta[feature] * samples[example, feature])
        let t1 = (-y)[example] °* log(hypothesis)[example]
        let t2 = (1 - y)[example] °* log(1 - hypothesis)[example]
        let cost = vectorSummation(vectorSubtraction(t1.values, vectorB: t2.values)) / Float(exampleCount)
        
        var regularizeTheta = theta
        regularizeTheta[[0]] = 0
        let regularizedCost = cost + ((2*regularize/Float(exampleCount)) * (regularizeTheta[feature] * regularizeTheta[feature])).values[0]
        
        return regularizedCost
    }
    
    let gradientFunction = {(theta: Tensor<Float>) -> Tensor<Float> in
        let gradient = (1/Float(exampleCount)) * (sigmoid(theta[feature] * samples[example, feature]) - y[example]) * samples[example, feature]
        
        var regularizeTheta = theta
        regularizeTheta[[0]] = 0
        let regularizedGradient = gradient[feature] + ((regularize/Float(exampleCount)) * regularizeTheta)[feature]
        
        return regularizedGradient
    }
    
    gradientDescent(&parameters, costFunction: costFunction, gradientFunction: gradientFunction, updateRate: 0.5)
    
    return parameters
}

public func oneVsAllClassification(x x: Tensor<Float>, y: Tensor<Float>, classCount: Int, regularize: Float = 0) -> Tensor<Float> {
    
    let exampleCount = x.modeSizes[0]
    let featureCount = x.modeSizes[1]
    
    var yClasses = [zeros(classCount, exampleCount)]
    for c in 0..<classCount {
        yClasses[0][c...c, all] = Tensor<Float>(modeSizes: [exampleCount], values: y.values.map({Float($0 == Float(c))}))
    }
    
    var outputData = [zeros(classCount, featureCount+1)]
    
    combine(x, forOuterModes: [], with: yClasses[0], forOuterModes: [0], outputData: &outputData,
            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
                let result = logisticRegression(x: sourceA, y: sourceB[slice: indexB])
                return [result]
    }),
            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
                outputData[0][slice: outerIndex + [all]] = inputData[0]
    }))
    
    return (outputData[0])
}