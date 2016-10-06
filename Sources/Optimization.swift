//
//  Optimization.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 04.05.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

//public func batchGradientDescent(objective: GradientOptimizable, input: Tensor<Float>, output: Tensor<Float>, updateRate: Float, convergenceThreshold: Float = 0.001, maxLoops: Int = 1000) {
//    
//    var cost = FLT_MAX
//    
//    for _ in 0..<maxLoops {
//        let currentCost = objective.cost(x: input, y: output)
//        if(abs(currentCost / cost - 1) < convergenceThreshold) {
//            break
//        }
//        cost = currentCost
//        
//        for p in 0..<objective.parameters.count {
//            objective.parameters[p] = substract(a: objective.parameters[p], b: updateRate * objective.gradient(x: input, y: output)[p])
//        }
//    }
//}

public func stochasticGradientDescent(_ objective: CostFunction, inputs: Tensor<Float>, targets: Tensor<Float>, updateRate: Float, convergenceThreshold: Float = 0.00001, maxLoops: Int = Int.max, minibatchSize: Int = 16, validationCallback: (_ currentEpoch: Int, _ currentEstimator: ParametricTensorFunction) -> (Bool) = {(epoch, _) in print("epoch \(epoch)"); return false}) {
    
    var cost = FLT_MAX
    var epoch = 0
    var currentBatch = inputs
    var currentBatchTargets = targets
    var currentIndex = 0
    var convergenceCounter = 0
    
    print("stochastic gradient descent")
    
    for _ in 0..<maxLoops {
        //create minibatch
        var minibatch: Tensor<Float>
        var minibatchTargets: Tensor<Float>
        if(currentIndex + minibatchSize < currentBatch.modeSizes[0]) {
            let minibatchRange = CountableRange(start: currentIndex, distance: minibatchSize)
            
            minibatch = currentBatch[minibatchRange, all]
            minibatchTargets = currentBatchTargets[minibatchRange, all]
            
            currentIndex += minibatchSize
        } else {
            //call validiation callback, if it returns true, break the optimization loop
            if(validationCallback(epoch, objective.estimator)) {
                break
            }
            
            let minibatchRange = currentIndex..<currentBatch.modeSizes[0]
            
            minibatch = currentBatch[minibatchRange, all]
            minibatchTargets = currentBatchTargets[minibatchRange, all]
            
            currentIndex = 0
            //reshuffle batch for new epoch
            let shuffleOrder = (0..<inputs.modeSizes[0]).shuffle()
            currentBatch = changeOrderOfModeIn(currentBatch, mode: 0, newOrder: shuffleOrder)
            currentBatchTargets = changeOrderOfModeIn(currentBatchTargets, mode: 0, newOrder: shuffleOrder)
            epoch += 1
        }
        
        //calculate current estimate and cost
        let estimate = objective.estimator.output(minibatch)
        minibatchTargets.indices = estimate.indices
        let newCost = objective.regularizedCostForEstimate(estimate, target: minibatchTargets)
        print("SGD cost: \(newCost)")
        
        //calculate gradients and update parameters
        let regularizedCostGradient = objective.gradientForEstimate(estimate, target: minibatchTargets)
        let gradients = objective.estimator.gradients(regularizedCostGradient).wrtParameters
        let scaledGradients = gradients.map({$0 * (updateRate / Float(minibatchSize))})
        objective.updateParameters(scaledGradients)
        
        //check for convergence
        if(abs((cost - newCost) / newCost) < convergenceThreshold) {
            convergenceCounter += 1
            if(convergenceCounter >= 3) {
                print("converged!")
                break
            }
        }
        cost = newCost
    }
}
