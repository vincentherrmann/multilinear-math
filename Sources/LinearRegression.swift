//
//  LinearRegression.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 25.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func linearRegression(x: Tensor<Float>, y: Tensor<Float>) -> Tensor<Float> {
    
    let example = TensorIndex.a
    let feature = TensorIndex.b
    
    let exampleCount = x.modeSizes[0]
    let featureCount = x.modeSizes[1]
    
    var samples = Tensor<Float>(modeSizes: [exampleCount, featureCount + 1], repeatedValue: 1)
    samples[all, 1...featureCount] = x
    
    // formula: w = (X^T * X)^-1 * X * y
    let sampleCovariance = samples[example, feature] * samples[example, .k]
    let inverseCovariance = inverse(sampleCovariance, rowMode: 0, columnMode: 1)
    let parameters = inverseCovariance[feature, .k] * samples[example, .k] * y[example]

    return parameters
}

open class LinearRegressionEstimator: ParametricTensorFunction {
    open var parameters: [Tensor<Float>]
    var currentInput: Tensor<Float> = zeros()
    
    fileprivate let example = TensorIndex.a
    fileprivate let feature = TensorIndex.b
    
    public init(featureCount: Int) {
        parameters = [zeros(featureCount), zeros()]
        parameters[0].indices = [feature]
    }
    
    open func output(_ input: Tensor<Float>) -> Tensor<Float> {
        if(input.modeCount == 1) {
            currentInput = Tensor<Float>(modeSizes: [1, input.modeSizes[0]], values: input.values)
            currentInput.indices = [example, feature]
        } else {
            currentInput = input[example, feature]
        }
        
        let hypothesis = (currentInput * parameters[0]) + parameters[1]
        return hypothesis
    }
    
    open func gradients(_ gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let parameter0Gradient = gradientWrtOutput * currentInput
        let parameter1Gradient = sum(gradientWrtOutput, overModes: [0])
        let inputGradient = sum(gradientWrtOutput * parameters[0], overModes: [0])
        
        return (inputGradient, [parameter0Gradient, parameter1Gradient])
    }
    
    open func updateParameters(_ subtrahends: [Tensor<Float>]) {
        parameters[0] = parameters[0] - subtrahends[0]
        parameters[1] = parameters[1] - subtrahends[1]
    }
}

/// Squared error cost for linear regression
open class LinearRegressionCost: CostFunction {
    open var estimator: ParametricTensorFunction
    open var regularizers: [ParameterRegularizer?] = [nil, nil]
    
    public init(featureCount: Int) {
        estimator = LinearRegressionEstimator(featureCount: featureCount)
    }
    
    open func costForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.elementCount)
        
        let distance = estimate - target
        let cost = (0.5 / exampleCount) * (distance * distance)
        
        return cost.values[0]
    }
    
    open func gradientForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        if(estimate.indices != target.indices) {
            print("abstract indices of estimate and target should be the same!")
        }
        let exampleCount = Float(target.elementCount)
        let gradient = (1/exampleCount) * (estimate - target)

        return gradient
    }
}
