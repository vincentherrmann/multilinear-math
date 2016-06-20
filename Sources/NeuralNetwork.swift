//
//  NeuralNetwork.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 30.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

/// Base class of a neural net layer. Can be used as an input layer.
public class NeuralNetLayer: ParametricTensorFunction {
    /// Cached preactivations of this layer of the last forward propagation, for being used in backpropagation of the gradients. Can be a minibatch.
    var currentPreactivations: Tensor<Float> = zeros()
    /// Cached activations of this layer of the last forward propagation, for being used in backpropagation of the gradients. Can be a minibatch.
    var currentActivations: Tensor<Float> = zeros()
    
    public var activationFunction: ActivationFunction
    
    var previousLayer: NeuralNetLayer?
    var nextLayer: NeuralNetLayer?
    
    /// mode for samples in batch
    let batch = TensorIndex.a
    /// mode for neurons in the previous layer
    let prev = TensorIndex.b
    /// mode for neurons in this layer
    let this = TensorIndex.c
    
    public var parameters: [Tensor<Float>] = []
    
    init(previousLayer: NeuralNetLayer? = nil, nextLayer: NeuralNetLayer? = nil, activationFunction: ActivationFunction = Sigmoid()) {
        self.previousLayer = previousLayer
        self.nextLayer = nextLayer
        self.activationFunction = activationFunction
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
    
    init(weights: Tensor<Float>, bias: Tensor<Float>, previousLayer: NeuralNetLayer? = nil, nextLayer: NeuralNetLayer? = nil, activationFunction: ActivationFunction = Sigmoid()) {
        super.init(previousLayer: previousLayer, nextLayer: nextLayer, activationFunction: activationFunction)
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