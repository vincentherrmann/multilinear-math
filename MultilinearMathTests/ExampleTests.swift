//
//  ExampleTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 29.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class ExampleTests: XCTestCase {

    func testWriteValuesToTensor() {
        var a = Tensor<Float>(modeSizes: [4, 4, 4, 4], repeatedValue: 0)
        
        a[1, 0, 3, 2] = 2
        a[2...2, [3], [0], 1..<3] = Tensor<Float>(modeSizes: [2], values: [3.3, 4.4])
        a[[0, 3], 1...1, [0, 2, 3], 0...1] = Tensor<Float>(modeSizes: [2, 3, 2], values: [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
        a[all, 2...2, 2...3, all] = Tensor<Float>(modeSizes: [4, 2, 4], repeatedValue: 5.5)
        
        print("a values: \(a.values)")
    }
    
    func testUMPCA() {
        let faces = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/XCode/MultilinearMath/MultilinearMath/Data/Faces100x32x32.txt", modeSizes: [100, 32, 32])
        
        let (facesNorm, mean, deviation) = normalize(faces, overModes: [0])
        
        let (uFaces, uEMPs) = uncorrelatedMPCA(facesNorm, featureCount: 25)
        let reconstructeduFaces = uncorrelatedMPCAReconstruct(uFaces, projections: uEMPs)
    }

}
