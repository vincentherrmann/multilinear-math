//
//  LogisticRegression.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol ActivationFunction {
    func output(input: Tensor<Float>) -> Tensor<Float>
    func derivative(input: Tensor<Float>) -> Tensor<Float>
}

public class Sigmoid: ActivationFunction {
    public func output(input: Tensor<Float>) -> Tensor<Float> {
        return 1 / (1 + exp(-input))
    }
    public func derivative(input: Tensor<Float>) -> Tensor<Float> {
        let s = output(input)
        let sDiff = 1-s
        let result = s °* sDiff
        return result
    }
}

public class ReLU: ActivationFunction {
    public var secondarySlope: Float
    
    public init(secondarySlope: Float) {
        self.secondarySlope = secondarySlope
    }
    
    public func output(input: Tensor<Float>) -> Tensor<Float> {
        return Tensor<Float>(withPropertiesOf: input, values: input.values.map({max(secondarySlope*$0, $0)}))
    }
    public func derivative(input: Tensor<Float>) -> Tensor<Float> {
        return Tensor<Float>(withPropertiesOf: input, values: input.values.map({$0 > 0 ? 1.0 : secondarySlope}))
    }
}

public func sigmoid(t: Tensor<Float>) -> Tensor<Float> {
    return 1 / (1 + exp(-t))
}

public func sigmoidDerivative(t: Tensor<Float>) -> Tensor<Float> {
    let s = sigmoid(t)
    return s * (1 - s)
}

//public func logisticRegression(x x: Tensor<Float>, y: Tensor<Float>, regularize: Float = 0) -> Tensor<Float> {
//    
//    let example = TensorIndex.a
//    let feature = TensorIndex.b
//    
//    let exampleCount = x.modeSizes[0]
//    let featureCount = x.modeSizes[1]
//    
//    var samples = ones(exampleCount, featureCount + 1)
//    samples[all, 1...featureCount] = x
//    var parameters = Tensor<Float>(modeSizes: [featureCount + 1], repeatedValue: 0)
//    
//    let costFunction = {(theta: Tensor<Float>) -> Float in
//        let hypothesis = sigmoid(theta[feature] * samples[example, feature])
//        let t1 = (-y)[example] °* log(hypothesis)[example]
//        let t2 = (1 - y)[example] °* log(1 - hypothesis)[example]
//        let cost = vectorSummation(vectorSubtraction(t1.values, vectorB: t2.values)) / Float(exampleCount)
//        
//        var regularizeTheta = theta
//        regularizeTheta[[0]] = 0
//        let regularizedCost = cost + ((2*regularize/Float(exampleCount)) * (regularizeTheta[feature] * regularizeTheta[feature])).values[0]
//        
//        return regularizedCost
//    }
//    
//    let gradientFunction = {(theta: Tensor<Float>) -> Tensor<Float> in
//        let gradient = (1/Float(exampleCount)) * (sigmoid(theta[feature] * samples[example, feature]) - y[example]) * samples[example, feature]
//        
//        print("gradient: \(gradient)")
//        
//        var regularizeTheta = theta
//        regularizeTheta[[0]] = 0
//        let regularizedGradient = gradient[feature] + ((regularize/Float(exampleCount)) * regularizeTheta)[feature]
//        
//        return regularizedGradient
//    }
//    
//    gradientDescent(&parameters, costFunction: costFunction, gradientFunction: gradientFunction, updateRate: 0.5)
//    
//    return parameters
//}
//
//public class LogisticRegression: GradientOptimizable {
//    private let example = TensorIndex.a
//    private let feature = TensorIndex.b
//    
//    public var parameters: [Tensor<Float>]
//    public var mean: Tensor<Float>
//    public var standardDeviation: Tensor<Float>
//    public var regularize: Float
//    public var exampleCount: Float
//    
//    public init(x: Tensor<Float>, y: Tensor<Float>, regularize: Float = 0.5) {
//        self.parameters = [zeros(x.modeSizes[1] + 1)[feature]]
//        
//        let xNorm = normalize(x, overModes: [0])
//        self.mean = xNorm.mean
//        self.standardDeviation = xNorm.standardDeviation
//        self.regularize = regularize
//        self.exampleCount = Float(y.elementCount)
//        
//        var batch = ones(x.modeSizes[0], x.modeSizes[1]+1)
//        batch[all, 1...x.modeSizes[1]] = xNorm.normalizedTensor
//        
//        train(x: batch, y: y)
//    }
//    
//    public func cost(x x: Tensor<Float>, y: Tensor<Float>) -> Float {
//        let hypothesis = sigmoid(parameters[0] * x)
//        let t1 = -y °* log(hypothesis)
//        let t2 = (1-y) °* log(1-hypothesis)
//        let cost = vectorSummation((t1 - t2).values) / exampleCount
//        
//        var regularizeParameters = parameters[0]
//        regularizeParameters[[0]] = 0
//        let regularizeCost = cost + (2*regularize/exampleCount) * (regularizeParameters * regularizeParameters).values[0]
//        return regularizeCost
//    }
//    
//    public func gradient(x x: Tensor<Float>, y: Tensor<Float>) -> [Tensor<Float>] {
//        let gradient = (1/exampleCount) * (sigmoid(parameters[0] * x) - y) * x
//        print("gradient: \(gradient)")
//        
//        var regularizeParameters = parameters[0]
//        regularizeParameters[[0]] = 0
//        let regularizedGradient = gradient + ((regularize/exampleCount) * regularizeParameters)
//        
//        return [regularizedGradient]
//    }
//    
//    public func train(x x: Tensor<Float>, y: Tensor<Float>) {
//        batchGradientDescent(self, input: x[example, feature], output: y[example], updateRate: 0.1)
//    }
//}

