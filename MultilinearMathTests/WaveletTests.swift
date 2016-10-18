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
        let db4Wavelet = createWaveletFromCoefficients(db4, levels: 0)
        print("db4: \(db4Wavelet)")
    }
    
    func testDB6() {
        //let db6: [Float] = [0.035226291882100656, -0.08544127388224149, -0.13501102001039084, 0.4598775021193313, 0.8068915093133388, 0.3326705529509569]
        let db6: [Float] = [0.3326705529509569, 0.8068915093133388, 0.4598775021193313, -0.13501102001039084, -0.08544127388224149, 0.035226291882100656].map({$0 * pow(2, 0.5)})
        

        //let db6: [Float] = [0.47046721, 1.14111692, 0.650365, -0.19093442, -0.12083221, 0.0498175]
        let db6Wavelet = createWaveletFromCoefficients(db6, levels: 0)
        print("db6: \(db6Wavelet)")
    }
    
    func testDB8() {
        
        let db8: [Float] = [0.23037781330885523, 0.7148465705525415, 0.6308807679295904, -0.02798376941698385, -0.18703481171888114, 0.030841381835986965, 0.032883011666982945, -0.010597401784997278].map({$0 * pow(2, 0.5)})
        

        //let db8: [Float] = [1, 0, -2, 3, 4, 1, 1, -3]
        let db8Wavelet = createWaveletFromCoefficients(db8, levels: 0)
        print("db8: \(db8Wavelet)")
    }
    
    func testFrequencyResponse() {
        let db4: [Float] = [0.48296291314469025, 0.836516303737469, 0.22414386804185735, -0.12940952255092145].map({$0 * pow(2, 0.5)})
        let spectrum = FIRFilter(coefficients: db4)
        let v = Array(0..<99).map({(Float($0)/100)})
        let fr = v.map({spectrum.frequencyResponse(6.28*$0 - 3.14)})
        let impulseResponse = fr.map({$0.r * $0.i})
        print("ir: \(impulseResponse)")
    }
    
    func testDaubechiesCoefficients() {
        let db6 = calculateDaubechiesCoefficients(vanishingMoments: 3)
        print("daubechies 6 coefficients: \(db6)")
    }

}

