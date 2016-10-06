//
//  LogisticRegression.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

open class LogisticRegressionEstimator: ParametricTensorFunction {
    open var parameters: [Tensor<Float>]
    var currentInput: Tensor<Float> = zeros()
    var currentPreactivations: Tensor<Float> = zeros()
    
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
        
        currentPreactivations = (currentInput * parameters[0]) + parameters[1]
        let currentHypothesis = Sigmoid().output(currentPreactivations)
        return currentHypothesis
    }
    
    open func gradients(_ gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let sigmoidGradient = Sigmoid().derivative(currentPreactivations)
        let preactivationGradient = sigmoidGradient °* gradientWrtOutput
        let parameter0Gradient = preactivationGradient * currentInput
        let parameter1Gradient = sum(preactivationGradient, overModes: [0])
        let inputGradient = sum(preactivationGradient * parameters[0], overModes: [0])
        
        return (inputGradient, [parameter0Gradient, parameter1Gradient])
    }
    
    open func updateParameters(_ subtrahends: [Tensor<Float>]) {
        parameters[0] = parameters[0] - subtrahends[0]
        parameters[1] = parameters[1] - subtrahends[1]
    }
}

/// Negative log likelihood cost for logistic regression
open class LogisticRegressionCost: CostFunction {
    open var estimator: ParametricTensorFunction
    open var regularizers: [ParameterRegularizer?] = [nil, nil]
    
    public init(featureCount: Int) {
        estimator = LogisticRegressionEstimator(featureCount: featureCount)
    }
    
    open func costForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.elementCount)
        
        let t1 = -target °* log(estimate)
        let t2 = (1-target) °* log(1-estimate)
        let cost = vectorSummation((t1-t2).values) / exampleCount
        
        return cost
    }
    
    open func gradientForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
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
