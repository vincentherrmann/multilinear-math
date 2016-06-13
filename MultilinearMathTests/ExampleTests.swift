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
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

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
        let facesWithDeviation = multiplyElementwise(a: facesNorm, commonModesA: [1, 2], outerModesA: [0], b: deviation, commonModesB: [0, 1], outerModesB: [])
        let facesWithMean = add(a: facesWithDeviation, commonModesA: [1, 2], outerModesA: [0], b: mean, commonModesB: [0, 1], outerModesB: [])
        
        let (uFaces, uEMPs) = uncorrelatedMPCA(facesNorm, featureCount: 8)
        let reconstructeduFaces = uncorrelatedMPCAReconstruct(uFaces, projections: uEMPs)
    }
    
    func testMPCAwithLargeDataset() {
        print("load data... \(NSDate())")
        let faces = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/MachineLearningMOOC/machine-learning-ex7/ex7/ex7faces.csv", modeSizes: [5000, 32, 32])
        
        print("normalize data... \(NSDate())")
        let (facesNorm, mean, deviation) = normalize(faces, overModes: [0])
        print("denormalize data... \(NSDate())")
        let facesWithDeviation = multiplyElementwise(a: facesNorm, commonModesA: [1, 2], outerModesA: [0], b: deviation, commonModesB: [0, 1], outerModesB: [])
        let facesWithMean = add(a: facesWithDeviation, commonModesA: [1, 2], outerModesA: [0], b: mean, commonModesB: [0, 1], outerModesB: [])
        
        print("calculate UMPCA... \(NSDate())")
        let (uFaces, uEMPs) = uncorrelatedMPCA(facesNorm, featureCount: 8)
        print("reconstruct data... \(NSDate())")
        let reconstructeduFaces = uncorrelatedMPCAReconstruct(uFaces, projections: uEMPs)
        
        
        print("calculate MPCA... \(NSData())")
        let mFaces = multilinearPCA(facesNorm, projectionModeSizes: [10, 10])
        
        //debug: 345 seconds
        //release(whole module optimization): 55 seconds
        //six-fold performance increase
    }
    
    func testLinearRegression() {
        let data = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/DataSets/Misc/Data3D.txt")
        let x = data[all, 0...1]
        let y = data[all, 2...2]
        let testTensor = Tensor<Float>(modeSizes: [2], values: [2100.0, 3.0])
        
        let parameters = linearRegression(x: x, y: y)
        print("parameters linear regression closed form: \(parameters.values)")
        let test = parameters[TensorIndex.a] * (Tensor<Float>(modeSizes: [3], values: [1] + testTensor.values))[TensorIndex.a]
        print("test result: \(test.values)")
        
//        
//        let (parametersGD, meanGD, deviationGD) = linearRegressionGD(x: x, y: y)
//        print("parameters linear regression gradient descent: \(parametersGD.values)")
//        let normalizedTestTensor = normalize(testTensor, overModes: [], withMean: meanGD, deviation: deviationGD)
//        let testGD = parametersGD[TensorIndex.a] * concatenate(a: ones(1), b: normalizedTestTensor, alongMode: 0)[TensorIndex.a]
//        print("GD test result: \(testGD.values)")
    }
    
    func testSGDLinearRegression() {
        let data = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/DataSets/Misc/Data3D.txt")
        let x = data[all, 0...1]
        let y = data[all, 2...2]
        let (xNorm, mean, deviation) = normalize(x, overModes: [0])
        let testTensor = Tensor<Float>(modeSizes: [2], values: [2100.0, 3.0])
        
        var costFunction: CostFunction = LinearRegressionCost(featureCount: 2)
        
        stochasticGradientDescent(&costFunction, inputs: xNorm, targets: y, updateRate: 5.0, convergenceThreshold: 0.0001, maxLoops: 200, minibatchSize: 47)
        print("parameters: \(costFunction.estimator.parameters[0].values + costFunction.estimator.parameters[1].values)")
        
        let normalizedTestTensor = normalize(testTensor, overModes: [], withMean: mean, deviation: deviation)
        let test = costFunction.estimator.output(normalizedTestTensor)
        print("linear regression result for input \(testTensor.values): \(test.values[0])")
        
        XCTAssert((354000 < test.values[0]) && (test.values[0] < 356000), "linear regression with SGD test")
    }
    
