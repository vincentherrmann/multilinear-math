//
//  NeuralNetwork.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 30.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol ParametricTensorFunction {
    var parameters: [Tensor<Float>] {get set}
    
    func output(input: Tensor<Float>) -> Tensor<Float>
    func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>])
    /// Substract the given values from the parameters. For gradient descent optimization algorithms
    mutating func updateParameters(subtrahends: [Tensor<Float>])
}

public protocol ParameterRegularizer {
    func regularizationCost(parameter: Tensor<Float>) -> Float
    func regularizationGradient(parameter: Tensor<Float>) -> Tensor<Float>
}

public struct ParameterDecay: ParameterRegularizer {
    public var regularizationParameter: Float
    
    public func regularizationCost(parameter: Tensor<Float>) -> Float {
        return multiply(a: parameter, remainingModesA: [], b: parameter, remainingModesB: []).values[0] * regularizationParameter
    }
    public func regularizationGradient(parameter: Tensor<Float>) -> Tensor<Float> {
        return parameter * regularizationParameter
    }
}

public protocol CostFunction {
    var estimator: ParametricTensorFunction {get set}
    var regularizers: [ParameterRegularizer?] {get}
    
    func costForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float
    func gradientForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float>
}

public extension CostFunction {
    mutating func updateParameters(subtrahends: [Tensor<Float>]) {
        let parameterRegularizations = estimator.parameters.combineWith(regularizers, combineFunction: { (parameter, regularizer) -> Tensor<Float> in
            if let r = regularizer {
                return r.regularizationGradient(parameter)
            } else {
                return Tensor<Float>(withPropertiesOf: parameter, repeatedValue: 0)
            }
        })
        
        estimator.updateParameters(subtrahends.combineWith(parameterRegularizations, combineFunction: {add(a: $0, outerModesA: [], b: $1, outerModesB: [])}))
    }
    
    func regularizedCostForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let cost = self.costForEstimate(estimate, target: target)
        
        let regularizationCosts = estimator.parameters.combineWith(regularizers, combineFunction: { (parameter, regularizer) -> Float in
            return (regularizer != nil) ? regularizer!.regularizationCost(parameter) : 0
        })
        
        return cost + regularizationCosts.reduce(0, combine: {$0 + $1})
    }
    
    public mutating func numericalGradients(input: Tensor<Float>, target: Tensor<Float>, epsilon: Float = 0.01) -> [Tensor<Float>] {
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

public struct SquaredErrorCost: CostFunction {
    public var estimator: ParametricTensorFunction
    public var regularizers: [ParameterRegularizer?] {
        get {
            return [ParameterRegularizer?](count: estimator.parameters.count, repeatedValue: nil)
        }
    }
    
    public init(forEstimator: ParametricTensorFunction) {
        estimator = forEstimator
    }
    
    public func costForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.modeCount > 1 ? target.modeSizes[0] : 1)
        
        let error = substract(a: target, outerModesA: [], b: estimate, outerModesB: [])
        let cost = multiply(a: error, remainingModesA: [], b: error, remainingModesB: [])
        return cost.values[0] / exampleCount
    }
    
    public func gradientForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        //let gradient = 2 * substract(a: target, outerModesA: [], b: estimate, outerModesB: [])
        let gradient = 2 * substract(a: estimate, outerModesA: [], b: target, outerModesB: [])
        return gradient
    }
}

public struct NegLogClassificationCost: CostFunction {
    public var estimator: ParametricTensorFunction
    public var regularizers: [ParameterRegularizer?] {
        get {
            return [ParameterRegularizer?](count: estimator.parameters.count, repeatedValue: nil)
        }
    }
    
    public init(forEstimator: ParametricTensorFunction) {
        estimator = forEstimator
    }
    
    public func costForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let exampleCount = Float(target.modeCount > 1 ? target.modeSizes[0] : 1)
        
        let t1 = -target °* log(estimate)
        let t2 = (1-target) °* log(1-estimate)
        let cost = vectorSummation((t1-t2).values) / exampleCount
        
        return cost
    }
    
    public func gradientForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        let g1 = target °* (1/estimate)
        let g2 = (1-target) °* (1 / (1-estimate))
        let gradient = -(g1 - g2)
        
        return gradient
    }
}

/// Base class of a neural net layer. Can be used as an input layer.
public class NeuralNetLayer: ParametricTensorFunction {
    /// Cached preactivations of this layer of the last forward propagation, for being used in backpropagation of the gradients. Can be a minibatch.
    var currentPreactivations: Tensor<Float> = zeros()
    /// Cached activations of this layer of the last forward propagation, for being used in backpropagation of the gradients. Can be a minibatch.
    var currentActivations: Tensor<Float> = zeros()
    
    public var activationFunction: ActivationFunction.Type = Sigmoid.self
    
    var previousLayer: NeuralNetLayer?
    var nextLayer: NeuralNetLayer?
    
    let batch = TensorIndex.a
    let prev = TensorIndex.b
    let this = TensorIndex.c
    
    public var parameters: [Tensor<Float>] = []
    
