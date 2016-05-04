//
//  DataSetLoading.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 30.04.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public func loadMNISTImageFile(path: String) -> Tensor<Float> {
    guard let data = NSData(contentsOfFile: path) else {
        print("could not load file \(path)")
        return Tensor<Float>(scalar: 0)
    }
    
    var magicNumber: UInt32 = 333
    data.getBytes(&magicNumber, range: NSRange(location: 0, length: 4))
    magicNumber = CFSwapInt32BigToHost(magicNumber)
    
    var imageCount: UInt32 = 10000
    data.getBytes(&imageCount, range: NSRange(location: 4, length: 4))
    imageCount = CFSwapInt32BigToHost(imageCount)
    
    var rows: UInt32 = 28
    data.getBytes(&rows, range: NSRange(location: 8, length: 4))
    rows = CFSwapInt32BigToHost(rows)
    
    var columns: UInt32 = 28
    data.getBytes(&columns, range: NSRange(location: 12, length: 4))
    columns = CFSwapInt32BigToHost(columns)
    
    print("load \(imageCount) MNIST images of size \(rows) x \(columns)")
    
    let elementCount = Int(imageCount * rows * columns)
    var values = [Float](count: elementCount, repeatedValue: 0)
    
    let startIndex: Int = 16
    
    for i in 0..<elementCount {
        let thisPosition = i + startIndex
        var thisValue: UInt8 = 0
        data.getBytes(&thisValue, range: NSRange(location: thisPosition, length: 1))
        values[i] = Float(thisValue) / 255.0
    }
    
    return Tensor<Float>(modeSizes: [Int(imageCount), Int(rows), Int(columns)], values: values)
}

public func loadMNISTLabelFile(path: String) -> [UInt8] {
    guard let data = NSData(contentsOfFile: path) else {
        print("could not load file \(path)")
        return []
    }
    
    var magicNumber: UInt32 = 333
    data.getBytes(&magicNumber, range: NSRange(location: 0, length: 4))
    magicNumber = CFSwapInt32BigToHost(magicNumber)
    
    var itemCount: UInt32 = 10000
    data.getBytes(&itemCount, range: NSRange(location: 4, length: 4))
    itemCount = CFSwapInt32BigToHost(itemCount)
    
    print("load \(itemCount) labels")
    
    let startIndex: Int = 8
    let elementCount = Int(itemCount)
    var values = [UInt8](count: elementCount, repeatedValue: 0)
    
    for i in 0..<elementCount {
        let thisPosition = i + startIndex
        var thisValue: UInt8 = 0
        data.getBytes(&thisValue, range: NSRange(location: thisPosition, length: 1))
        values[i] = thisValue
    }
    
    return values
}
