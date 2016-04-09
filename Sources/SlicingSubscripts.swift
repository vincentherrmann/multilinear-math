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
    //dummy, will be overwritten for the constrained types
    public func sliceIndices() -> [Int] {
        let emptyArray = [Int]()
        return emptyArray
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
}

internal func recurseCopy<T: MultidimensionalData>(target target: T,
                          targetPointer: UnsafeMutableBufferPointer<T.Element>,
                          from: T,
                          subscripts: [DataSliceSubscript],
                          subscriptMode: Int,
                          subscriptIndex: [Int],
                          sliceMode: Int,
                          sliceIndex: [Int],
                          copyFromSlice: Bool) {
    
    if(subscriptMode < subscripts.count - 1) {
        var indices: [Int] = []
        if let arraySubscript = subscripts[subscriptMode] as? Array<Int> {
            indices = arraySubscript.sliceIndices()
        } else if let rangeSubscript = subscripts[subscriptMode] as? Range<Int> {
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
            
        } else if let rangeSubscript = subscripts[subscriptMode] as? Range<Int> {
            var currentSubscriptIndex = subscriptIndex
            currentSubscriptIndex[subscriptMode] = rangeSubscript.startIndex
            
            let length = Int(rangeSubscript.count)
            
            if(copyFromSlice) {
                let flatSubscriptIndex = target.flatIndex(currentSubscriptIndex)
                let flatSliceIndex = from.flatIndex(sliceIndex)
                
                from.values.withUnsafeBufferPointer({ (fromBuffer) -> () in
                    //let oldTargetArray = Array(targetPointer)
                    //let fromArray = Array(fromBuffer)
                    let targetAdress = targetPointer.baseAddress.advancedBy(flatSubscriptIndex)
                    let fromAdress = fromBuffer.baseAddress.advancedBy(flatSliceIndex)
                    memcpy(targetAdress, fromAdress, sizeof(T.Element.self) * length)
                    //let newTargetArray = Array(targetPointer)
                })
            } else { //copy to slice
                let flatSliceIndex = target.flatIndex(sliceIndex)
                let flatSubscriptIndex = from.flatIndex(currentSubscriptIndex)
                
                from.values.withUnsafeBufferPointer({ (fromBuffer) -> () in
                    let targetAdress = targetPointer.baseAddress.advancedBy(flatSliceIndex)
                    let fromAdress = fromBuffer.baseAddress.advancedBy(flatSubscriptIndex)
                    memcpy(targetAdress, fromAdress, sizeof(T.Element.self) * length)
                })
                
            }
        }
    }
}

public func getSlice<T: MultidimensionalData>(from from: T, modeSubscripts: [DataSliceSubscript]) -> T {
    let subscripts = from.completeDataSliceSubscripts(modeSubscripts)
    
    let newSizes = subscripts.map({$0.sliceSize}).filter({$0 > 1})
    var newData = T(modeSizes: newSizes, repeatedValue: from.values[0])
    
    let subscriptIndex = [Int](count: from.modeCount, repeatedValue: 0)
    let sliceIndex = [Int](count: newData.modeCount, repeatedValue: 0)
    
    newData.values.withUnsafeMutableBufferPointer { (slice) -> () in
        recurseCopy(target: newData, targetPointer: slice, from: from, subscripts: subscripts, subscriptMode: 0, subscriptIndex: subscriptIndex, sliceMode: 0, sliceIndex: sliceIndex, copyFromSlice: false)
    }
    
    return newData
}