//    func testLogisticRegression() {
//        let data = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/DataSets/Misc/examScoresClassify.txt", modeSizes: [100, 3])
//        let x = data[all, 0...1]
//        let y = data[all, 2...2]
//        
//        let (xNorm, mean, deviation) = normalize(x, overModes: [0])
//        
//        let parameters = logisticRegression(x: xNorm, y: y)
//        print("parameters logistic regression: \(parameters)")
//        
//        let testValues = normalize(Tensor<Float>(modeSizes: [3, 2], values: [40, 50, 70, 60, 90, 90]), overModes: [1], withMean: mean, deviation: deviation)
//        let tVwithOnes = concatenate(a: ones(3), b: testValues, alongMode: 1)
//        let test = sigmoid(parameters[TensorIndex.b] * tVwithOnes[.a, .b])
//        print("logistic regression result: \(test.values)")
//    }
    
    func testSGDLogisticRegression() {
        let data = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/DataSets/Misc/examScoresClassify.txt", modeSizes: [100, 3])
        let x = data[all, 0...1]
        let y = data[all, 2...2]
        
        let (xNorm, mean, deviation) = normalize(x, overModes: [0])
        
        var costFunction: CostFunction = LogisticRegressionCost(featureCount: 2)
        
        stochasticGradientDescent(&costFunction, inputs: xNorm, targets: y, updateRate: 1.0, convergenceThreshold: 0.001, maxLoops: 200, minibatchSize: 25)
        print("parameters: \(costFunction.estimator.parameters[0].values + costFunction.estimator.parameters[1].values)")
        
        let testValues = normalize(Tensor<Float>(modeSizes: [3, 2], values: [40, 50, 70, 60, 90, 90]), overModes: [1], withMean: mean, deviation: deviation)
        let test = costFunction.estimator.output(testValues)
        print("logistic regression result: \(test.values)")
        XCTAssert((test.values[0] < 0.1) && (0.5 < test.values[1]) && (test.values[1] < 0.8) && (0.99 < test.values[2]), "logistic regression with SGD test")
    }
    
    func testMiniNeuralNet() {
        let data = Tensor<Float>(valuesFromFileAtPath: "/Users/vincentherrmann/Documents/Software/DataSets/Misc/examScoresClassify.txt", modeSizes: [100, 3])
        let x = data[all, 0...1]
        let y = data[all, 2...2]
        
        let (xNorm, mean, deviation) = normalize(x, overModes: [0])
        
        var neuralNetCostFunction: CostFunction = SquaredErrorCost(forEstimator: NeuralNet(layerSizes: [2, 3, 3, 1]))
        stochasticGradientDescent(&neuralNetCostFunction, inputs: xNorm, targets: y, updateRate: 10.0, convergenceThreshold: 0.0001, maxLoops: 200, minibatchSize: 25)
        
        let testValues = normalize(Tensor<Float>(modeSizes: [3, 2], values: [40, 50, 70, 60, 90, 90]), overModes: [1], withMean: mean, deviation: deviation)
        let test = neuralNetCostFunction.estimator.output(testValues)
        print("neural net result: \(test.values)")
        
    }
    
    func testNeuralNetGradient() {
        var neuralNetCost: CostFunction = SquaredErrorCost(forEstimator: NeuralNet(layerSizes: [4, 6, 5, 3]))
        let input = randomTensor(min: -1, max: 1, modeSizes: 10, 4)
        let target = randomTensor(min: 0, max: 1, modeSizes: 10, 3)
        let estimate = neuralNetCost.estimator.output(input)
        
        let costGradient = neuralNetCost.gradientForEstimate(estimate, target: target)
        let automaticGradient = neuralNetCost.estimator.gradients(costGradient)
        let numericalGradient = neuralNetCost.numericalGradients(input, target: target, epsilon: 0.1)
        
        for p in 0..<numericalGradient.count {
            let costs = automaticGradient.wrtParameters[p].values.combineWith(numericalGradient[p].values, combineFunction: { (i: Float, e: Float) -> Float in
                let dev = i != 0 ? (abs(i-e) / abs(i)) : 0
                return dev
            })
            let totalDeviation = vectorSummation(costs) / Float(numericalGradient[p].elementCount)
            print("average gradient deviation for parameters \(p): \(totalDeviation*100)%")
        }
        
    }
    
    func testMNISTGradient() {
        var neuralNetCost: CostFunction = SquaredErrorCost(forEstimator: NeuralNet(layerSizes: [28*28, 15, 10]))
        
        let x_values = loadMNISTImageFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/t10k-images.idx3-ubyte")
        let x = Tensor<Float>(modeSizes: [x_values.modeSizes[0], 28*28], values: x_values.values) - 0.5
        let y_labels = loadMNISTLabelFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/t10k-labels.idx1-ubyte")
        let y = createOneHotVectors(y_labels.map({Int($0)}), differentValues: Array(0...9))
        
        let input = x[0..<10, all]
        let target = y[0..<10, all]
        let estimate = neuralNetCost.estimator.output(input)
        
        let costGradient = neuralNetCost.gradientForEstimate(estimate, target: target)
        let automaticGradient = neuralNetCost.estimator.gradients(costGradient)
        print("computing numerical gradient")
        let numericalGradient = neuralNetCost.numericalGradients(input, target: target, epsilon: 0.1)
        print("...done")
        
        for p in 0..<numericalGradient.count {
            let costs = automaticGradient.wrtParameters[p].values.combineWith(numericalGradient[p].values, combineFunction: { (i: Float, e: Float) -> Float in
                let dev = i != 0 ? (abs(i-e) / abs(i)) : 0
                return dev
            })
            let totalDeviation = vectorSummation(costs) / Float(numericalGradient[p].elementCount)
            print("average gradient deviation for parameters \(p): \(totalDeviation*100)%")
        }
        
    }
    
    func testNeuralNetworkMNIST() {
        //var neuralNetCost: CostFunction = SquaredErrorCost(forEstimator: NeuralNet(layerSizes: [28*28, 25, 10]))
        var estimator =  NeuralNet(layerSizes: [28*28, 25, 10])
        estimator.layers[0].activationFunction = ReLU.self
        estimator.layers[1].activationFunction = ReLU.self
        var neuralNetCost: CostFunction = SquaredErrorCost(forEstimator: estimator)
        
        let x_values = loadMNISTImageFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/t10k-images.idx3-ubyte")
        print("normalize...")
        let x = normalize(Tensor<Float>(modeSizes: [x_values.modeSizes[0], 28*28], values: x_values.values), overModes: [0]).normalizedTensor
        let y_labels = loadMNISTLabelFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/t10k-labels.idx1-ubyte")
        let y = createOneHotVectors(y_labels.map({Int($0)}), differentValues: Array(0...9))
        
        //let (xNorm, mean, deviation) = normalize(x, overModes: [0])
        
        stochasticGradientDescent(&neuralNetCost, inputs: x[.a, .b], targets: y[.a, .c], updateRate: 0.03, convergenceThreshold: 0.000001, maxLoops: 4000, minibatchSize: 50)
        
        let testBatch = x[0..<10, all]
        let finalEstimate = neuralNetCost.estimator.output(testBatch)
        print("finalEstimate: \(finalEstimate.values)")
        let maximumIndices = findMaximumElementOf(finalEstimate, inMode: 1)
        print("max indices: \(maximumIndices.values)")
        let target = Array(y_labels[0..<10])
        print("targets: \(target)")
        
        
    }
    
//    func testOneVsAllClassification() {
//        let mnistImages = loadMNISTImageFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/t10k-images.idx3-ubyte")
//        let mnistData = Tensor<Float>(modeSizes: [mnistImages.modeSizes[0], mnistImages.modeSizes[1] * mnistImages.modeSizes[2]], values: mnistImages.values)
//        let mnistLabels = loadMNISTLabelFile("/Users/vincentherrmann/Documents/Software/DataSets/MNIST/t10k-labels.idx1-ubyte")
//        
//        print("normalize...")
//        let (mnistNorm, mean, deviation) = normalize(mnistData, overModes: [0])
//        let y = Tensor<Float>(modeSizes: [mnistLabels.count], values: mnistLabels.map({Float($0)}))
//        
//        print("one vs all logistic regression...")
//        let parameters = oneVsAllClassification(x: mnistNorm, y: y, classCount: 10)
//    }
    
//    func testFeedforwardNeuralNet() {
//        let net = FeedforwardNeuralNet(withLayerSizes: [3, 5, 4, 2])
//        let test = net.feedforward(ones(3))
//        
//    }

}
