//
//  SlicingSubscripts.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

/*  The problem for the DataSliceSubscript is to get an heterogenous array of Collections with Int Elements. This is a challenge, because it is currently not possible to extend a protocol to a generically constrained type. The solution in this case is to make all needed collections conform to a protocol with dynamically dispatched function that get overwritten for the constrained collection types.
 */


/// This item can be used as part of a subscript for MultidimensionalData, for creating a slice of the data. It represents the indices of one mode of the data object.
public protocol DataSliceSubscript {
    ///The number of indices of this mode of the slice
    var sliceSize: Int {get}
    ///The indicices in the original data in this mode that will be included in the slice
    func sliceIndices() -> [Int] //for some reason, this does not work as a computed property (?)
    
    ///Copy the sliceIndices in this mode to the slice
    func copyValuesFrom<T: MultidimensionalData>(data: T, inout to slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int)
    func copyValuesTo<T: MultidimensionalData>(inout data: T, from slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int)
}
extension DataSliceSubscript {
    //dummy, will be overwritten for the constrained types
    public func sliceIndices() -> [Int] {
        let emptyArray = [Int]()
        return emptyArray
    }
    
    /// Recursion for every index of every mode, except the last (where the copyValuesFrom functions is called), of the data slice. Modes with only one index get eliminated.
    internal func recurseCopyFrom<T: MultidimensionalData>(data: T, inout to slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int, sliceSubscripts: [DataSliceSubscript]) {
        
        var indices = [Int]()
        if let arraySelf = self as? Array<Int> {
            indices = arraySelf.sliceIndices()
        } else if let rangeSelf = self as? Range<Int> {
            indices = rangeSelf.sliceIndices()
        }
        
        if(currentDataMode < data.modeCount-2) { //multiple modes remaining -> recursion
            if(indices.count == 1) { //only one index, the slice will not have this mode
                currentDataIndex[currentDataMode] = indices.first!
                sliceSubscripts[currentDataMode+1].recurseCopyFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode, sliceSubscripts: sliceSubscripts)
            } else { //recursion for every index in this mode
                for i in indices.indices {
                    currentDataIndex[currentDataMode] = indices[i]
                    currentSliceIndex[currentSliceMode] = i
                    sliceSubscripts[currentDataMode+1].recurseCopyFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode+1, sliceSubscripts: sliceSubscripts)
                }
            }
        } else if(currentDataMode < data.modeCount-1) { //only last mode remaining -> copy values to slice
            if(indices.count == 1) {
                currentDataIndex[currentDataMode] = indices.first!
                
                if let nextArray = sliceSubscripts[currentDataMode+1] as? Array<Int> {
                    nextArray.copyValuesFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode)
                } else if let nextRange = sliceSubscripts[currentDataMode+1] as? Range<Int> {
                    nextRange.copyValuesFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode)
                }
            } else {
                for i in indices.indices {
                    currentDataIndex[currentDataMode] = indices[i]
                    currentSliceIndex[currentSliceMode] = i
                    
                    if let nextArray = sliceSubscripts[currentDataMode+1] as? Array<Int> {
                        nextArray.copyValuesFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode+1)
                    } else if let nextRange = sliceSubscripts[currentDataMode+1] as? Range<Int> {
                        nextRange.copyValuesFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode+1)
                    }
                }
            }
        } else { //already last mode (only special cases) -> copy values of this mode
            
            if let nextArray = sliceSubscripts[currentDataMode+1] as? Array<Int> {
                nextArray.copyValuesFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode, currentSliceMode: currentSliceMode)
            } else if let nextRange = sliceSubscripts[currentDataMode+1] as? Range<Int> {
                nextRange.copyValuesFrom(data, to: &slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode, currentSliceMode: currentSliceMode)
            }
        }
    }
    
    internal func recurseCopyTo<T: MultidimensionalData>(inout data: T, from slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int, sliceSubscripts: [DataSliceSubscript]) {
        
        var indices = [Int]()
        if let arraySelf = self as? Array<Int> {
            indices = arraySelf.sliceIndices()
        } else if let rangeSelf = self as? Range<Int> {
            indices = rangeSelf.sliceIndices()
        }
        
        if(currentDataMode < data.modeCount-2) { //multiple modes remaining -> recursion
            if(indices.count == 1) { //only one index, the slice will not have this mode
                currentDataIndex[currentDataMode] = indices.first!
                sliceSubscripts[currentDataMode+1].recurseCopyTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode, sliceSubscripts: sliceSubscripts)
            } else { //recursion for every index in this mode
                for i in indices.indices {
                    currentDataIndex[currentDataMode] = indices[i]
                    currentSliceIndex[currentSliceMode] = i
                    sliceSubscripts[currentDataMode+1].recurseCopyTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode+1, sliceSubscripts: sliceSubscripts)
                }
            }
        } else if(currentDataMode < data.modeCount-1) { //only last mode remaining -> copy values to slice
            if(indices.count == 1) {
                currentDataIndex[currentDataMode] = indices.first!
                
                if let nextArray = sliceSubscripts[currentDataMode+1] as? Array<Int> {
                    nextArray.copyValuesTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode)
                } else if let nextRange = sliceSubscripts[currentDataMode+1] as? Range<Int> {
                    nextRange.copyValuesTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode)
                }
            } else {
                for i in indices.indices {
                    currentDataIndex[currentDataMode] = indices[i]
                    currentSliceIndex[currentSliceMode] = i
                    
                    if let nextArray = sliceSubscripts[currentDataMode+1] as? Array<Int> {
                        nextArray.copyValuesTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode+1)
                    } else if let nextRange = sliceSubscripts[currentDataMode+1] as? Range<Int> {
                        nextRange.copyValuesTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode+1, currentSliceMode: currentSliceMode+1)
                    }
                }
            }
        } else { //already last mode (only special cases) -> copy values of this mode
            
            if let nextArray = sliceSubscripts[currentDataMode+1] as? Array<Int> {
                nextArray.copyValuesTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode, currentSliceMode: currentSliceMode)
            } else if let nextRange = sliceSubscripts[currentDataMode+1] as? Range<Int> {
                nextRange.copyValuesTo(&data, from: slice, currentDataIndex: &currentDataIndex, currentSliceIndex: &currentSliceIndex, currentDataMode: currentDataMode, currentSliceMode: currentSliceMode)
            }
        }
    }
    
    ///only used if there are no constrained types, copy the whole mode
    public func copyValuesFrom<T: MultidimensionalData>(data: T, inout to slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int) {
        
        let flatDataIndex = data.flatIndex(currentDataIndex)
        let flatSliceIndex = slice.flatIndex(currentSliceIndex)
        let modeSize = data.modeSizes[currentDataMode]
        
        slice.values[Range(start: flatSliceIndex, distance: modeSize)] = data.values[Range(start: flatDataIndex, distance: modeSize)]
    }
    ///only used if there are no constrained types, copy the whole mode
    public func copyValuesTo<T: MultidimensionalData>(inout data: T, from slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int) {
        
        let flatDataIndex = data.flatIndex(currentDataIndex)
        let flatSliceIndex = slice.flatIndex(currentSliceIndex)
        let modeSize = data.modeSizes[currentDataMode]
        
        data.values[Range(start: flatDataIndex, distance: modeSize)] = slice.values[Range(start: flatSliceIndex, distance: modeSize)]
    }
}

