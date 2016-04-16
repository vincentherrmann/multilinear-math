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

    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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
        expectedProduct = [Float](count: product.elementCount, repeatedValue: 0)
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

    func testTensorNormalization() {
        let originalValues = Array(0..<60).map({return Float($0)})
        var tensor = Tensor<Float>(modeSizes: [3, 4, 5], values: originalValues)
        tensor.indices = [.a, .b, .c]
//        let normalized1 = normalize(tensor, overModes: [1])
//
//        tensor = normalized1.normalizedTensor °* normalized1.standardDeviation
//        tensor = tensor + normalized1.mean
//        XCTAssert(squaredDistance(tensor.values, b: originalValues) < 50*0.001, "normalization over mode 1")
        
        tensor = Tensor<Float>(modeSizes: [3, 4, 5], values: originalValues)
        tensor.indices = [.a, .b, .c]
        var normalized2 = normalize(tensor, overModes: [0, 1, 2])
        
        tensor = normalized2.normalizedTensor °* normalized2.standardDeviation
        tensor = tensor + normalized2.mean
        XCTAssert(squaredDistance(tensor.values, b: originalValues) < 50*0.001, "normalization over modes 0, 1 and 2")
        print("\(tensor.values)")
    }

}
