//
//  ActivationFunctions.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 19.06.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol ActivationFunction {
    func output(_ input: Tensor<Float>) -> Tensor<Float>
    func derivative(_ input: Tensor<Float>) -> Tensor<Float>
}

public struct Sigmoid: ActivationFunction {
    public func output(_ input: Tensor<Float>) -> Tensor<Float> {
        let values = input.values.map { (x) -> Float in
            if x >= 0 {
                return 1 / (1 + (exp(-x)))
            } else {
                let e = exp(x)
                return e / (1 + e)
            }
        }
        let tensor = Tensor<Float>(withPropertiesOf: input, values: values)
        return tensor
        //return 1 / (1 + exp(-input)) //this method would be numerically unstable
    }
    public func derivative(_ input: Tensor<Float>) -> Tensor<Float> {
        let s = output(input)
        let result = s °* (1-s)
        return result
    }
}

public struct ReLU: ActivationFunction {
    public var secondarySlope: Float
    
    public init(secondarySlope: Float) {
        self.secondarySlope = secondarySlope
    }
    
    public func output(_ input: Tensor<Float>) -> Tensor<Float> {
        return Tensor<Float>(withPropertiesOf: input, values: input.values.map({max(secondarySlope*$0, $0)}))
    }
    public func derivative(_ input: Tensor<Float>) -> Tensor<Float> {
        return Tensor<Float>(withPropertiesOf: input, values: input.values.map({$0 > 0 ? 1.0 : secondarySlope}))
    }
}

public struct Softplus: ActivationFunction {
    public func output(_ input: Tensor<Float>) -> Tensor<Float> {
        let output = log(1 + exp(input))
        return output
    }
    public func derivative(_ input: Tensor<Float>) -> Tensor<Float> {
        let expo = exp(input)
        let der = expo °/ (1 + expo)
        return der
    }
}