public struct AllIndices: DataSliceSubscript {
    public var sliceSize: Int {
        get {
            print("slice size for AllIndices not defined")
            return 0
        }
    }
}
public let all = AllIndices()

extension Array: DataSliceSubscript {
    public var sliceSize: Int {
        get {
            return count
        }
    }
}
public extension Array where Element: IntegerType {
    func sliceIndices() -> [Int] {
        return self.map({$0.value})
    }
    
    func copyValuesFrom<T: MultidimensionalData>(data: T, inout to slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int) {
        
        for i in indices {
            currentDataIndex[currentDataMode] = self[i].value
            currentSliceIndex[currentSliceMode] = i
            slice.values[slice.flatIndex(currentSliceIndex)] = data.values[data.flatIndex(currentDataIndex)]
        }
    }
    
    func copyValuesTo<T: MultidimensionalData>(inout data: T, from slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int) {
        
        for i in indices {
            currentDataIndex[currentDataMode] = self[i].value
            currentSliceIndex[currentSliceMode] = i
            data.values[data.flatIndex(currentDataIndex)] = slice.values[slice.flatIndex(currentSliceIndex)]
        }
    }
}

extension Range: DataSliceSubscript {
    public var sliceSize: Int {
        get {
            return Array(self).count
        }
    }
}
public extension Range where Element: IntegerType {
    func sliceIndices() -> [Int] {
        return Array(self).map({$0.value})
    }
    
    func copyValuesFrom<T: MultidimensionalData>(data: T, inout to slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int) {
        
        currentDataIndex[currentDataMode] = startIndex.value
        
        let flatDataIndex = data.flatIndex(currentDataIndex)
        let flatSliceIndex = slice.flatIndex(currentSliceIndex)
        
        slice.values[flatSliceIndex..<flatSliceIndex + sliceSize] = data.values[flatDataIndex..<flatDataIndex + sliceSize]
    }
    
    func copyValuesTo<T: MultidimensionalData>(inout data: T, from slice: T, inout currentDataIndex: [Int], inout currentSliceIndex: [Int], currentDataMode: Int, currentSliceMode: Int) {
        
        currentDataIndex[currentDataMode] = startIndex.value
        
        let flatDataIndex = data.flatIndex(currentDataIndex)
        let flatSliceIndex = slice.flatIndex(currentSliceIndex)
        
        data.values[flatDataIndex..<flatDataIndex + sliceSize] = slice.values[flatSliceIndex..<flatSliceIndex + sliceSize]
    }
}