public class LogisticRegressionEstimator: ParametricTensorFunction {
    public var parameters: [Tensor<Float>]
    var currentInput: Tensor<Float> = zeros()
    var currentPreactivations: Tensor<Float> = zeros()
    
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
        
        currentPreactivations = (currentInput * parameters[0]) + parameters[1]
        let currentHypothesis = sigmoid(currentPreactivations)
        return currentHypothesis
    }
    
    public func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let sigmoidGradient = Sigmoid().derivative(currentPreactivations)
        let preactivationGradient = sigmoidGradient °* gradientWrtOutput
        let parameter0Gradient = preactivationGradient * currentInput
        let parameter1Gradient = sum(preactivationGradient, overModes: [0])
        let inputGradient = sum(preactivationGradient * parameters[0], overModes: [0])
        
        return (inputGradient, [parameter0Gradient, parameter1Gradient])
    }
    
    public func updateParameters(subtrahends: [Tensor<Float>]) {
        parameters[0] = parameters[0] - subtrahends[0]
        parameters[1] = parameters[1] - subtrahends[1]
    }
}

/// Negative log likelihood cost for logistic regression
public class LogisticRegressionCost: CostFunction {
    public var estimator: ParametricTensorFunction
    public var regularizers: [ParameterRegularizer?] = [nil, nil]
    
    public init(featureCount: Int) {
        estimator = LogisticRegressionEstimator(featureCount: featureCount)
    }
    
    public func costForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.elementCount)
        
        let t1 = -target °* log(estimate)
        let t2 = (1-target) °* log(1-estimate)
        let cost = vectorSummation((t1-t2).values) / exampleCount
        
        return cost
    }
    
    public func gradientForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        if(estimate.indices != target.indices) {
            print("abstract indices of estimate and target should be the same!")
        }
        
        let g1 = target °* (1/estimate)
        let g2 = (1-target) °* (1 / (1-estimate))
        let gradient = -(g1 - g2)
        
        return gradient
    }
}

//public func oneVsAllClassification(x x: Tensor<Float>, y: Tensor<Float>, classCount: Int, regularize: Float = 0) -> Tensor<Float> {
//    
//    let exampleCount = x.modeSizes[0]
//    let featureCount = x.modeSizes[1]
//    
//    var yClasses = [zeros(classCount, exampleCount)]
//    for c in 0..<classCount {
//        yClasses[0][c...c, all] = Tensor<Float>(modeSizes: [exampleCount], values: y.values.map({Float($0 == Float(c))}))
//    }
//    
//    var outputData = [zeros(classCount, featureCount+1)]
//    
//    combine(x, forOuterModes: [], with: yClasses[0], forOuterModes: [0], outputData: &outputData,
//            calculate: ({ (indexA, indexB, outerIndex, sourceA, sourceB) -> [Tensor<Float>] in
//                let result = logisticRegression(x: sourceA, y: sourceB[slice: indexB])
//                return [result]
//    }),
//            writeOutput: ({ (indexA, indexB, outerIndex, inputData, outputData) in
//                outputData[0][slice: outerIndex + [all]] = inputData[0]
//    }))
//    
//    return (outputData[0])
//}