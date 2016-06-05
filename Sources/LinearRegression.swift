//
//  LinearRegression.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 25.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func linearRegression(x x: Tensor<Float>, y: Tensor<Float>) -> Tensor<Float> {
    
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

public class LinearRegressionEstimator: ParametricTensorFunction {
    public var parameters: [Tensor<Float>]
    var currentInput: Tensor<Float> = zeros()
    
    private let example = TensorIndex.a
    private let feature = TensorIndex.b
    
    public init(featureCount: Int) {
        parameters = [zeros(featureCount), zeros()]
        parameters[0].indices = [feature]
    }
    
    public func output(input: Tensor<Float>) -> Tensor<Float> {
        if(input.modeCount == 1) {
            currentInput = Tensor<Float>(modeSizes: [1, input.modeSizes[0]], values: input.values)
            currentInput.indices = [example, feature]
        } else {
            currentInput = input[example, feature]
        }
        
        let hypothesis = (currentInput * parameters[0]) + parameters[1]
        return hypothesis
    }
    
    public func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let parameter0Gradient = gradientWrtOutput * currentInput
        let parameter1Gradient = sum(gradientWrtOutput, overModes: [0])
        let inputGradient = sum(gradientWrtOutput * parameters[0], overModes: [0])
        
        return (inputGradient, [parameter0Gradient, parameter1Gradient])
    }
    
    public func updateParameters(subtrahends: [Tensor<Float>]) {
        parameters[0] = parameters[0] - subtrahends[0]
        parameters[1] = parameters[1] - subtrahends[1]
    }
}

/// Squared error cost for linear regression
public class LinearRegressionCost: CostFunction {
    public var estimator: ParametricTensorFunction
    public var regularizers: [ParameterRegularizer?] = [nil, nil]
    
    public init(featureCount: Int) {
        estimator = LinearRegressionEstimator(featureCount: featureCount)
    }
    
    public func costForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.elementCount)
        
        let distance = estimate - target
        let cost = (0.5 / exampleCount) * (distance * distance)
        
        return cost.values[0]
    }
    
    public func gradientForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        if(estimate.indices != target.indices) {
            print("abstract indices of estimate and target should be the same!")
        }
        let exampleCount = Float(target.elementCount)
        let gradient = (1/exampleCount) * (estimate - target)

        return gradient
    }
}

//public func linearRegressionGD(x x: Tensor<Float>, y: Tensor<Float>) -> (parameters: Tensor<Float>, mean: Tensor<Float>, deviation: Tensor<Float>) {
//    
//    let example = TensorIndex.a
//    let feature = TensorIndex.b
//    
//    let exampleCount = x.modeSizes[0]
//    let featureCount = x.modeSizes[1]
//    
//    let xNorm = normalize(x, overModes: [0])
//    
//    var samples = Tensor<Float>(modeSizes: [exampleCount, featureCount + 1], repeatedValue: 1)
//    samples[all, 1...featureCount] = xNorm.normalizedTensor
//    var parameters = Tensor<Float>(modeSizes: [featureCount + 1], repeatedValue: 0)
//    
//    let costFunction = {(theta: Tensor<Float>) -> Float in
//        let hypothesis = theta[feature] * samples[example, feature]
//        let distance = hypothesis[example] - y[example]
//        //let cost = (0.5/Float(exampleCount)) * vectorSummation(vectorSquaring(distance.values))
//        let cost = (0.5/Float(exampleCount)) * (distance[example] * distance[example])
//        return cost.values[0]
//    }
//    
//    let gradientFunction = {(theta: Tensor<Float>) -> Tensor<Float> in
//        let gradient = (1/Float(exampleCount)) * ((theta[feature] * samples[example, feature]) - y[example]) * samples[example, feature]
//        return gradient
//    }
//    
//    gradientDescent(&parameters, costFunction: costFunction, gradientFunction: gradientFunction, updateRate: 0.1)
//    
//    return (parameters, xNorm.mean, xNorm.standardDeviation)
//}
//
//public class LinearRegression: GradientOptimizable {
//    private let example = TensorIndex.a
//    private let feature = TensorIndex.b
//    
//    public var parameters: [Tensor<Float>]
//    public var mean: Tensor<Float>
//    public var standardDeviation: Tensor<Float>
//    
//    public init(x: Tensor<Float>, y: Tensor<Float>) {
//        self.parameters = [zeros(x.modeSizes[1] + 1)[feature]]
//        
//        let xNorm = normalize(x, overModes: [0])
//        self.mean = xNorm.mean
//        self.standardDeviation = xNorm.standardDeviation
//        
//        var batch = ones(x.modeSizes[0], x.modeSizes[1]+1)
//        batch[all, 1...x.modeSizes[1]] = xNorm.normalizedTensor
//        
//        train(x: batch, y: y)
//    }
//    
//    public func cost(x x: Tensor<Float>, y: Tensor<Float>) -> Float {
//        let hypothesis = parameters[0] * x
//        let distance = hypothesis - y
//        let cost = (0.5/Float(x.modeSizes[0])) * (distance * distance)
//        return cost.values[0]
//    }
//    
//    public func gradient(x x: Tensor<Float>, y: Tensor<Float>) -> [Tensor<Float>] {
//        let gradient = (1/Float(x.modeSizes[0])) * ((parameters[0] * x) - y) * x
//        return [gradient]
//    }
//    
//    public func train(x x: Tensor<Float>, y: Tensor<Float>) {
//        batchGradientDescent(self, input: x[example, feature], output: y[example], updateRate: 0.1)
//    }
//}

public func gradientDescent(inout parameters: Tensor<Float>, costFunction: (Tensor<Float> -> Float), gradientFunction: Tensor<Float> -> Tensor<Float>, updateRate: Float) {
    
    var cost = FLT_MAX
    
    for _ in 0..<1000 {
        let currentCost = costFunction(parameters)
        print("gradient descent - current cost: \(currentCost)")
        
        if(abs(cost - currentCost) < 0.001) {
            break
        }
        
        cost = currentCost
        
        parameters = parameters[TensorIndex.a] - (updateRate * gradientFunction(parameters))[TensorIndex.a]
    }
}