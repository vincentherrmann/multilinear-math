//
//  WaveletTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 14.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class WaveletTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testDB4() {
        let db4: [Float] = [0.48296291314469025, 0.836516303737469, 0.22414386804185735, -0.12940952255092145].map({$0 * pow(2, 0.5)})
        //let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
        let db4Wavelet = scalingFunction(from: db4, levels: 0)
        print("db4: \(db4Wavelet)")
    }

    func testDB6() {
        //let db6: [Float] = [0.035226291882100656, -0.08544127388224149, -0.13501102001039084, 0.4598775021193313, 0.8068915093133388, 0.3326705529509569]
        let db6: [Float] = [0.3326705529509569, 0.8068915093133388, 0.4598775021193313, -0.13501102001039084, -0.08544127388224149, 0.035226291882100656].map({$0 * pow(2, 0.5)})


        //let db6: [Float] = [0.47046721, 1.14111692, 0.650365, -0.19093442, -0.12083221, 0.0498175]
        let db6Wavelet = scalingFunction(from: db6, levels: 0)
        print("db6: \(db6Wavelet)")
    }

    func testDB8() {

        let db8: [Float] = [0.23037781330885523, 0.7148465705525415, 0.6308807679295904, -0.02798376941698385, -0.18703481171888114, 0.030841381835986965, 0.032883011666982945, -0.010597401784997278].map({$0 * pow(2, 0.5)})


        //let db8: [Float] = [1, 0, -2, 3, 4, 1, 1, -3]
        let db8Wavelet = scalingFunction(from: db8, levels: 0)
        print("db8: \(db8Wavelet)")
    }

//    func testFrequencyResponse() {
//        let db4: [Float] = [0.48296291314469025, 0.836516303737469, 0.22414386804185735, -0.12940952255092145].map({$0 * pow(2, 0.5)})
//        let spectrum = FIRFilter(coefficients: db4)
//        let v = Array(0..<99).map({(Float($0)/100)})
//        let fr = v.map({spectrum.frequencyResponse(6.28*$0 - 3.14)})
//        let impulseResponse = fr.map({$0.r * $0.i})
//        print("ir: \(impulseResponse)")
//    }

    func testDaubechiesCoefficients() {
        let db6 = calculateDaubechiesCoefficients(vanishingMoments: 3)
        let db6Tensor = Tensor<Float>(modeSizes: [6], values: db6)
        let target = Tensor<Float>(modeSizes: [6], values: [0.049817, -0.12083, -0.19093, 0.65037, 1.1411, 0.47047])

        let s = sum(db6Tensor[.a] - target[.a], overModes: [0])

        XCTAssert(abs(s.values[0]) < 0.01, "wrong daubechies 6 coefficients: \(db6)")

        print("daubechies 6 coefficients: \(db6)")
    }

    func testFlatDelayAllpass() {
        let d3 = flatDelayCoefficients(count: 3, delay: 0.5)
        print("d3: \(d3)")

        let d4 = flatDelayCoefficients(count: 4, delay: 0.5)
        print("d4: \(d4)")
    }

    func testComplexWavelet() {
        let cA4L2 = calculateComplexWaveletCoefficients(vanishingMoments: 4, delayCoefficients: 3, rootsOutsideUnitCircle: [1, 2])
        let real = cA4L2.map({$0.real})
        let imag = cA4L2.map({$0.imaginary})

        print("cA4L2midPhase real: \(real)")
        print("cA4L2midPhase imaginary: \(imag)")

        let scaling = scalingFunction(from: real, levels: 6)
        let reconstructedReal = coefficientsFromScalingFunction(values: scaling, count: 12)
        print("reconstructed real: \(reconstructedReal)")


    }

    func testForwardFWT() {
        let db4 = DaubechiesWavelet(vanishingMoments: 2)
        let signal = Array(0..<128).map({Float($0)/10}).map({sin(3*$0)})
        var currentSignal = signal
        var analysis: [[Float]] = []

        var a: (r0: [Float], r1: [Float]) = ([], [])
        for _ in 0..<4 {
            a = waveletTransformForwardStep(signal: currentSignal, h0: db4.h0, h1: db4.h1)
            currentSignal = a.r0

            analysis.append(a.r1)
        }

        analysis.append(a.r0)
    }

    func testPacketCode() {
        var c = WaveletPacket(values: [1, 2, 3, 4, 5, 6, 7], levels: [.scaling, .scaling, .wavelet])
        print("code: \(c.code), levels: \(c.levels), level: \(c.level), length: \(c.length)")

        c.addLevel(.scaling)
        print("code: \(c.code), levels: \(c.levels), level: \(c.level), length: \(c.length)")

        c.addLevel(.wavelet)
        print("code: \(c.code), levels: \(c.levels), level: \(c.level), length: \(c.length)")

    }

    func testPacketPlot() {
        let p1 = WaveletPacket(values: [0, 1, 2, 1], levels: [.wavelet])
        let p2 = WaveletPacket(values: [2, 0], levels: [.scaling, .wavelet])
        let p3 = WaveletPacket(values: [0, 1], levels: [.scaling, .scaling])

        let plot = FastWaveletPlot(packets: [p1, p2, p3])

    }

    func testPacketTransform() {
        let h0: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
        let w = Wavelet(h0: h0, f0: h0.reversed())

        let count: Int = 1024
        let length: Float = 30
        let xArray = Array(0..<count).map({Float($0) * length / Float(count)})

        let signal = xArray.map({sin(9*$0)})

        let packets = waveletPacketTransform(signal: signal, wavelet: w, innerCodes: [8])

    }

    func testFrequencyResponse2() {
        let cReal: [Float] = [-0.00252085552, 0.0188991688, 0.0510309711, -0.0490589067, 0.0589671507, 0.79271543, 1.0953089, 0.32142213, -0.227000564, -0.0872127786, 0.0242141522, 0.0032346386]

        let filter = FIRFilter(coefficients: cReal)
        let ft1 = filter.frequencyResponse()

    }

}

