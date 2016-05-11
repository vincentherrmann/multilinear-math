//
//  Optimization.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 04.05.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol GradientOptimizable: class {
    var parameters: [Tensor<Float>] {get set}
    
    func cost(x x: Tensor<Float>, y: Tensor<Float>) -> Float
    func gradient(x x: Tensor<Float>, y: Tensor<Float>) -> [Tensor<Float>]
}

public func batchGradientDescent(objective: GradientOptimizable, input: Tensor<Float>, output: Tensor<Float>, updateRate: Float, convergenceThreshold: Float = 0.001, maxLoops: Int = 1000) {
    
    var cost = FLT_MAX
    
    for _ in 0..<maxLoops {
        let currentCost = objective.cost(x: input, y: output)
        if(abs(currentCost / cost - 1) < convergenceThreshold) {
            break
        }
        cost = currentCost
        
        for p in 0..<objective.parameters.count {
            objective.parameters[p] = substract(a: objective.parameters[p], b: updateRate * objective.gradient(x: input, y: output)[p])
        }
    }
}