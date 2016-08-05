//
//  TensorOperationNodes.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 20.07.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

protocol TensorOperationNode {
    static var inputCount: Int {get}
    static var outputCount: Int {get}
    mutating func setup()
    func execute(input: [Tensor<Float>]) -> [Tensor<Float>]
}

struct RealToComplexFFT: TensorOperationNode {
    static var inputCount = 1
    static var outputCount = 1
    
    var modeSizes: [Int]
    var logSizes: [Int]!
    var dftSetup: vDSP_DFT_Setup!
    
    init(modeSizes: [Int]) {
        self.modeSizes = modeSizes
        setup()
    }
    
    mutating func setup() {
        /// next biggest integer base 2 logarithms of the mode sizes
        logSizes = modeSizes.map{Int(ceil(log2(Float($0))))}
        dftSetup = vDSP_DFT_zrop_CreateSetup(nil, UInt(logSizes.maxElement()!), .FORWARD)
    }
    
    
    func execute(input: [Tensor<Float>]) -> [Tensor<Float>] {
        var inputTensor = input[0]
        
        var outputTensor = [Tensor<Float>(withPropertiesOf: inputTensor)]
        
        for mode in 0..<modeSizes.count {
            var outerModes = inputTensor.modeArray
            outerModes.removeAtIndex(mode)
            ///array of padding zeros for the fft
            //let paddingZeros = [Float](count: Int(pow(2, Float(logSizes[mode]))) - inputTensor.modeSizes[mode], repeatedValue: 0)
            let vectorSize = Int(pow(2, Float(logSizes[mode])))
            var realInValues = [Float](count: vectorSize/2, repeatedValue: 0)
            var imagInValues = [Float](count: vectorSize/2, repeatedValue: 0)
            var inputVector: DSPSplitComplex = DSPSplitComplex(realp: &realInValues, imagp: &imagInValues)
            var realOutValues = [Float](count: vectorSize/2, repeatedValue: 0)
            var imagOutValues = [Float](count: vectorSize/2, repeatedValue: 0)
            var outputVector: DSPSplitComplex = DSPSplitComplex(realp: &realOutValues, imagp: &imagOutValues)
            
            inputTensor.performForOuterModes(outerModes, outputData: &outputTensor,
                                             calculate: { (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
                                                let vector = sourceData[slice: currentIndex].values
                                                vDSP_ctoz(self.complexPointer(vector), 1, &inputVector, 1, UInt(self.modeSizes[mode]))
                                                vDSP_DFT_Execute(self.dftSetup, inputVector.realp, inputVector.imagp, outputVector.realp, outputVector.imagp)
                                                let realOut = Tensor<Float>(modeSizes: [vectorSize/2], values: realOutValues)
                                                let imagOut = Tensor<Float>(modeSizes: [vectorSize/2], values: imagOutValues)
                                                return [realOut, imagOut]
                },
                                             writeOutput: { (currentIndex, outerIndex, inputData, outputData) in
                    <#code#>
            })
        }
    }
    
    func complexPointer(vector: UnsafePointer<Float>) -> UnsafePointer<DSPComplex> {
        return UnsafePointer(vector)
    }
}

protocol TensorFourierTransform {
    static var transformSetup: (vDSP_DFT_Setup, vDSP_Length) -> COpaquePointer {get}
    static var transformFunction: (COpaquePointer, UnsafePointer<Float>, UnsafePointer<Float>, UnsafeMutablePointer<Float>, UnsafeMutablePointer<Float>) -> () {get}
    var modeSizes: [Int] {get}
    var logSizes: [Int] {get set}
    var dftSetups: [COpaquePointer] {get set}
}
extension TensorFourierTransform {
    mutating func setupTransform() {
        /// next biggest integer base 2 logarithms of the mode sizes
        logSizes = modeSizes.map{Int(ceil(log2(Float($0))))}
        
        //create dft setup for each mode
        dftSetups = []
        var currentSetup: COpaquePointer = nil
        for size in logSizes {
            currentSetup = Self.transformSetup(currentSetup, UInt(size))
            dftSetups.append(currentSetup)
        }
    }
    
    func performFourierTransform(input: Tensor<Float>) -> Tensor<Float> {
        var inputTensor = input
        var outputTensor = [Tensor<Float>(withPropertiesOf: inputTensor)]
        
        for mode in 0..<modeSizes.count {
            var outerModes = inputTensor.modeArray
            outerModes.removeFirst()
            outerModes.removeAtIndex(mode)
            let modeSize = modeSizes[mode]
            let vectorSize = Int(pow(2, Float(logSizes[mode])))
            ///array of padding zeros for the fft
            let paddingZeros = [Float](count: vectorSize - inputTensor.modeSizes[mode], repeatedValue: 0)
            
            var realOutValues = [Float](count: vectorSize, repeatedValue: 0)
            var imagOutValues = [Float](count: vectorSize, repeatedValue: 0)
            
            inputTensor.performForOuterModes(outerModes, outputData: &outputTensor,
                                             calculate: { (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
                                                let real = sourceData[slice: currentIndex][0...0, all].values + paddingZeros
                                                let imag = sourceData[slice: currentIndex][1...1, all].values + paddingZeros
                                                
                                                Self.transformFunction(self.dftSetups[mode], real, imag, &realOutValues, &imagOutValues)
                                                
                                                let outputValues = Array(realOutValues[0..<modeSize]) + Array(imagOutValues[0..<modeSize])
                                                let output = Tensor<Float>(modeSizes: [2, vectorSize], values: outputValues)
                                                return [output]
                },
                                             writeOutput: { (currentIndex, outerIndex, inputData, outputData) in
                                                outputData[0][slice: outerIndex] = inputData[0]
            })
            
            inputTensor = outputTensor[0]
        }
        
        return outputTensor[0]
    }
}

struct FourierTransform: TensorFourierTransform, TensorOperationNode {
    static var inputCount = 1
    static var outputCount = 1
    
