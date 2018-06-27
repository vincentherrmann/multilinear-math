//
//  FastWaveletTransform.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 05.11.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

public class Wavelet {
    ///lowpass analysis filter
    public var h0: [Float]
    ///highpass analysis filter
    public var h1: [Float] {
        get {
            let waveletFilter = Array(zip(h0, Array(0..<h0.count)).map({$0 * pow(-1, Float($1))}).reversed())
            if(h0.count % 2 == 0) {
                return waveletFilter
            } else {
                return waveletFilter.map({-$0})
            }
        }
    }
    ///lowpass synthesysis filter
    public var f0: [Float]
    ///highpass synthesysis filter
    public var f1: [Float] {
        get {
            let waveletFilter = Array(zip(f0, Array(0..<h0.count)).map({$0 * pow(-1, Float($1))}).reversed())
            if(f0.count % 2 == 0) {
                return waveletFilter
            } else {
                return waveletFilter.map({-$0})
            }
        }
    }

    public init(h0: [Float], f0: [Float]) {
        self.h0 = h0
        self.f0 = f0
    }

    public func scalingAnalysisFunctionExact(levels: Int) -> [Float] {
        var scaling = Wavelet.calculateIntegerScalingValues(h0)
        for _ in 0..<levels {
            scaling = Wavelet.newExactScalingLevel(scaling, coefficients: h0)
        }
        return scaling
    }

    public func scalingAnalysisFunctionCascading(levels: Int) -> [Float] {
        var scaling: [Float] = [1]
        for _ in 0...levels {
            scaling = Wavelet.newScalingApproximation(scaling, coefficients: h0)
        }
        return scaling
    }

    public func waveletAnalysisFunctionExact(levels: Int) -> [Float] {
        let scaling = scalingAnalysisFunctionExact(levels: levels)
        let wavelet = Wavelet.waveletFunction(from: scaling, level: levels, coefficients: h1)
        return wavelet
    }

    public func waveletAnalysisFunctionCascading(levels: Int) -> [Float] {
        let scaling = scalingAnalysisFunctionCascading(levels: levels)
        let wavelet = Wavelet.waveletFunction(from: scaling, level: levels, coefficients: h1)
        return wavelet
    }

    public func analysisFilter(for code: WaveletPacket.WaveletPacketCode) -> [Float] {
        var filter: [Float] = [1]
        let p = WaveletPacket(values: [], code: code)
        let types = Array(p.levels)
        print("code: \(p.code), types: \(types)")

        for type in types {
            switch type {
            case .scaling:
                filter = Wavelet.newScalingApproximation(filter, coefficients: h0)
            case .wavelet:
                filter = Wavelet.newScalingApproximation(filter, coefficients: h1)
            }
        }

        return filter
    }

    public func analysisFilter(for levels: [WaveletPacket.LevelType]) -> [Float] {
        let p = WaveletPacket(values: [], levels: levels)
        return analysisFilter(for: p.levels)
    }

    /// calculate the values of the scaling function on the integer position from the filter coefficients. This is done by solving a system of linear equations constructed from the dilation equation
    private static func calculateIntegerScalingValues(_ coefficients: [Float]) -> [Float] {
        let count = coefficients.count

        //calculate factor matrix (left side of the equation system)
        //example: db4 coeffients a0, a1, a2, a3
        // a0-1  0    0    0   =  0
        //  a2  a1-1  a0   0   =  0
        //  0    a3  a2-1  a1  =  0
        //  0    0    0   a3-1 =  0
        //  1    1    1    1   =  1 //this last equation is added to each row to get an unambiguous solution
        var factorMatrix = Tensor<Float>(modeSizes: [count, count], repeatedValue: 0)
        for r in 0..<count {
            let coeff0Position = 2*r
            for c in 0..<count {
                let index = coeff0Position - c
                if(index < 0 || index >= count) {continue}
                factorMatrix[r, index] = coefficients[c]
            }
            factorMatrix[r, r] += -1
        }
        factorMatrix = factorMatrix + 1
        let results = [Float](repeating: 1, count: count-1) + [1]

        print("count: \(count)")
        print("factor matrix: \(factorMatrix.values)")
        print("results: \(results)")
        let solution = solveLinearEquationSystem(factorMatrix.values, factorMatrixSize: MatrixSize(rows: count, columns: count), results: results, resultsSize: MatrixSize(rows: count, columns: 1))

        let testResults = matrixMultiplication(matrixA: factorMatrix.values, sizeA: MatrixSize(rows: count, columns: count), matrixB: solution, sizeB: MatrixSize(rows: count, columns: 1))
        print("test result: \(testResults)")

        return solution
    }

