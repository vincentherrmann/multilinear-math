//
//  TensorOperationsTests.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 09.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import XCTest
import MultilinearMath

class TensorOperationsTests: XCTestCase {

    var tensor1: Tensor<Float> = Tensor<Float>(scalar: 0)
    var tensor2: Tensor<Float> = Tensor<Float>(scalar: 0)

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.

        //  0  1  2  3      12 13 14 15
        //  4  5  6  7      16 17 18 19
        //  8  9 10 11      20 21 22 23
        tensor1 = Tensor<Float>(modeSizes: [2, 3, 4], values: Array(0..<24).map({return Float($0)}))
        tensor2 = Tensor<Float>(modeSizes: [4, 5, 3], values: Array(0..<60).map({return Float($0)}))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }

    func testTensorMultiplication() {

        var t1 = Tensor<Float>(modeSizes: [2, 3], values: Array(0..<6).map({return Float($0)}))
        var t2 = Tensor<Float>(modeSizes: [3, 4], values: Array(0..<12).map({return Float($0)}))
        t1.indices = [.a, .b]
        t2.indices = [.b, .c]
        var product = t1*t2
        var expectedProduct: [Float] = [20, 23, 26, 29, 56, 68, 80, 92]
        XCTAssertEqual(product.values, expectedProduct, "product 2x3 * 3x4")

        t1 = Tensor<Float>(modeSizes: [2, 2, 2], values: Array(0..<8).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [2, 2, 2], values: Array(0..<8).map({return Float($0)}))
        t1.indices = [.a, .b, .c]
        t2.indices = [.c, .d, .e]
        product = t1*t2
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for a in 0...1 {
            for b in 0...1 {
                for d in 0...1 {
                    for e in 0...1 {
                        var sum: Float = 0
                        for c in 0...1 {
                            sum += t1[a, b, c] * t2[c, d, e]
                        }
                        expectedProduct[product.flatIndex([a, b, d, e])] = sum
                    }
                }
            }
        }
        XCTAssertEqual(product.values, expectedProduct, "product 2x2x2 * 2x2x2")

        t1 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t1.indices = [.a, .b, .c]
        t2.indices = [.b, .c, .d]
        product = t1*t2
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for a in 0...2 {
            for d in 0...2 {
                var sum: Float = 0
                for b in 0...2 {
                    for c in 0...2 {
                        sum += t1[a, b, c] * t2[b, c, d]
                    }
                }
                expectedProduct[product.flatIndex([a, d])] = sum
            }
        }
        XCTAssertEqual(product.values, expectedProduct, "product 3x3x3 * 3x3x3")

        t1 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t1.indices = [.a, .b, .c]
        t2.indices = [.c, .b, .d]
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for a in 0...2 {
            for d in 0...2 {
                var sum: Float = 0
                for b in 0...2 {
                    for c in 0...2 {
                        sum += t1[a, b, c] * t2[c, b, d]
                    }
                }
                expectedProduct[product.flatIndex([a, d])] = sum
            }
        }
        product = t1*t2
        XCTAssertEqual(product.values, expectedProduct, "product 3x3x3 * 3x3x3")

        t1 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t1.indices = [.a, .b, .c]
        t2.indices = [.d, .c, .b]
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for a in 0...2 {
            for d in 0...2 {
                var sum: Float = 0
                for b in 0...2 {
                    for c in 0...2 {
                        sum += t1[a, b, c] * t2[d, c, b]
                    }
                }
                expectedProduct[product.flatIndex([a, d])] = sum
            }
        }
        product = t1*t2
        XCTAssertEqual(product.values, expectedProduct, "product 3x3x3 * 3x3x3")

        t1 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [3, 3, 3], values: Array(0..<27).map({return Float($0)}))
        t1.indices = [.a, .b, .c]
        t2.indices = [.c, .d, .b]
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for a in 0...2 {
            for d in 0...2 {
                var sum: Float = 0
                for b in 0...2 {
                    for c in 0...2 {
                        sum += t1[a, b, c] * t2[c, d, b]
                    }
                }
                expectedProduct[product.flatIndex([a, d])] = sum
            }
        }
        product = t1*t2
        XCTAssertEqual(product.values, expectedProduct, "product 3x3x3 * 3x3x3")


        t1 = Tensor<Float>(modeSizes: [3, 3, 3, 3], values: Array(0..<81).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [3, 3, 3, 3], values: Array(0..<81).map({return Float($0)}))
        t1.indices = [.a, .b, .c, .d]
        t2.indices = [.c, .d, .a, .e]
        product = t1*t2
        //        t1 = Tensor<Float>(modeSizes: [3, 3, 3, 3], values: Array(0..<81).map({return Float($0)}))
        //        t2 = Tensor<Float>(modeSizes: [3, 3, 3, 3], values: Array(0..<81).map({return Float($0)}))
        //        t1.indexAs([.a, .b, .c, .d])
        //        t2.indexAs([.c, .d, .a, .e])
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for b in 0...2 {
            for e in 0...2 {
                var sum: Float = 0
                for a in 0...2 {
                    for c in 0...2 {
                        for d in 0...2 {
                            sum += t1[a, b, c, d] * t2[c, d, a, e]
                        }
                    }
                }
                expectedProduct[product.flatIndex([b, e])] = sum
            }
        }

        XCTAssertEqual(product.values, expectedProduct, "product 3x3x3x3 * 3x3x3x3")

        t1 = Tensor<Float>(modeSizes: [3, 3, 3, 3], values: Array(0..<81).map({return Float($0)}))
        t2 = Tensor<Float>(modeSizes: [3, 3], values: Array(0..<9).map({return Float($0)}))
        t1.indices = [.a, .b, .c, .d]
        t2.indices = [.b, .e]
        product = t1*t2
        expectedProduct = [Float](repeating: 0, count: product.elementCount)
        for a in 0...2 {
            for c in 0...2 {
                for d in 0...2 {
                    for e in 0...2 {
                        var sum: Float = 0
                        for b in 0...2 {
                            sum += t1[a, b, c, d] * t2[b, e]
                        }
                        expectedProduct[product.flatIndex([a, c, d, e])] = sum
                    }
                }
            }
        }

        XCTAssertEqual(product.values, expectedProduct, "product 3x3x3x3 * 3x3")
    }

