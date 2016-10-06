//
//  Utilities.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

public protocol Number: Comparable {
    init(_ value: Int)
    init(_ value: Float)
    init(_ value: Double)
    
    static func + (lhs: Self, rhs: Self) -> Self
    static func - (lhs: Self, rhs: Self) -> Self
    static func * (lhs: Self, rhs: Self) -> Self
    static func / (lhs: Self, rhs: Self) -> Self
}

extension Double : Number {}
extension Float : Number {}
extension Int : Number {}
extension Int64 : Number {}

public protocol IntegerType {
    var value: Int {get}
}
extension Int: IntegerType {
    public var value: Int {
        get{
            return self
        }
    }
}

// credit for the UnsafeBuffer protocol to Chris Liscio https://github.com/liscio
/// A CollectionType that can perfom functions on its Unsafe(Mutable)BufferPointer
public protocol UnsafeBuffer: RandomAccessCollection {
    typealias IndexDistance = Int
    
    /// Perform the a function with a UnsafeBufferPointer to this collection
    func performWithUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Self.Iterator.Element>) throws -> R) -> R?
}

public protocol UnsafeMutableBuffer: UnsafeBuffer, RandomAccessCollection {
    typealias IndexDistance = Int
    
    /// Perform the a function with a UnsafeMutableBufferPointer to this collection
    mutating func performWithUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Self.Iterator.Element>) throws -> R) -> R?
}


extension Array : UnsafeMutableBuffer {
    public func performWithUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Iterator.Element>) throws -> R) -> R? {
        let value = try? withUnsafeBufferPointer(body)
        return value
    }
    
    mutating public func performWithUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) -> R? {

        let value = try? withUnsafeMutableBufferPointer(body)
        return value
    }
}
extension ArraySlice : UnsafeMutableBuffer {
    public func performWithUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) -> R? {
        let value = try? withUnsafeBufferPointer(body)
        return value
    }
    
    mutating public func performWithUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Element>) throws -> R) -> R? {
        let value = try? withUnsafeMutableBufferPointer(body)
        return value
    }
}
extension UnsafeBufferPointer: UnsafeBuffer {
    public func performWithUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) -> R? {
        let value = try? body(self)
        return value
    }
}
extension UnsafeMutableBufferPointer: UnsafeMutableBuffer {
    public func performWithUnsafeBufferPointer<R>(_ body: (UnsafeBufferPointer<Element>) throws -> R) -> R? {
        let thisPointer = UnsafeBufferPointer(start: baseAddress, count: count)
        let value = try? body(thisPointer)
        return value
    }
    public func performWithUnsafeMutableBufferPointer<R>(_ body: (inout UnsafeMutableBufferPointer<Iterator.Element>) throws -> R) -> R? {
        var thisPointer = self
        let value = try? body(&thisPointer)
        return value
    }
}

extension Collection {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Iterator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollection where IndexDistance == Int, Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}


/// combine two arrays (preferably of same size, else smaller size is used) with the combineFunction
func arrayCombine<A, B, R> (_ arrayA: [A], arrayB: [B], combineFunction: (_ a: A, _ b: B) -> R) -> [R] {
    let length = min(arrayA.count, arrayB.count)
    var result = [R]()
    for i in 0..<length {
        result.append(combineFunction(arrayA[i], arrayB[i]))
    }
    return result
}
public extension Array {
    /// Combine this array with another array and a given combineFunction
    func combineWith<E, R>(_ array: [E], combineFunction: (_ t: Element, _ e: E) -> R) -> [R] {
        return arrayCombine(self, arrayB: array, combineFunction: combineFunction)
    }
    
    /// Safe access to array elements
    subscript (safe index: Int) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

public extension UnsafeBuffer where Iterator.Element: Equatable, Index == Int {
    ///remove the given values from this array
    func removeValues(_ values: [Iterator.Element]) -> [Iterator.Element] {
        var returnArray = Array(self)
        for value in values {
            if let index = returnArray.index(of: value) {
                returnArray.remove(at: index)
                
            }
        }
        return returnArray
    }
}

//public func squaredDistance(a: [Float], b: [Float]) -> Float {
//    return a.combineWith(b, combineFunction: {($0-$1)*($0-$1)}).reduce(0, combine: {$0+$1})
//}

public func meanSquaredError(target: [Float], result: [Float]) -> Float {
    assert(target.count == result.count)
    let factor = 1 / Float(target.count)
    let errors = zip(target, result).map({pow($0.0 - $0.1, 2)})
    return errors.reduce(0, {$0 + $1}) * factor
}

public func memoryAddress(_ o: UnsafeRawPointer) -> UnsafeRawPointer {
    return UnsafeRawPointer(bitPattern: unsafeBitCast(o, to: Int.self))!
}

public func printArrayAddress<T>(_ array: inout [T]) {
    print("array memory address: \(memoryAddress(&array))")
}


public extension String {
    
    /// `Int8` value of the first character
    var charValue: Int8 {
        get {
            return (self.cString(using: String.Encoding.utf8)?[0])!
        }
    }
    
    subscript (i: Int) -> Character {
        return self[self.characters.index(self.startIndex, offsetBy: i)]
    }
    
//    subscript (r: CountableRange<Int>) -> String {
//        let start = characters.index(startIndex, offsetBy: r.lowerBound)
//        let end = <#T##String.CharacterView corresponding to `start`##String.CharacterView#>.index(start, offsetBy: r.upperBound - r.lowerBound)
//        return self[start..<end]
//    }
}


public extension CountableRange {
    init(start: Element, distance: Element.Stride) {
        
        let end = start.advanced(by: distance)
        self.init(start..<end)
    }
}