    private static func newExactScalingLevel(_ currentScaling: [Float], coefficients: [Float]) -> [Float] {
        let newLevel = 2 * (currentScaling.count-1) / (coefficients.count-1)
        var newScaling = [Float](repeating: 0, count: (coefficients.count-1) * newLevel + 1)
        let newValueCount = (coefficients.count-1) * (newLevel/2)
        //print("new level: \(newLevel), value count: \(newApproximation.count), new values: \(newValueCount)")

        for t in 0..<currentScaling.count {
            newScaling[2*t] = currentScaling[t]
        }

        for n in 0..<newValueCount {
            var value: Float = 0
            for c in 0..<coefficients.count {
                let index = 2 + 4*n - newLevel*c
                if(index < 0 || index >= newScaling.count) {continue}
                value += coefficients[c] * newScaling[index]
            }
            newScaling[2*n+1] = value
        }
        return newScaling
    }

    ///approximate filter using the cascading algorithm
    private static func newScalingApproximation(_ currentApproximation: [Float], coefficients: [Float]) -> [Float] {
        let newValueCount = 2*currentApproximation.count + coefficients.count - 2
        var newApproximation = [Float](repeating: 0, count: newValueCount)

        for j in 0..<newValueCount {
            var currentValue: Float = 0
            for k in 0..<coefficients.count {
//                if((j+k) % 2 == 0) {
//                    let index = (j-k)/2
//                    if(index >= 0 && index < currentApproximation.count) {
//                        currentValue += coefficients[k] * currentApproximation[index]
//                    }
//                }
                if((-j+k) % 2 == 0) {
                    let index = (-j+k)/2
                    if(index <= 0 && index > -currentApproximation.count) {
                        currentValue += coefficients[k] * currentApproximation[-index]
                    }
                }
            }
            newApproximation[j] = currentValue
        }

        return newApproximation
    }

    private static func waveletFunction(from scalingFunction: [Float], level: Int, coefficients: [Float]) -> [Float] {
        let distance = Int(pow(2, Float(level)))
        var waveletFunction = [Float](repeating: 0, count: scalingFunction.count)

        for t in 0..<waveletFunction.count {
            var currentValue: Float = 0
            for k in 0..<coefficients.count {
                let index = 2*t - k*distance
                if(index < 0 || index >= scalingFunction.count) {continue}
                currentValue += scalingFunction[index] * coefficients[k]
            }
            waveletFunction[t] = currentValue
        }

        return waveletFunction
    }

}

public struct WaveletPacket {
    //level:     1    2
    //          10  100
    //              101
    //          11  110
    //              111
    public enum LevelType: Int {
        case scaling = 0
        case wavelet = 1
    }
    public typealias WaveletPacketCode = UInt

    public var values: [Float]
    public var code: WaveletPacketCode
    public var level: Int {
        get {
            let msb = WaveletPacket.mostSignificantBit(of: code)
            return Int(msb.position)-1
        }
    }
    public var levels: [LevelType] {
        get {
            var types = [LevelType](repeating: .scaling, count: level)
            var bit: UInt = 1
            for l in 0..<level {
                if(code & bit > 0) {
                    types[level-l-1] = .wavelet
                }
                bit = bit*2
            }
            return types
        }
        set(newTypes) {
            code = 1
            for type in newTypes {
                code = code*2
                code = code + UInt(type.rawValue)
            }
        }
    }
    /// Number of signal samples one value is representing (2^level)
    public var length: Int {
        get {
            let l = 1 << level
            return l
        }
    }
    /// Position in the spectrum form 0 (lowest frequencies) to (2^level)-1 (highest frequencies)
    public var position: Int {
        return Int(code) - length
    }

