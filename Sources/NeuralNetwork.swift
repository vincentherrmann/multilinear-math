//
//  NeuralNetwork.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 30.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

//public class FeedforwardNeuralNet: GradientOptimizable {
//    ///weights of each layer
//    var weights: [Tensor<Float>]
//    ///biases of each layer
//    var bias: [Tensor<Float>]
//    var currentActivations: [Tensor<Float>]
//    var activationFunction: Tensor<Float> -> Tensor<Float>
//    var regularize: Float = 0
//    
//    var layerCount: Int {
//        get {
//            return weights.count + 1
//        }
//    }
//    var layerSizes: [Int] {
//        get {
//            return weights.map({$0.modeSizes[0]}) + [weights.last!.modeSizes[1]]
//        }
//    }
//    
//    public init(withLayerSizes: [Int], activationFunction: Tensor<Float> -> Tensor<Float> = sigmoid) {
//        if(withLayerSizes.count < 2) {
//            "a neural net has to have at least two layers!"
//        }
//        
//        self.weights = []
//        self.bias = []
//        self.activationFunction = activationFunction
//        
//        for l in 0..<withLayerSizes.count-1 {
//            weights.append(randomTensor(withLayerSizes[l], withLayerSizes[l+1]))
//            bias.append(zeros(withLayerSizes[l+1]))
//        }
//    }
//    
//    public func feedforward(input: Tensor<Float>) -> Tensor<Float> {
//        
//        let lastMode = input.modeCount - 1
//        var output = input
//        
//        for l in 0..<weights.count {
//            let product = multiply(a: output, summationModesA: [lastMode], b: weights[l], summationModesB: [0])
//            output = activationFunction(add(a: product, b: bias[l]))
//        }
//        return output
//    }
//    
//    public func cost(x x: Tensor<Float>, y: Tensor<Float>) -> Float {
//        let hypothesis = feedforward(x)
//        let t1 = multiplyElementwise(a: -y, b: log(hypothesis))
//        let t2 = multiplyElementwise(a: 1 - y, b: log(1 - hypothesis))
//        let difference = substract(a: t1, b: t2)
//        
//        var regularizationCost: Float = 0
//        for w in weights {
//            regularizationCost += multiply(a: w, remainingModesA: [], b: w, remainingModesB: []).values[0]
//        }
//        regularizationCost = 0.5 * regularize * regularizationCost
//        
//        let cost = (vectorSummation(difference.values) + regularizationCost) / Float(y.modeSizes[0])
//        return cost
//    }
//}

public protocol ParametricTensorFunction {
    var parameters: [Tensor<Float>] {get}
    
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
                return parameter
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
}

public struct SquaredErrorCost: CostFunction {
    public var estimator: ParametricTensorFunction
    public var regularizers: [ParameterRegularizer?] {
        get {
            return [ParameterRegularizer?](count: estimator.parameters.count, repeatedValue: nil)
        }
    }
    
    public func costForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Float {
        let error = substract(a: target, outerModesA: [], b: estimate, outerModesB: [])
        return (error * error).values[0]
    }
    
    public func gradientForEstimate(estimate: Tensor<Float>, target: Tensor<Float>) -> Tensor<Float> {
        return 2 * substract(a: target, outerModesA: [], b: estimate, outerModesB: [])
    }
}

/// Base class of a neural net layer. Can be used as an input layer.
public class NeuralNetLayer: ParametricTensorFunction {
    /// Cached preactivations of this layer of the last forward propagation, for being used in backpropagation of the gradients. Can be a minibatch.
    var currentPreactivations: Tensor<Float> = zeros()
    /// Cached activations of this layer of the last forward propagation, for being used in backpropagation of the gradients. Can be a minibatch.
    var currentActivations: Tensor<Float> = zeros()
    
    var activationFunction: ActivationFunction.Type = Sigmoid.self
    
    var previousLayer: NeuralNetLayer?
    var nextLayer: NeuralNetLayer?
    
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
        currentPreactivations = input
        currentActivations = activationFunction.output(currentPreactivations)
        return currentActivations
    }
    
    public func gradients(gradientWrtOutput: Tensor<Float>) -> (wrtInput: Tensor<Float>, wrtParameters: [Tensor<Float>]) {
        let preactivationGradient = activationFunction.derivative(currentPreactivations) °* gradientWrtOutput
        return (preactivationGradient, [])
    }
    
    public func updateParameters(subtrahends: [Tensor<Float>]) {}
}

/// One layer of a feedforward neural net
public class FeedforwardLayer: NeuralNetLayer {
    
    var weights: Tensor<Float>
    var bias: Tensor<Float>
    
    override public var parameters: [Tensor<Float>] {
        get {
            return [weights, bias]
        }
        set(newParameters) {
            weights = newParameters[0]
            bias = newParameters[1]
        }
    }
    
    init(weights: Tensor<Float>, bias: Tensor<Float>, previousLayer: NeuralNetLayer? = nil, nextLayer: NeuralNetLayer? = nil) {
        self.weights = weights
        self.bias = bias
        super.init(previousLayer: previousLayer, nextLayer: nextLayer)
    }
    
    func feedforward(inputActivations: Tensor<Float>) -> Tensor<Float> {
        let activationProduct = multiply(a: inputActivations, summationModesA: [inputActivations.modeCount-1], b: weights, summationModesB: [0])
        currentPreactivations = add(a: bias, commonModesA: [0], b: activationProduct, commonModesB: [activationProduct.modeCount-1])
        currentActivations = activationFunction.output(currentPreactivations)
        return currentActivations
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
        let preactivationGradient = activationFunction.derivative(currentPreactivations) °* gradientWrtOutput
        
        let weightGradient = preactivationGradient * previousLayer!.currentActivations
        let biasGradient = preactivationGradient
        let inputGradient = preactivationGradient * weights
        
        return (inputGradient, [weightGradient, biasGradient])
    }
    
    override public func updateParameters(substrahends: [Tensor<Float>]) {
        weights = weights - substrahends[0]
        bias = bias - substrahends[1]
    }
}

public class NeuralNet: ParametricTensorFunction {
    var layers: [NeuralNetLayer]
    
    public var parameters: [Tensor<Float>] {
        get {
            return layers.flatMap({$0.parameters})
        }
    }
    
    init(withLayers: [NeuralNetLayer]) {
        layers = withLayers
    }
    
    init(layerSizes: [Int]) {
        layers = [NeuralNetLayer()]
        
        for l in 1..<layerSizes.count {
            layers.append(FeedforwardLayer(weights: randomTensor(layerSizes[l-1], layerSizes[l]), bias: zeros(layerSizes[l]), previousLayer: layers[l-1]))
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
            gradientWrtParameters.appendContentsOf(gradients.wrtParameters)
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