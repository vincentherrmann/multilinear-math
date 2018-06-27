//
//  TensorSyntacticOperators.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 23.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

// MARK: - Scalar-Tensor functions
/// Negative of a tensor
public prefix func -(tensor: Tensor<Float>) -> Tensor<Float> {
    let negative = Tensor<Float>(withPropertiesOf: tensor, values: vectorNegation(tensor.values))
    return negative
}

/// add a scalar to every element of a tensor
public func +(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    let sum = Tensor<Float>.init(withPropertiesOf: lhs, values: vectorAddition(vector: lhs.values, add: rhs))
    return sum
}
/// add a scalar to every element of a tensor
public func +(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return rhs+lhs
}

/// substract a scalar from every element of a tensor
public func -(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    let diff = Tensor<Float>(withPropertiesOf: lhs, values: vectorAddition(vector: lhs.values, add: -rhs))
    return diff
}

/// substract every element of a tensor from a scalar
public func -(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return lhs + (-rhs)
}

/// multiply every element of a tensor with a scalar
public func *(lhs: Tensor<Float>, rhs: Float) -> Tensor<Float> {
    let product = Tensor<Float>.init(withPropertiesOf: lhs, values: vectorMultiplication(lhs.values, factor: rhs))
    return product
}
/// multiply every element of a tensor with a scalar
public func *(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    return rhs*lhs
}

// MARK: - Tensor-Tensor functions
public func +(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {

    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)

    let sum = add(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)

    return sum
}

public func -(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {

    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)

    let difference = substract(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)

    return difference
}

infix operator °*
public func °*(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {

    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)

    let product = multiplyElementwise(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)

    return product
}

infix operator °/
public func °/(lhs: Tensor<Float>, rhs: Tensor<Float>) -> Tensor<Float> {

    let commonIndices = lhs.commonIndicesWith(rhs)
    let commonModesLhs = commonIndices.map({$0.modeA})
    let outerModesLhs = lhs.modeArray.removeValues(commonModesLhs)
    let commonModesRhs = commonIndices.map({$0.modeB})
    let outerModesRhs = rhs.modeArray.removeValues(commonModesRhs)

    let quotient = divide(a: lhs, commonModesA: commonModesLhs, outerModesA: outerModesLhs, b: rhs, commonModesB: commonModesRhs, outerModesB: outerModesRhs)

    return quotient
}

/// divide a scalar by every element of a tensor
public func /(lhs: Float, rhs: Tensor<Float>) -> Tensor<Float> {
    let quotient = Tensor<Float>.init(withPropertiesOf: rhs, values: vectorDivision(numerator: lhs, vector: rhs.values))
    return quotient
}
