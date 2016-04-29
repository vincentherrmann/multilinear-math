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

public func logisticRegression(x x: Tensor<Float>, y: Tensor<Float>) -> (parameters: Tensor<Float>, mean: Tensor<Float>, deviation: Tensor<Float>) {
    
    let example = TensorIndex.a
    let feature = TensorIndex.b
    
    let exampleCount = x.modeSizes[0]
    let featureCount = x.modeSizes[1]
    
    let xNorm = normalize(x, overModes: [0])
    
    var samples = Tensor<Float>(modeSizes: [exampleCount, featureCount + 1], repeatedValue: 1)
    samples[all, 1...featureCount] = xNorm.normalizedTensor
    var parameters = Tensor<Float>(modeSizes: [featureCount + 1], repeatedValue: 0)
    
    let costFunction = {(theta: Tensor<Float>) -> Float in
        let hypothesis = sigmoid(theta[feature] * samples[example, feature])
        let t1 = (-y)[example] °* log(hypothesis)[example]
        let t2 = (1 - y)[example] °* log(1 - hypothesis)[example]
        let cost = vectorSummation(vectorSubtraction(t1.values, vectorB: t2.values)) / Float(exampleCount)
        return cost
    }
    
    let gradientFunction = {(theta: Tensor<Float>) -> Tensor<Float> in
        let gradient = (1/Float(exampleCount)) * (sigmoid(theta[feature] * samples[example, feature]) - y[example]) * samples[example, feature]
        return gradient
    }
    
    gradientDescent(&parameters, costFunction: costFunction, gradientFunction: gradientFunction, updateRate: 0.5)
    
    return (parameters, xNorm.mean, xNorm.standardDeviation)
}