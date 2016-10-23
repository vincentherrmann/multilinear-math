//
//  ComplexWavelets.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 21.10.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func calculateComplexWaveletCoefficients(vanishingMoments: Int, delayCoefficients: Int, rootsOutsideUnitCircle: [Int] = []) -> [ComplexNumber] {
    
    //create S polynomial
    var sPolynomial: [PolynomialTerm] = [(1 + 0*i, 0)]
    let sBase: [PolynomialTerm] = [(1 + 0*i, 1), (2 + 0*i, 0), (1 + 0*i, -1)]
    
    for _ in 0..<vanishingMoments {
        sPolynomial = expandProduct(factor1: sPolynomial, factor2: sBase)
    }
    
    let d = flatDelayCoefficients(count: delayCoefficients, delay: 0.5)
    let dPolynomial: [PolynomialTerm] = zip(d, Array(0..<d.count)).map({($0 + 0*i, $1)})
    print("dPolynomial: \(dPolynomial)")
    
    sPolynomial = expandProduct(factor1: sPolynomial, factor2: dPolynomial)
    
    let dPolynomialR: [PolynomialTerm] = dPolynomial.map({($0.coefficient, -$0.power)})
    sPolynomial = expandProduct(factor1: sPolynomial, factor2: dPolynomialR)
    
    print("sPolynomial: \(sPolynomial)")
    
    // create system of linear equations
    let fmSize = (vanishingMoments + delayCoefficients-1)*2 - 1
    var factorMatrix = Tensor<Float>(modeSizes: [fmSize, fmSize], repeatedValue: 0)
    var results = [Float](repeating: 0, count: fmSize)
    for r in 0..<fmSize {
        let n = r - vanishingMoments - delayCoefficients + 2
        for c in 0..<fmSize {
            let index = 2*n - c + fmSize
            if(index < 0 || index >= sPolynomial.count) {continue}
            factorMatrix[r, c] = sPolynomial[index].coefficient.real
        }
        if n == 0 {
            results[r] = 2
        }
    }
    print("factor matrix: \(factorMatrix.values)")
    print("results: \(results)")
    let rCoefficients = solveLinearEquationSystem(factorMatrix.values, factorMatrixSize: MatrixSize(rows: fmSize, columns: fmSize), results: results, resultsSize: MatrixSize(rows: fmSize, columns: 1))
    print("r: \(rCoefficients)")
    
    let qPolynomial = ComplexPolynomial(coefficients: rCoefficients.map({$0 + i*0}))
    
    //find roots
    let newton = ComplexNewtonApproximator(polynomial: qPolynomial)
    var roots: [ComplexNumber] = []
    
    for s in 0..<(10*vanishingMoments) {
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
        
        if roots.count >= vanishingMoments + delayCoefficients - 2 {
            break
        }
    }
    
    roots.sort(by: {$0.0.absoluteValue < $0.1.absoluteValue})
    for r in rootsOutsideUnitCircle {
        if r >= roots.count {continue}
        roots[r] = 1 / roots[r]
    }
    
    
    print("roots: \(roots)")
    
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
    
    let g0 = expandProduct(factor1: h0, factor2: dPolynomialR.map({($0.coefficient, $0.power + d.count - 1)}))
    h0 = expandProduct(factor1: h0, factor2: dPolynomial)
    
    print("h0_3: \(h0)")
    
    let factor = sqrt(2 / h0.map({$0.coefficient}).reduce(0, {$0 + $1.real*$1.real}))
    
    let complexCoefficients = zip(h0, g0).map({factor * ($0.0.coefficient.real + $0.1.coefficient.real * i)})
    
    return complexCoefficients
}

public func flatDelayCoefficients(count: Int, delay: Float) -> [Float] {
    
    if(count == 0) {
        return [1]
    }
    
    var currentD: Float = 1
    var d: [Float] = [currentD]
    
    let L = Float(count - 1)
    
    for n in 0..<count - 1 {
        let nF = Float(n)
        currentD = currentD * (L - nF) * (L - nF - delay) / ((nF + 1)*(nF + 1 + delay))
        d.append(currentD)
    }
    
    //normalize
    let sum = d.reduce(0, {$0+$1})
    d = d.map({$0 / sum})
    
    return d
}
