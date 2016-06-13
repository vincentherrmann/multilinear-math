//
//  NeuralNetTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 13.06.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class NeuralNetTests: XCTestCase {

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func testMNISTClassification() {
        var estimator =  NeuralNet(layerSizes: [28*28, 25, 10])
        estimator.layers[0].activationFunction = ReLU(secondarySlope: 0.01)
        estimator.layers[1].activationFunction = ReLU(secondarySlope: 0.01)
        var neuralNetCost: CostFunction = SquaredErrorCost(forEstimator: estimator)
        
        print("load MNIST data...")
        let rawData = loadMNISTImageFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/train-images-2.idx3-ubyte")
        let rawLabels = loadMNISTLabelFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/train-labels.idx1-ubyte")
        
        print("normalize...")
        let data = normalize(Tensor<Float>(modeSizes: [rawData.modeSizes[0], 28*28], values: rawData.values), overModes: [0]).normalizedTensor
        let labels = createOneHotVectors(rawLabels.map({Int($0)}), differentValues: Array(0...9))
        let trainingData = data[0..<50000, all]
        let trainingLabels = labels[0..<50000, all]
        let validationData = data[50000..<60000, all]
        let validationLabels = rawLabels[50000..<60000].map({Float($0)})
        
        stochasticGradientDescent(&neuralNetCost, inputs: trainingData[.a, .b], targets: trainingLabels[.a, .c], updateRate: 0.03, convergenceThreshold: 0.00001, maxLoops: 4000, minibatchSize: 50, validationCallback: ({ (epoch, estimator) -> () in
            print("epoch \(epoch)")
            let estimate = estimator.output(validationData)
            let maximumIndices = findMaximumElementOf(estimate, inMode: 1)
            let correctValues = zip(validationLabels, maximumIndices.values).filter({$0.0 == $0.1})
            print("classified \(correctValues.count) of \(validationLabels.count) correctly")
        }))
        
        let testBatch = validationData[0..<10, all]
        let finalEstimate = neuralNetCost.estimator.output(testBatch)
        print("finalEstimate: \(finalEstimate.values)")
        let maximumIndices = findMaximumElementOf(finalEstimate, inMode: 1)
        print("max indices: \(maximumIndices.values)")
        let target = Array(validationLabels[0..<10])
        print("targets: \(target)")
    }

    func testExample() {
        // This is an example of a functional test case.
        // Use XCTAssert and related functions to verify your tests produce the correct results.
    }

    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock {
            // Put the code you want to measure the time of here.
        }
    }

}
