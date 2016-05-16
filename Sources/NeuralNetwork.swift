//
//  NeuralNetwork.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 30.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public class FeedforwardNeuralNet: GradientOptimizable {
    ///weights of each layer
    var weights: [Tensor<Float>]
    ///biases of each layer
    var bias: [Tensor<Float>]
    var currentActivations: [Tensor<Float>]
    var activationFunction: Tensor<Float> -> Tensor<Float>
    var regularize: Float = 0
    
    var layerCount: Int {
        get {
            return weights.count + 1
        }
    }
    var layerSizes: [Int] {
        get {
            return weights.map({$0.modeSizes[0]}) + [weights.last!.modeSizes[1]]
        }
    }
    
    public init(withLayerSizes: [Int], activationFunction: Tensor<Float> -> Tensor<Float> = sigmoid) {
        if(withLayerSizes.count < 2) {
            "a neural net has to have at least two layers!"
        }
        
        self.weights = []
        self.bias = []
        self.activationFunction = activationFunction
        
        for l in 0..<withLayerSizes.count-1 {
            weights.append(randomTensor(withLayerSizes[l], withLayerSizes[l+1]))
            bias.append(zeros(withLayerSizes[l+1]))
        }
    }
    
    public func feedforward(input: Tensor<Float>) -> Tensor<Float> {
        
        let lastMode = input.modeCount - 1
        var output = input
        
        for l in 0..<weights.count {
            let product = multiply(a: output, summationModesA: [lastMode], b: weights[l], summationModesB: [0])
            output = activationFunction(add(a: product, b: bias[l]))
        }
        return output
    }
    
    public func cost(x x: Tensor<Float>, y: Tensor<Float>) -> Float {
        let hypothesis = feedforward(x)
        let t1 = multiplyElementwise(a: -y, b: log(hypothesis))
        let t2 = multiplyElementwise(a: 1 - y, b: log(1 - hypothesis))
        let difference = substract(a: t1, b: t2)
        
        var regularizationCost: Float = 0
        for w in weights {
            regularizationCost += multiply(a: w, remainingModesA: [], b: w, remainingModesB: []).values[0]
        }
        regularizationCost = 0.5 * regularize * regularizationCost
        
        let cost = (vectorSummation(difference.values) + regularizationCost) / Float(y.modeSizes[0])
        return cost
    }
}

public protocol NeuralNetLayer {
    var currentPreactivations: Tensor<Float> {get}
    var currentActivations: Tensor<Float> {get}
    
    var activationFunction: ActivationFunction {get}
    
    var previousLayer: NeuralNetLayer? {get}
    var nextLayer: NeuralNetLayer? {get}
    
    func propagateForward(input: Tensor<Float>) -> Tensor<Float>
    func propagateBackward(gradient: Tensor<Float>) -> Tensor<Float>
}

public struct FeedforwardLayer: NeuralNetLayer {
    public var currentPreactivations: Tensor<Float> = zeros(0)
    public var currentActivations: Tensor<Float> = zeros(0)
    
    public var activationFunction: ActivationFunction.Type = Sigmoid.self
    
    public var previousLayer: NeuralNetLayer? = nil
    public var nextLayer: NeuralNetLayer? = nil
    
    var weights: Tensor<Float> = zeros(0)
    var bias: Float = 0
    
    mutating func propagateForward(input: Tensor<Float>) -> Tensor<Float> {
        currentPreactivations = bias + multiply(a: input, summationModesA: [input.modeCount-1], b: weights, summationModesB: [0])
        currentActivations = activationFunction.output(currentPreactivations)
        return currentActivations
    }
    
    /// Calculate the gradients via backpropagation
    /// - Parameter gradientWrtOutput: The gradient of the target function, with respect to the output of this layer, i.e. the input of the following layer.
    /// - Returns: 
    /// `wrtWeights`: <br> The gradient of the target function with respect to the weights of this layer <br>
    /// `wrtBias`: <br> The gradient of the target function with respect to the bias of this layer <br>
    /// `wrtInput`: <br> The gradient of the target function with respect to the input of this layer. Should be used as input to this function of the preceding layer during backpropagation. <br>
    func gradient(gradientWrtOutput: Tensor<Float>) -> (wrtWeights: Tensor<Float>, wrtBias: Tensor<Float>, wrtInput: Tensor<Float>) {
    }
    
    func propagateBackward(gradient: Tensor<Float>) -> (weightGradient: Tensor<Float>, biasGradient: Tensor<Float>, activationGradient: Tensor<Float>) {
        let preactivationGradient = activationFunction.derivative(currentPreactivations) °* gradient
        
        let weightGradient = preactivationGradient * previousLayer!.currentActivations
        let biasGradient = preactivationGradient
        let activationGradient = preactivationGradient * weights
        
        return (weightGradient, biasGradient, activationGradient)
    }
}