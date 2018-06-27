//
//  FourierTransformTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 05.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class FourierTransformTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testFFTNodes() {
        //setup nodes
        let forwardFFT = FourierTransform(modeSizes: [3, 7])
        let inverseFFT = InverseFourierTransform(modeSizes: [3, 7])

        let inputSignal = randomTensor(modeSizes: 2, 3, 7).uniquelyIndexed()
        print("original signal: \(inputSignal.values)")
        let transformedSignal = forwardFFT.execute([inputSignal])
        let reconstructedSignal = inverseFFT.execute(transformedSignal)[0]
        print("reconstructed signal: \(reconstructedSignal.values)")

        let factor = reconstructedSignal.values[0] / inputSignal.values[0]
        print("scaling factor for sizes \(inputSignal.modeSizes): \(factor)")

        let mse = meanSquaredError(target: inputSignal.values, result: reconstructedSignal.values)
        print("mse: \(mse)")
        XCTAssert(mse < 0.01, "no acceptable reconstruction from fourier transform")
    }

}