//    func testTensorNormalization() {
//        let originalValues = Array(0..<60).map({return Float($0)})
//        var tensor = Tensor<Float>(modeSizes: [3, 4, 5], values: originalValues)
//        tensor.indices = [.a, .b, .c]
////        let normalized1 = normalize(tensor, overModes: [1])
////
////        tensor = normalized1.normalizedTensor °* normalized1.standardDeviation
////        tensor = tensor + normalized1.mean
////        XCTAssert(squaredDistance(tensor.values, b: originalValues) < 50*0.001, "normalization over mode 1")
//
//        tensor = Tensor<Float>(modeSizes: [3, 4, 5], values: originalValues)
//        tensor.indices = [.a, .b, .c]
//        let normalized = normalize(tensor, overModes: [0, 1, 2])
//
//        tensor = normalized.normalizedTensor °* normalized.standardDeviation
//        tensor = tensor + normalized.mean
//        XCTAssert(squaredDistance(tensor.values, b: originalValues) < 50*0.001, "normalization over modes 0, 1 and 2")
//        print("normalized: \(tensor.values)")
//
////        let normalizedConcurrent = normalizeConcurrent(tensor, overModes: [0, 1, 2])
////
////        tensor = normalizedConcurrent.normalizedTensor °* normalizedConcurrent.standardDeviation
////        tensor = tensor + normalized.mean
////        XCTAssert(squaredDistance(tensor.values, b: originalValues) < 50*0.001, "concurrent normalization over modes 0, 1 and 2")
////        print("normalizedConcurrent: \(tensor.values)")
//    }

    func testTensorModeSizesChange() {
        let t1 = ones(5, 9)
        let r1 = changeModeSizes(t1, targetSizes: [7, 10])
        print("r1: \(r1.values)")
        let r2 = changeModeSizes(t1, targetSizes: [4, 4])
        print("r2: \(r2.values)")
        let r3 = changeModeSizes(t1, targetSizes: [6, 2])
        print("r3: \(r3.values)")

    }

    func testTensorSum() {
        let sum1 = sum(tensor1, overModes: [0, 1, 2])
        XCTAssertEqual(sum1.values, [276.0], "sum tensor1 over all modes")

        let sum2 = sum(tensor1, overModes: [0, 2])
        XCTAssertEqual(sum2.values, [60.0, 92.0, 124.0], "sum tensor1 over modes 0 and 2")

        let sum3 = sum(tensor1, overModes: [1])
        XCTAssertEqual(sum3.values, [12.0, 15.0, 18.0, 21.0, 48.0, 51.0, 54.0, 57.0], "sum tensor1 over mode 1")
    }

    func testTensorNormalization() {
        let normalization1 = normalize(tensor1, overModes: [0, 1, 2])
        let sum1 = sum(normalization1.normalizedTensor, overModes: [0, 1, 2])
        XCTAssert(abs(sum1.values[0]) < 0.001, "normalize tensor1 over all modes")
    }

    func testTensorInverse() {
    }

    func testTensorOrdering() {
        let reorderedMode0 = changeOrderOfModeIn(tensor1, mode: 0, newOrder: [1, 0])
        XCTAssertEqual(reorderedMode0.values[2], 14.0, "reordered mode 0")
        print("reordered values in mode 0: \(reorderedMode0.values)")

        let reorderedMode1 = changeOrderOfModeIn(tensor1, mode: 1, newOrder: [2, 0, 1])
        XCTAssertEqual(reorderedMode1.values[2], 10.0, "reordered mode 1")
        print("reordered values in mode 1: \(reorderedMode1.values)")

        let reorderedMode2 = changeOrderOfModeIn(tensor1, mode: 2, newOrder: [2, 0, 1, 3])
        XCTAssertEqual(reorderedMode2.values[2], 1.0, "reordered mode 2")
        print("reordered values in mode 2: \(reorderedMode2.values)")
    }

}