    static var transformSetup = {(prevSetup, length) -> COpaquePointer in
        return vDSP_DFT_zop_CreateSetup(prevSetup, length, vDSP_DFT_Direction.FORWARD)
    }
    static var transformFunction = {(setup, realIn, imagIn, realOut, imagOut) -> () in
        vDSP_DFT_Execute(setup, realIn, imagIn, realOut, imagOut)
    }
    
    var modeSizes: [Int]
    var logSizes: [Int]
    var dftSetups: [vDSP_DFT_Setup]
    
    init(modeSizes: [Int]) {
        self.modeSizes = modeSizes
        setup()
    }
    
    mutating func setup() {
        setupTransform()
    }
    
    func execute(input: [Tensor<Float>]) -> [Tensor<Float>] {
        let output = performFourierTransform(input[0])
        return [output]
    }
}

struct InverseFourierTransform: TensorFourierTransform, TensorOperationNode {
    static var inputCount = 1
    static var outputCount = 1
    
    static var transformSetup = {(prevSetup, length) -> COpaquePointer in
        return vDSP_DFT_zop_CreateSetup(prevSetup, length, vDSP_DFT_Direction.INVERSE)
    }
    static var transformFunction = {(setup, realIn, imagIn, realOut, imagOut) -> () in
        vDSP_DFT_Execute(setup, realIn, imagIn, realOut, imagOut)
    }
    
    var modeSizes: [Int]
    var logSizes: [Int]
    var dftSetups: [vDSP_DFT_Setup]
    
    init(modeSizes: [Int]) {
        self.modeSizes = modeSizes
        setup()
    }
    
    mutating func setup() {
        setupTransform()
    }
    
    func execute(input: [Tensor<Float>]) -> [Tensor<Float>] {
        let output = performFourierTransform(input[0])
        return [output]
    }
}

/// Operation node for multidimensional forward complex to complex FFT with zero padding. First most must have size 2 and depict real and complex.
struct FFT: TensorOperationNode {
    static var inputCount = 1
    static var outputCount = 1
    
    var modeSizes: [Int]
    var logSizes: [Int]!
    var dftSetups: [vDSP_DFT_Setup]
    
    init(modeSizes: [Int]) {
        self.modeSizes = modeSizes
        setup()
    }
    
    mutating func setup() {
        /// next biggest integer base 2 logarithms of the mode sizes
        logSizes = modeSizes.map{Int(ceil(log2(Float($0))))}
        
        //create dft setup for each mode
        dftSetups = []
        var currentSetup: vDSP_DFT_Setup = nil
        for size in logSizes {
            currentSetup = vDSP_DFT_zop_CreateSetup(currentSetup, UInt(size), .FORWARD)
            dftSetups.append(currentSetup)
        }
    }
    
    func execute(input: [Tensor<Float>]) -> [Tensor<Float>] {
        var inputTensor = input[0]
        var outputTensor = [Tensor<Float>(withPropertiesOf: inputTensor)]
        
        for mode in 0..<modeSizes.count {
            var outerModes = inputTensor.modeArray
            outerModes.removeFirst()
            outerModes.removeAtIndex(mode)
            let modeSize = modeSizes[mode]
            let vectorSize = Int(pow(2, Float(logSizes[mode])))
            ///array of padding zeros for the fft
            let paddingZeros = [Float](count: vectorSize - inputTensor.modeSizes[mode], repeatedValue: 0)
            
            var realOutValues = [Float](count: vectorSize, repeatedValue: 0)
            var imagOutValues = [Float](count: vectorSize, repeatedValue: 0)
            
            inputTensor.performForOuterModes(outerModes, outputData: &outputTensor,
                                             calculate: { (currentIndex, outerIndex, sourceData) -> [Tensor<Float>] in
                                                let real = sourceData[slice: currentIndex][0...0, all].values + paddingZeros
                                                let imag = sourceData[slice: currentIndex][1...1, all].values + paddingZeros
                                            
                                                vDSP_DFT_Execute(self.dftSetups[mode], real, imag, &realOutValues, &imagOutValues)
                                            
                                                let outputValues = Array(realOutValues[0..<modeSize]) + Array(imagOutValues[0..<modeSize])
                                                let output = Tensor<Float>(modeSizes: [2, vectorSize], values: outputValues)
                                                return [output]
                },
                                             writeOutput: { (currentIndex, outerIndex, inputData, outputData) in
                                                outputData[0][slice: outerIndex] = inputData[0]
            })
            
            inputTensor = outputTensor[0]
        }
        
        return outputTensor
    }
}



