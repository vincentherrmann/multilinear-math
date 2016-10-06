//
//  FIRFilter.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 15.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public struct FIRFilter {
    public var coefficients: [Float]
    public var order: Int {
        get {return coefficients.count}
    }
    
    public init(coefficients: [Float]) {
        self.coefficients = coefficients
    }
    
    public func zTransform(_ z: (Float, Float)) -> (r: Float, i: Float) {
        print("z transform at: \(z)")
        var x: (Float, Float) = (0, 0)
        for n in 0..<order {
            let zn = powComplex(z, n: -n)
            print("zn: \(zn)")
            let p = (coefficients[n] * zn.r, coefficients[n] * zn.i)
            x = (x.0 + p.0, x.1 + p.1)
        }
        print("x: \(x)")
        return x
    }
    
    public func frequencyResponse(_ omega: Float) -> (r: Float, i: Float) {
        return zTransform((cos(omega), sin(omega)))
    }
    
}

public func multiplyComplex(_ a: (Float, Float), b: (Float, Float)) -> (r: Float, i: Float) {
    let r = a.0 * b.0 - a.1 * b.1
    let i = a.1 * b.0 + a.0 * b.1
    return (r, i)
}

public func powComplex(_ z: (Float, Float), n: Int) -> (r: Float, i: Float) {
    if(n == 0) {
        return (1, 0)
    }
    
    let m = n<0 ? -n : n
    var r: (Float, Float) = (1, 0)
    for _ in 0..<m {
        r = multiplyComplex(r, b: z)
        print("r: \(r)")
    }
    
    if(n > 0) {
        return r
    } else {
        let denom = r.0*r.0 + r.1*r.1
        return(r.0/denom, -r.1/denom)
    }
}
