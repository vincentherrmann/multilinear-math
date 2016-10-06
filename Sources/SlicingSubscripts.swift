//
//  SlicingSubscripts.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation
import Accelerate

/*  The problem for the DataSliceSubscript is to get an heterogenous array of Collections with Int Elements. This is a challenge, because it is currently not possible to extend a protocol to a generically constrained type. The solution in this case is to make all needed collections conform to a protocol with dynamically dispatched function that get overwritten for the constrained collection types.
 */


/// This item can be used as part of a subscript for MultidimensionalData, for creating a slice of the data. It represents the indices of one mode of the data object.
public protocol DataSliceSubscript {
    ///The number of indices of this mode of the slice
    var sliceSize: Int {get}
    ///The indicices in the original data in this mode that will be included in the slice
    func sliceIndices() -> [Int] //for some reason, this does not work as a computed property (?)
}
extension DataSliceSubscript {
    public func sliceIndices() -> [Int] {
        if let array = self as? [Int] {
            return array.map({$0.value})
        } else if let range = self as? CountableRange<Int> {
            return Array(range).map({$0.value})
        } else {
            let emptyArray = [Int]()
            return emptyArray
        }
    }
}

public struct AllIndices: DataSliceSubscript {
    public var sliceSize: Int {
        get {
            //print("slice size for AllIndices not defined")
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

extension CountableRange: DataSliceSubscript {
    public var sliceSize: Int {
        get {
            return Array(self).count
        }
    }
}

extension CountableClosedRange: DataSliceSubscript {
    public var sliceSize: Int {
        get {
            return Array(self).count
        }
    }
}

/// Copy values from one multidimensional data object to another.
/// - Parameter from: The source multidimensional data object
/// - Parameter to: The target object
/// - Parameter targetPointer: A pointer to the value array of the target object
/// - Parameter subscripts: An array of data slice subscripts defining the indices of the slice
/// - Parameter copyFromSlice: If true, the subscripts refer to the target object, the source object is the slice, if wrong vice versa
public func copySliceFrom<T: MultidimensionalData>(_ from: T,
                          to target: T,
                             targetPointer: UnsafeMutableBufferPointer<T.Element>,
                             subscripts: [DataSliceSubscript],
                             copyFromSlice: Bool) {
    
    //cast all subscripts as Int arrays
    var arraySubscripts: [DataSliceSubscript] = []
    for thisSubscript in subscripts {
        if let array = thisSubscript as? [Int] {
            arraySubscripts.append(array)
        } else if let range = thisSubscript as? CountableRange<Int> {
            arraySubscripts.append(range.sliceIndices())
        }
    }
    
    //get flat indices
    let modeSizes = (copyFromSlice ? target : from).modeSizes
    let indicesToCopy = copyIndices(arraySubscripts, modeSizes: modeSizes)
    
    //copy
    if(copyFromSlice) { //all values from the source to the defined indices in the target
        for i in 0..<indicesToCopy.count {
            targetPointer[indicesToCopy[i]] = from.values[i]
        }
    } else { //the defined values in the source to the target
        for i in 0..<indicesToCopy.count {
            targetPointer[i] = from.values[indicesToCopy[i]]
        }
    }
}

/// Calculate the flat indices of a slice defined by the given subscripts in a tensor with the given mode sizes
private func copyIndices(_ subscripts: [DataSliceSubscript], modeSizes: [Int]) -> [Int] {
    if(subscripts.count == 0) {
        return [0]
    }
    
    ///cycle lenghts of the modes in the value array of the embedding data object
    var cycleLengths: [Int] = [Int](repeating: 0, count: subscripts.count)
    ///cycle lengths of the modes in the value array of the slice
    var sliceCycleLengths: [Int] = cycleLengths
    var currentCycleLength: Int = 1
    var currentSliceCycleLength: Int = 1
    for i in cycleLengths.indices.reversed() {
        currentCycleLength = currentCycleLength * modeSizes[i]
        currentSliceCycleLength = currentSliceCycleLength * subscripts[i].sliceSize
        cycleLengths[i] = currentCycleLength
        sliceCycleLengths[i] = currentSliceCycleLength
    }
    
    let indices: [Int] = (subscripts.last! as! Array<Int>).sliceIndices()
    
    func indexRecurse(_ indices: [Int], mode: Int) -> [Int] {
        var newIndices: [Int] = []
        newIndices.reserveCapacity(sliceCycleLengths[mode])

        let offset = cycleLengths[mode+1]
        let sliceIndices = (subscripts[mode] as! Array<Int>).sliceIndices()
        for i in 0..<subscripts[mode].sliceSize {
            newIndices.append(contentsOf: indices.map({$0 + sliceIndices[i]*offset}))
        }
        
        if(mode > 0) {
            return indexRecurse(newIndices, mode: mode-1)
        } else {
            return newIndices
        }
    }
    
    let copyIndices: [Int]
    if(subscripts.count > 1) {
        copyIndices = indexRecurse(indices, mode: subscripts.count - 2)
    } else {
        copyIndices = indices
    }
    
    return copyIndices
}


internal func recurseCopy<T: MultidimensionalData>(target: T,
                          targetPointer: UnsafeMutableBufferPointer<T.Element>,
                          from: T,
                          subscripts: [DataSliceSubscript],
                          subscriptMode: Int,
                          subscriptIndex: [Int],
                          sliceMode: Int,
                          sliceIndex: [Int],
                          copyFromSlice: Bool) {
    
    //print("write to address: \(targetPointer), in thread: \(NSThread.currentThread())")
    
    if(subscriptMode < subscripts.count - 1) {
        var indices: [Int] = []
        if let arraySubscript = subscripts[subscriptMode] as? Array<Int> {
            indices = arraySubscript.sliceIndices()
        } else if let rangeSubscript = subscripts[subscriptMode] as? CountableRange<Int> {
            indices = rangeSubscript.sliceIndices()
        }
        
        if(indices.count == 1) { //only one index, the slice will not have this mode
            for i in indices.indices {
                var newSubscriptIndex = subscriptIndex
                newSubscriptIndex[subscriptMode] = indices[i]
                
                recurseCopy(target: target,
                            targetPointer: targetPointer,
                            from: from,
                            subscripts: subscripts,
                            subscriptMode: subscriptMode+1,
                            subscriptIndex: newSubscriptIndex,
                            sliceMode: sliceMode,
                            sliceIndex: sliceIndex,
                            copyFromSlice: copyFromSlice)
            }
        } else {
            for i in indices.indices {
                var newSubscriptIndex = subscriptIndex
                newSubscriptIndex[subscriptMode] = indices[i]
                var newSliceIndex = sliceIndex
                newSliceIndex[sliceMode] = i
                
                recurseCopy(target: target,
                            targetPointer: targetPointer,
                            from: from,
                            subscripts: subscripts,
                            subscriptMode: subscriptMode+1,
                            subscriptIndex: newSubscriptIndex,
                            sliceMode: sliceMode+1,
                            sliceIndex: newSliceIndex,
                            copyFromSlice: copyFromSlice)
            }
        }
    } else if(subscripts.count == 0) {
        if(copyFromSlice) {
            let fromIndex = from.flatIndex(sliceIndex)
            targetPointer[0] = from.values[fromIndex]
        } else {
            let targetIndex = target.flatIndex(sliceIndex)
            targetPointer[targetIndex] = from.values[0]
        }
    } else {
        if let arraySubscript = subscripts[subscriptMode] as? Array<Int> {
            var currentSubscriptIndex = subscriptIndex
            var currentSliceIndex = sliceIndex
            
            if(copyFromSlice) {
                for i in arraySubscript.indices {
                    currentSubscriptIndex[subscriptMode] = arraySubscript[i]
                    currentSliceIndex[sliceMode] = i
                    let targetIndex = target.flatIndex(currentSubscriptIndex)
                    let fromIndex = from.flatIndex(currentSliceIndex)
                    
                    targetPointer[targetIndex] = from.values[fromIndex]
                }
            } else { //copy to slice
                for i in arraySubscript.indices {
                    currentSubscriptIndex[subscriptMode] = arraySubscript[i]
                    currentSliceIndex[sliceMode] = i
                    let targetIndex = target.flatIndex(currentSliceIndex)
                    let fromIndex = from.flatIndex(currentSubscriptIndex)
                    
                    targetPointer[targetIndex] = from.values[fromIndex]
                }
            }
            
        } else if let rangeSubscript = subscripts[subscriptMode] as? CountableRange<Int> {
            var currentSubscriptIndex = subscriptIndex
            currentSubscriptIndex[subscriptMode] = rangeSubscript.startIndex
            
            let length = Int(rangeSubscript.count)
            
            if(copyFromSlice) {
                let flatSubscriptIndex = target.flatIndex(currentSubscriptIndex)
                let flatSliceIndex = from.flatIndex(sliceIndex)
                
                from.values.performWithUnsafeBufferPointer({ (fromBuffer) -> () in
                    let targetAddress = targetPointer.baseAddress!.advanced(by: flatSubscriptIndex)
                    var fromAddress = fromBuffer.index(after: flatSliceIndex)
                    //let fromAdress = fromBuffer.baseAddress.advancedBy(flatSliceIndex)
                    memcpy(targetAddress, &fromAddress, MemoryLayout<T.Element>.size * length) //not sure &fromAddress works
                })
            } else { //copy to slice
                let flatSliceIndex = target.flatIndex(sliceIndex)
                let flatSubscriptIndex = from.flatIndex(currentSubscriptIndex)
                
                from.values.performWithUnsafeBufferPointer({ (fromBuffer) -> () in
                    let targetAddress = targetPointer.baseAddress!.advanced(by: flatSliceIndex)
                    var fromAddress = fromBuffer.index(after: flatSubscriptIndex)
                    //let fromAdress = fromBuffer.baseAddress.advancedBy(flatSubscriptIndex)
                    memcpy(targetAddress, &fromAddress, MemoryLayout<T.Element>.size * length) //not sure &fromAddress works
                })
            }
        }
    }
}

public func getSlice<T: MultidimensionalData>(from: T, modeSubscripts: [DataSliceSubscript]) -> T {
    let subscripts = from.completeDataSliceSubscripts(modeSubscripts)
    
    let modesWithSubscripts = zip(from.modeArray, subscripts).filter({$0.1.sliceSize > 1})
    let onlyModes = modesWithSubscripts.map({$0.0})
    let newSizes = modesWithSubscripts.map({$0.1.sliceSize})
    
    var newData = T(withPropertiesOf: from, onlyModes: onlyModes, newModeSizes: newSizes, repeatedValue: from.values[0], values: nil)
    //var newData = T(modeSizes: newSizes, repeatedValue: from.values[0])
    
    let subscriptIndex = [Int](repeating: 0, count: from.modeCount)
    let sliceIndex = [Int](repeating: 0, count: newData.modeCount)
    
    newData.values.performWithUnsafeMutableBufferPointer { (slice) -> () in
//        newData.printMemoryAdresses(printTitle: "--get slice--", printThread: true)
//        recurseCopy(target: newData, targetPointer: slice, from: from, subscripts: subscripts, subscriptMode: 0, subscriptIndex: subscriptIndex, sliceMode: 0, sliceIndex: sliceIndex, copyFromSlice: false)
        copySliceFrom(from, to: newData, targetPointer: slice, subscripts: subscripts, copyFromSlice: false)
    }
    
    return newData
}
