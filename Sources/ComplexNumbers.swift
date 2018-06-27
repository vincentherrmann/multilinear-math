//
//  ComplexNumbers.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 16.10.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public let i = ComplexNumber(real: 0, imaginary: 1)

public struct ComplexNumber: Equatable {
    public var values: [Float] = [0, 0]
    public var real: Float {
        get {
            return values[0]
        }
        set(newReal) {
            values[0] = newReal
        }
    }
    public var imaginary: Float {
        get {
            return values[1]
        }
        set(newImaginary) {
            values[1] = newImaginary
        }
    }
    public var complexConjugate: ComplexNumber {
        get {
            return ComplexNumber(real: real, imaginary: -imaginary)
        }
    }
    public var absoluteValue: Float {
        get {
            let absSquared = self * complexConjugate
            let a = sqrt(absSquared.real)
            return a
        }
    }
    public var argument: Float {
        get {
            let a =  atan2f(imaginary, real)
            return a
        }
    }

    public init(real: Float, imaginary: Float) {
        values = [real, imaginary]
    }

    static public func ==(lhs: ComplexNumber, rhs: ComplexNumber) -> Bool {
        if (lhs.real == rhs.real && lhs.imaginary == rhs.imaginary) {
            return true
        } else {
            return false
        }
    }

    static public func abs(_ x: ComplexNumber) -> ComplexNumber {
        return ComplexNumber(real: x.absoluteValue, imaginary: 0)
    }
}

public func +(lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: lhs.real + rhs.real, imaginary: lhs.imaginary + rhs.imaginary)
}
public func +(lhs: ComplexNumber, rhs: Float) -> ComplexNumber {
    return ComplexNumber(real: lhs.real + rhs, imaginary: lhs.imaginary)
}
public func +(lhs: Float, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: lhs + rhs.real, imaginary: rhs.imaginary)
}

public prefix func -(a: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: -a.real, imaginary: -a.imaginary)
}
public func -(lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: lhs.real - rhs.real, imaginary: lhs.imaginary - rhs.imaginary)
}
public func -(lhs: ComplexNumber, rhs: Float) -> ComplexNumber {
    return ComplexNumber(real: lhs.real - rhs, imaginary: lhs.imaginary)
}
public func -(lhs: Float, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: lhs - rhs.real, imaginary: -rhs.imaginary)
}

public func *(lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    let r = lhs.real * rhs.real - lhs.imaginary * rhs.imaginary
    let i = lhs.imaginary * rhs.real + lhs.real * rhs.imaginary
    return ComplexNumber(real: r, imaginary: i)
}
public func *(lhs: ComplexNumber, rhs: Float) -> ComplexNumber {
    return ComplexNumber(real: lhs.real * rhs, imaginary: lhs.imaginary * rhs)
}
public func *(lhs: Float, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: lhs * rhs.real, imaginary: lhs * rhs.imaginary)
}

public func /(lhs: ComplexNumber, rhs: ComplexNumber) -> ComplexNumber {
    let denominator = rhs.real * rhs.real + rhs.imaginary * rhs.imaginary
    let r = (lhs.real * rhs.real + lhs.imaginary * rhs.imaginary) / denominator
    let i = (lhs.imaginary * rhs.real - lhs.real * rhs.imaginary) / denominator
    return ComplexNumber(real: r, imaginary: i)
}
public func /(lhs: ComplexNumber, rhs: Float) -> ComplexNumber {
    return ComplexNumber(real: lhs.real / rhs, imaginary: lhs.imaginary / rhs)
}
public func /(lhs: Float, rhs: ComplexNumber) -> ComplexNumber {
    return ComplexNumber(real: lhs, imaginary: 0) / rhs
}

public func pow(_ z: ComplexNumber, n: Int) -> ComplexNumber {
    var r = 1 + i*0
    if n == 0 {
        return r
    } else if n > 0 {
        for _ in 0..<n {
            r = r*z
        }
        return r
    } else {
        for  _ in 0..<(-n) {
            r = r/z
        }
        return r
    }
}

public struct ComplexPolynomial {
    public var coefficients: [ComplexNumber]
    public var degree: Int {
        get {
            return coefficients.count - 1
        }
    }
    public var derivative: ComplexPolynomial {
        var newCoefficients: [ComplexNumber] = []
        for i in 1...degree {
            newCoefficients.append(coefficients[i] * (Float(i)))
        }
        return ComplexPolynomial(coefficients: newCoefficients)
    }

    public func valueFor(z: ComplexNumber) -> ComplexNumber {
        var currentZ: ComplexNumber = ComplexNumber(real: 1, imaginary: 0)
        var currentResult: ComplexNumber = ComplexNumber(real: 0, imaginary: 0)

        for c in coefficients {
            let s = c * currentZ
            currentResult = currentResult + s
            currentZ = currentZ * z
        }

        return currentResult
    }
}





