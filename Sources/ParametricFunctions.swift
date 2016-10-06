//
//  ParametricFunctions.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 19.06.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol ParametricTensorFunction {
    var parameters: [Tensor<Float>] {get set}
    
    func output(_ input: Tensor<Float>) -> Tensor<Float>
    func gradients(_ gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>])
    /// Substract the given values from the parameters. For gradient descent optimization algorithms
    mutating func updateParameters(_ subtrahends: [Tensor<Float>])
}

public protocol CostFunction: class {
    var estimator: ParametricTensorFunction {get set}
    var regularizers: [ParameterRegularizer?] {get}
    
    func costForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Float
    func gradientForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float>
}

public extension CostFunction {
    func updateParameters(_ subtrahends: [Tensor<Float>]) {
        let parameterRegularizations = estimator.parameters.combineWith(regularizers, combineFunction: { (parameter, regularizer) -> Tensor<Float> in
            if let r = regularizer {
                return r.regularizationGradient(parameter)
            } else {
                return Tensor<Float>(withPropertiesOf: parameter, repeatedValue: 0)
            }
        })
        
        estimator.updateParameters(subtrahends.combineWith(parameterRegularizations, combineFunction: {add(a: $0, outerModesA: [], b: $1, outerModesB: [])}))
    }
    
    func regularizedCostForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let cost = self.costForEstimate(estimate, target: target)
        
        let regularizationCosts = estimator.parameters.combineWith(regularizers, combineFunction: { (parameter, regularizer) -> Float in
            return (regularizer != nil) ? regularizer!.regularizationCost(parameter) : 0
        })
        
        return cost + regularizationCosts.reduce(0, {$0 + $1})
    }
    
    
    public func numericalGradients(_ input: Tensor<Float>, target: Tensor<Float>, epsilon: Float = 0.01) -> [Tensor<Float>] {
        let estimate = estimator.output(input)
        let cost = costForEstimate(estimate, target: target)
        
        //check gradients
        var numericalGradients: [Tensor<Float>] = estimator.parameters
        
        for p in 0..<estimator.parameters.count {
            for i in 0..<estimator.parameters[p].elementCount {
                //change one single element in the parameters
                let originalValue = estimator.parameters[p].getWithFlatIndex(i)
                
                // + epsilon
                let plusEpsilonValue = originalValue + epsilon
                estimator.parameters[p].set(plusEpsilonValue, atFlatIndex: i)
                //compute the numerical gradient value
                let plusEpsilonEstimate = estimator.output(input)
                let plusEpsilonCost = costForEstimate(plusEpsilonEstimate, target: target)
                
                // - epsilon
                let minusEpsilonValue = originalValue - epsilon
                estimator.parameters[p].set(minusEpsilonValue, atFlatIndex: i)
                //compute the numerical gradient value
                let minusEpsilonEstimate = estimator.output(input)
                let minusEpsilonCost = costForEstimate(minusEpsilonEstimate, target: target)
                
                let gradientValue = (plusEpsilonCost - minusEpsilonCost) / (2*epsilon)
                numericalGradients[p].set(gradientValue, atFlatIndex: i)
                
                //reset the estimator parameter
                estimator.parameters[p].set(originalValue, atFlatIndex: i)
            }
        }
        
        return numericalGradients
    }
}

public protocol ParameterRegularizer {
    func regularizationCost(_ parameter: Tensor<Float>) -> Float
    func regularizationGradient(_ parameter: Tensor<Float>) -> Tensor<Float>
}

public struct ParameterDecay: ParameterRegularizer {
    public var regularizationParameter: Float
    
    public init(decayRate: Float) {
        regularizationParameter = decayRate
    }
    
    public func regularizationCost(_ parameter: Tensor<Float>) -> Float {
        return multiply(a: parameter, remainingModesA: [], b: parameter, remainingModesB: []).values[0] * regularizationParameter
    }
    public func regularizationGradient(_ parameter: Tensor<Float>) -> Tensor<Float> {
        return parameter * regularizationParameter
    }
}

open class SquaredErrorCost: CostFunction {
    open var estimator: ParametricTensorFunction
    open var regularizers: [ParameterRegularizer?]
    
    public init(forEstimator: ParametricTensorFunction) {
        estimator = forEstimator
        regularizers = [ParameterRegularizer?](repeating: nil, count: estimator.parameters.count)
    }
    
    open func costForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.modeCount > 1 ? target.modeSizes[0] : 1)
        
        let error = substract(a: target, outerModesA: [], b: estimate, outerModesB: [])
        let cost = multiply(a: error, remainingModesA: [], b: error, remainingModesB: [])
        let scaledCost = cost.values[0] / exampleCount
        
        return cost.values[0] / exampleCount
    }
    
    open func gradientForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        let gradient = 2 * substract(a: estimate, outerModesA: [], b: target, outerModesB: [])
        return gradient
    }
}

open class NegLogClassificationCost: CostFunction {
    open var estimator: ParametricTensorFunction
    open var regularizers: [ParameterRegularizer?] {
        get {
            return [ParameterRegularizer?](repeating: nil, count: estimator.parameters.count)
        }
    }
    
    public init(forEstimator: ParametricTensorFunction) {
        estimator = forEstimator
    }
    
    open func costForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.modeCount > 1 ? target.modeSizes[0] : 1)
        
        let t1 = -target °* log(estimate)
        let t2 = (1-target) °* log(1-estimate)
        let cost = vectorSummation((t1-t2).values) / exampleCount
        
        return cost
    }
    
    open func gradientForEstimate(_ estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        let g1 = target °* (1/estimate)
        let g2 = (1-target) °* (1 / (1-estimate))
        let gradient = -(g1 - g2)
        
        return gradient
    }
}
