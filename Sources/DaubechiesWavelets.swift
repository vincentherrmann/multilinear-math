//
//  DaubechiesWavelets.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 12.10.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func calculateDaubechiesCoefficients(vanishingMoments: Int) -> [Float] {

    //create Q polynomial
    var summedExpansion: [PolynomialTerm] = [(1 + 0*i, 0)]
    let qBase: [PolynomialTerm] = [(0.5 + 0*i, 0), (-0.25 + 0*i, 1), (-0.25 + 0*i, -1)]
    
    for n in 1..<vanishingMoments {
        var expansion = [[PolynomialTerm]].init(repeating: qBase, count: n).reduce([(1 + 0*i, 0)], {expandProduct(factor1: $0, factor2: $1)})
        let factor = Float(binomialCoefficient(vanishingMoments + n - 1, choose: n))
        expansion = expansion.map({($0.coefficient * factor, $0.power)})

        for term in expansion {
            let pow = term.power
            if let i = summedExpansion.map({$0.power}).index(where: {$0 == pow}) {
                summedExpansion[i] = (summedExpansion[i].coefficient + term.coefficient, pow)
            } else {
                summedExpansion.append(term)
            }
        }
    }
    
    summedExpansion.sort(by: {$0.power < $1.power})
    let qPolynomial = ComplexPolynomial(coefficients: summedExpansion.map({$0.coefficient}))
    
    //find roots
    let newton = ComplexNewtonApproximator(polynomial: qPolynomial)
    var roots: [ComplexNumber] = []
    
    for s in 0..<100 {
        let start = cos(2.6 * Float(s)) + sin(2.6 * Float(s))*i
        if let root = newton.findRoot(from: start) {
            if roots.contains(where: {($0 - root).absoluteValue < 0.001}) {
                continue
            } else if root.absoluteValue > 1 {
                roots.append(1 / root)
            } else {
                roots.append(root)
            }
        }
        
        if roots.count >= vanishingMoments-1 {
            break
        }
    }
    
    //create H0 polynomial
    var h0: [PolynomialTerm] = [(2 + 0*i, 0)]
    
    for _ in 0..<vanishingMoments {
        h0 = expandProduct(factor1: h0, factor2: [(0.5 + 0*i, 0), (0.5 + 0*i, 1)])
    }
    
    print("h0_1: \(h0)")
    
    for root in roots {
        let f = 1 / (1-root)
        h0 = expandProduct(factor1: h0, factor2: [(-root*f, 0), (f, 1)])
    }
    
    print("h0_2: \(h0)")
    
    let h0Coefficients = h0.map({$0.coefficient.real})
    
    return h0Coefficients
}


/// One term of a complex polynomial, consisting of a `coefficient` and the `power` of the variable
public typealias PolynomialTerm = (coefficient: ComplexNumber, power: Int)

/// Expand the product of two complex polynomials
///
/// - parameter factor1: first polynomial
/// - parameter factor2: second polynomial
///
/// - returns: product
public func expandProduct(factor1: [PolynomialTerm], factor2: [PolynomialTerm]) -> [PolynomialTerm] {
    
    var expansion: [PolynomialTerm] = []
    
    for term1 in factor1 {
        for term2 in factor2 {
            let coeff = term1.coefficient * term2.coefficient
            let pow = term1.power + term2.power
            
            if let i = expansion.map({$0.power}).index(where: {$0 == pow}) {
                expansion[i] = (expansion[i].coefficient + coeff, pow)
            } else {
                expansion.append((term1.coefficient * term2.coefficient, term1.power + term2.power))
            }
        }
    }
    
    expansion.sort(by: {$0.power < $1.power})
    
    return expansion
}

public func binomialCoefficient(_ a: Int, choose b: Int) -> Int {
    let num = Array(1...a).reduce(1, {$0*$1})
    let f1 = Array(1...b).reduce(1, {$0*$1})
    let f2 = Array(1...(a-b)).reduce(1, {$0*$1})
    return num/(f1*f2)
}

public struct ComplexNewtonApproximator {
    public var polynomial: ComplexPolynomial
    public var threshold: Float = 0.000001
    public var maxIterations: Int = 30
    
    public init(polynomial: ComplexPolynomial) {
        self.polynomial = polynomial
    }
    
    public func findRoot(from: ComplexNumber) -> ComplexNumber? {
        var currentPosition = from
        var currentValue = polynomial.valueFor(z: currentPosition)
        
        for _ in 0..<maxIterations {
            let currentDerivative = polynomial.derivative.valueFor(z: currentPosition)
            currentPosition = currentPosition - (currentValue / currentDerivative)
            currentValue = polynomial.valueFor(z: currentPosition)
            
            //print("newton currentValue: \(currentValue)")
            
            if(currentValue.absoluteValue < threshold) {
                print("root at \(currentPosition)")
                return currentPosition
            }
        }
        
        print("found no root in the neighbourhood of \(from)")
        print()
        
        return nil
    }
}