    public init(values: [Float], levels: [LevelType]) {
        self.values = values
        self.code = 1
        self.levels = levels
    }

    public init(values: [Float], code: WaveletPacketCode) {
        self.values = values
        self.code = code
    }

    private static func mostSignificantBit(of n: UInt) -> (value: UInt, position: UInt) {
        if n < 1 {
            return (0, 0)
        }

        var msbValue: UInt = 1
        var msbPosition: UInt = 1
        while msbValue <= n {
            msbValue = msbValue*2
            msbPosition += 1
        }

        return (msbValue/2, msbPosition-1)
    }

    public mutating func addLevel(_ type: LevelType) {
        let newCode = code << 1
        code = newCode + UInt(type.rawValue)
    }

    public func levelAdded(_ type: LevelType) -> WaveletPacketCode {
        let new = code << 1 + UInt(type.rawValue)
        return new
    }

}

public func waveletPacketTransform(signal: [Float], wavelet: Wavelet, innerCodes: [WaveletPacket.WaveletPacketCode]) -> [WaveletPacket] {

    //determine all scaling representations that have to be calculated
    var scalingCodes: [WaveletPacket.WaveletPacketCode] = []
    for thisCode in innerCodes {
        var p = thisCode
        while p > 1 {
            if p % 2 != 0 {
                p = p-1
            }
            if scalingCodes.contains(p) {
                break
            }

            scalingCodes.append(p)
            p = p/2
        }
    }

    scalingCodes.sort(by: {$0 < $1})
    print("packet transform scaling codes: \(scalingCodes)")

    var packets: [WaveletPacket] = [WaveletPacket(values: signal, code: 1)]

    for thisCode in scalingCodes {

        guard let i = packets.index(where: {$0.code == thisCode/2}) else {
            print("error: no signal with code \(thisCode/2) found")
            break
        }

        let parentPacket = packets[i]
        let a  = waveletTransformForwardStep(signal: parentPacket.values, h0: wavelet.h0, h1: wavelet.h1)
        packets.append(WaveletPacket(values: a.r0, levels: parentPacket.levels + [.scaling]))
        packets.append(WaveletPacket(values: a.r1, levels: parentPacket.levels + [.wavelet]))

        packets.remove(at: i)
    }

    return packets
}

public func waveletTransformForwardStep<A: UnsafeBuffer>(signal: A, h0: A, h1: A) -> (r0: [Float], r1: [Float]) where A.Iterator.Element == Float, A.Index == Int {

    let n0 = UInt(signal.count / 2 - h0.count + 1)
    let n1 = UInt(signal.count / 2 - h1.count + 1)

    var r0 = [Float](repeating: 0, count: signal.count/2)
    var r1 = [Float](repeating: 0, count: signal.count/2)

    signal.performWithUnsafeBufferPointer { (sPointer: UnsafeBufferPointer<Float>) -> Void in
        h0.performWithUnsafeBufferPointer({ (h0Pointer: UnsafeBufferPointer<Float>) -> Void in
            vDSP_desamp(sPointer.baseAddress!, 2, h0Pointer.baseAddress!, &r0, n0, UInt(h0.count))
        })
        h1.performWithUnsafeBufferPointer({ (h1Pointer: UnsafeBufferPointer<Float>) -> Void in
            vDSP_desamp(sPointer.baseAddress!, 2, h1Pointer.baseAddress!, &r1, n1, UInt(h1.count))
        })
    }

    return(r0, r1)
}
