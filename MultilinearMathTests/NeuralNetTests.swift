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

    func testMNISTClassification() {
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

        let estimator =  NeuralNet(layerSizes: [28*28, 40, 10])
        estimator.layers[0].activationFunction = ReLU(secondarySlope: 0.01)
        estimator.layers[1].activationFunction = ReLU(secondarySlope: 0.01)
        let neuralNetCost = SquaredErrorCost(forEstimator: estimator)
        let regularizer = ParameterDecay(decayRate: 0.0001)
        neuralNetCost.regularizers[0] = regularizer
        neuralNetCost.regularizers[2] = regularizer

        let epochs = 30
        stochasticGradientDescent(neuralNetCost, inputs: trainingData[.a, .b], targets: trainingLabels[.a, .c], updateRate: 0.1, minibatchSize: 50, validationCallback: ({ (epoch, estimator) -> (Bool) in
            print("epoch \(epoch)")

            let estimate = estimator.output(validationData)
            let maximumIndices = findMaximumElementOf(estimate, inMode: 1)
            let correctValues = zip(validationLabels, maximumIndices.values).filter({$0.0 == $0.1})
            print("classified \(correctValues.count) of \(validationLabels.count) correctly")
            if(epoch >= epochs) {
                return true
            } else {
                return false
            }
        }))

        let testBatch = validationData[0..<10, all]
        let finalEstimate = neuralNetCost.estimator.output(testBatch)
        print("finalEstimate: \(finalEstimate.values)")
        let maximumIndices = findMaximumElementOf(finalEstimate, inMode: 1)
        print("max indices: \(maximumIndices.values)")
        let target = Array(validationLabels[0..<10])
        print("targets: \(target)")
    }
}
