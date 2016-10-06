//
//  TensorOperationNodes.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 20.07.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

public protocol TensorOperationNode {
    static var inputCount: Int {get}
    static var outputCount: Int {get}
    mutating func setup()
    func execute(_ input: [Tensor<Float>]) -> [Tensor<Float>]
}

protocol TensorFourierTransform {
    static var transformSetup: (vDSP_DFT_Setup, vDSP_Length) -> OpaquePointer {get}
    static var transformFunction: (OpaquePointer, UnsafePointer<Float>, UnsafePointer<Float>, UnsafeMutablePointer<Float>, UnsafeMutablePointer<Float>) -> () {get}
    var modeSizes: [Int] {get}
    var transformSizes: [Int]! {get set}
    var dftSetups: [OpaquePointer] {get set}
}
extension TensorFourierTransform {
    mutating func setupTransform() {
        /// next biggest integer base 2 logarithms of the mode sizes
        let logSizes = modeSizes.map{Int(ceil(log2(Float($0))))}
        transformSizes = logSizes.map{Int(pow(2, Float($0)))}
        print("transform sizes: \(transformSizes)")
        
        //create dft setup for each mode
        dftSetups = []
        var currentSetup: OpaquePointer? = nil
        for size in transformSizes {
            currentSetup = Self.transformSetup(currentSetup!, UInt(size))
            dftSetups.append(currentSetup!)
        }
    }
    
    func performFourierTransform(_ input: Tensor<Float>) -> Tensor<Float> {
        var inputTensor = input
        print("input tensor sizes: \(inputTensor.modeSizes)")
        var outputTensor = [Tensor<Float>(withPropertiesOf: inputTensor)]
        
        for mode in 0..<modeSizes.count {
            var outerModes = inputTensor.modeArray
            outerModes.removeFirst()
            outerModes.remove(at: mode)
            //let modeSize = transformSizes[mode]
            let vectorSize = transformSizes[mode]
            ///array of padding zeros for the fft
//            let paddingZeros = [Float](count: vectorSize - modeSizes[mode], repeatedValue: 0)
            print("mode \(mode), vectorSize: \(vectorSize)")
            
            inputTensor.performForOuterModes(outerModes, outputData: &outputTensor,
                                             calculate: { (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
                                                let real = sourceData[slice: currentIndex][0...0, all].values
                                                let imag = sourceData[slice: currentIndex][1...1, all].values
                                                
                                                print("index \(currentIndex) real vector: \(real)")
                                                print("index \(currentIndex) imag vector: \(imag)")
                                                
                                                var realOutValues = [Float](repeating: 0, count: vectorSize)
                                                var imagOutValues = [Float](repeating: 0, count: vectorSize)
                                                
                                                Self.transformFunction(self.dftSetups[mode], real, imag, &realOutValues, &imagOutValues)
                                                
                                                let outputValues = realOutValues + imagOutValues
                                                let output = Tensor<Float>(modeSizes: [2, vectorSize], values: outputValues)
//                                                print("index \(currentIndex) real output: \(realOutValues)")
//                                                print("index \(currentIndex) imag output: \(imagOutValues)")
                                                
                                                return [output]
                },
                                             writeOutput: { (currentIndex, outerIndex, inputData, outputData) in
                                                outputData[0][slice: currentIndex] = inputData[0]
            })
            
            inputTensor = outputTensor[0]
        }
        
        return outputTensor[0]
    }
}

public struct FourierTransform: TensorFourierTransform, TensorOperationNode {
    public static var inputCount = 1
    public static var outputCount = 1
    
    static var transformSetup: (vDSP_DFT_Setup, vDSP_Length) -> OpaquePointer = {(prevSetup, length) -> OpaquePointer in
        return vDSP_DFT_zop_CreateSetup(prevSetup, length, vDSP_DFT_Direction.FORWARD)!
    }
    static var transformFunction = {(setup, realIn, imagIn, realOut, imagOut) -> () in
        vDSP_DFT_Execute(setup, realIn, imagIn, realOut, imagOut)
    }
    
    var modeSizes: [Int]
    var transformSizes: [Int]!
    var dftSetups: [vDSP_DFT_Setup] = []
    
    public init(modeSizes: [Int]) {
        self.modeSizes = modeSizes
        setup()
    }
    
    mutating public func setup() {
        setupTransform()
    }
    
    public func execute(_ input: [Tensor<Float>]) -> [Tensor<Float>] {
        print("transform sizes: \(transformSizes)")
        let paddedInput = changeModeSizes(input[0], targetSizes: [2] + transformSizes)
        print("padded input sizes: \(paddedInput.modeSizes)")
        let output = performFourierTransform(paddedInput)
        return [output]
    }
}

public struct InverseFourierTransform: TensorFourierTransform, TensorOperationNode {
    public static var inputCount = 1
    public static var outputCount = 1
    
    static var transformSetup: (vDSP_DFT_Setup, vDSP_Length) -> OpaquePointer = {(prevSetup, length) -> OpaquePointer in
        return vDSP_DFT_zop_CreateSetup(prevSetup, length, vDSP_DFT_Direction.INVERSE)!
    }
    static var transformFunction = {(setup, realIn, imagIn, realOut, imagOut) -> () in
        vDSP_DFT_Execute(setup, realIn, imagIn, realOut, imagOut)
    }
    
    var modeSizes: [Int]
    var transformSizes: [Int]!
    var dftSetups: [vDSP_DFT_Setup] = []
    
    public init(modeSizes: [Int]) {
        self.modeSizes = modeSizes
        setup()
    }
    
    mutating public func setup() {
        setupTransform()
    }
    
    public func execute(_ input: [Tensor<Float>]) -> [Tensor<Float>] {
        let factor = 1 / Float(transformSizes.reduce(1, {$0*$1}))
        let output = performFourierTransform(input[0]) * factor
        let scaledOutput = changeModeSizes(output, targetSizes: [2] + modeSizes)
        return [scaledOutput]
    }
}


