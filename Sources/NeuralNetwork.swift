//
//  NeuralNetwork.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 30.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public class FeedforwardNeuralNet {
    var weights: [Tensor<Float>]
    var bias: [Tensor<Float>]
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