    init(previousLayer: NeuralNetLayer? = nil, nextLayer: NeuralNetLayer? = nil) {
        self.previousLayer = previousLayer
        self.nextLayer = nextLayer
        if let prev = previousLayer {
            prev.nextLayer = self
        }
        if let next = nextLayer {
            next.previousLayer = self
        }
    }
    
    public func output(input: Tensor<Float>) -> Tensor<Float> {
        currentPreactivations = input[batch, this]
        currentActivations = activationFunction.output(currentPreactivations)
        return currentActivations // [batch, this]
    }
    
    public func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let preactivationGradient = activationFunction.derivative(currentPreactivations) °* gradientWrtOutput[batch, this] // [batch, this]
        return (preactivationGradient, [])
    }
    
    public func updateParameters(subtrahends: [Tensor<Float>]) {}
}

/// One layer of a feedforward neural net
public class FeedforwardLayer: NeuralNetLayer {
    
    var weights: Tensor<Float>!
    var bias: Tensor<Float>!
    
    override public var parameters: [Tensor<Float>] {
        get {
            return [weights, bias]
        }
        set(newParameters) {
            weights = newParameters[0][prev, this]
            bias = newParameters[1][this]
        }
    }
    
    init(weights: Tensor<Float>, bias: Tensor<Float>, previousLayer: NeuralNetLayer? = nil, nextLayer: NeuralNetLayer? = nil) {
        super.init(previousLayer: previousLayer, nextLayer: nextLayer)
        self.weights = weights[prev, this]
        self.bias = bias[this]
    }
    
    func feedforward(inputActivations: Tensor<Float>) -> Tensor<Float> {
        let activationProduct = inputActivations[batch, prev] * weights
        currentPreactivations = activationProduct + bias // [batch, this]
        currentActivations = activationFunction.output(currentPreactivations)
        return currentActivations // [batch, this]
    }
    
    override public func output(input: Tensor<Float>) -> Tensor<Float> {
        return feedforward(input)
    }
    
    /// Calculate the gradients via backpropagation
    /// - Parameter gradientWrtOutput: The gradient of the target function, with respect to the output of this layer, i.e. the input of the following layer.
    /// - Returns:
    /// `wrtInput`: <br> The gradient of the target function with respect to the input of this layer. Should be used as input to this function of the preceding layer during backpropagation. <br>
    /// `wrtParameters`: <br> The gradient of the target function with respect to the parameters of this layer (i.e. [wrtWeights, wrtBias]).  <br>
    override public func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let activationDerivative = activationFunction.derivative(currentPreactivations)[batch, this]
        let preactivationGradient = gradientWrtOutput[batch, this] °* activationDerivative // [batch, this]
        
        let weightGradient = previousLayer!.currentActivations[batch, prev] * preactivationGradient // [prev, this]
        let biasGradient = sum(preactivationGradient, overModes: [0]) // [this]
        let inputGradient = preactivationGradient * weights // [batch, prev]
        
        return (inputGradient, [weightGradient, biasGradient])
    }
    

    
    override public func updateParameters(substrahends: [Tensor<Float>]) {
        weights = weights - substrahends[0]
        bias = bias - substrahends[1]
    }
}

public class NeuralNet: ParametricTensorFunction {
    public var layers: [NeuralNetLayer]
    
    public var parameters: [Tensor<Float>] {
        get {
            return layers.flatMap({$0.parameters})
        }
        set(newParameters) {
            var currentParameter = 0
            
            for layer in layers {
                let parameterCount = layer.parameters.count
                for p in 0..<parameterCount {
                    layer.parameters[p] = newParameters[currentParameter]
                    currentParameter += 1
                }
            }
        }
    }
    
    public init(withLayers: [NeuralNetLayer]) {
        layers = withLayers
    }
    
    public init(layerSizes: [Int]) {
        layers = [NeuralNetLayer()]
        
        for l in 1..<layerSizes.count {
            let e: Float = 0.1
            layers.append(FeedforwardLayer(weights: randomTensor(min: -e, max: e, modeSizes: layerSizes[l-1], layerSizes[l]), bias: randomTensor(min: -e, max: e, modeSizes: layerSizes[l]), previousLayer: layers[l-1]))
        }
        
    }
    
    public func output(input: Tensor<Float>) -> Tensor<Float> {
        return layers.reduce(input, combine: {$1.output($0)})
    }
    
    public func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        //backpropagation
        var gradientWrtParameters: [Tensor<Float>] = []
        let gradientWrtInput = layers.reverse().reduce(gradientWrtOutput) { (currentGradientWrtOutput, currentLayer) -> Tensor<Float> in
            let gradients = currentLayer.gradients(currentGradientWrtOutput)
            gradientWrtParameters.insertContentsOf(gradients.wrtParameters, at: 0)
            //gradientWrtParameters.appendContentsOf(gradients.wrtParameters)
            return gradients.wrtInput
        }
        
        return (gradientWrtInput, gradientWrtParameters)
    }
    
    public func updateParameters(subtrahends: [Tensor<Float>]) {
        var currentParameter = 0
        for l in layers {
            let parameterCount = l.parameters.count
            l.updateParameters(Array(subtrahends[Range(start: currentParameter, distance: parameterCount)]))
            currentParameter += parameterCount
        }
    }
}