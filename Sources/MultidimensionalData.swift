//
//  MultidimensionalData.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

/// Multidimensional collection of elements of a certain type. The elements are stored in a flat array but accessed with multidimensional Integer indices.
public protocol MultidimensionalData {
    /// the kind of value that is stored
    typealias Element
    
    /// the size in of mode
    var modeSizes: [Int] {get set}
    /// the raw values in a flat array
    var values: [Element] {get set}
    
    init(modeSizes: [Int], values: [Element])
    
    /// Will get called everytime the order of the modes changes. If there are any changes to be done, implement them here, else do nothing
    mutating func newModeOrder(newToOld: [Int])
}

public extension MultidimensionalData {
    /// number of modes
    var modeCount: Int {
        get {
            return modeSizes.count
        }
    }
    
    /// total number of elements
    var elementCount: Int {
        get {
            //multiply all modeSizes
            return modeSizes.reduce(1, combine: {$0*$1})
        }
    }
    
    /// simply Array(0..<modeCount)
    var modeArray: [Int] {
        get {
            return Array(0..<modeCount)
        }
    }
    
    init(modeSizes: [Int], repeatedValue: Element) {
        let count = modeSizes.reduce(1, combine: {$0*$1})
        self.init(modeSizes: modeSizes, values: [Element](count: count, repeatedValue: repeatedValue))
    }
    
    /// Convert a nested multidimensional index into a flat index
    /// - Returns: The flattened index
    func flatIndex(index: [Int]) -> Int {
        
        if(modeCount == 0) {
            return 0
        }
        
        //converts the multidimensional index into the index of the flattened data array
        assert(index.count == modeCount, "wrong number of modes in \(index), \(modeCount) indices needed")
        
        var thisFlatIndex = 0
        for d in 0..<modeCount {
            thisFlatIndex = thisFlatIndex * modeSizes[d] + index[d]
        }
        
        return thisFlatIndex
    }
    
    /// Convert a flat index into a multidimensional nested index
    /// - Returns: The nested index
    func nestedIndex(flatIndex: Int) -> [Int] {
        //converts a flat index into a multidimensional index
        var currentFlatIndex = flatIndex
        var index: [Int] = [Int](count: max(modeCount, 1), repeatedValue: 0)
        
        for d in (0..<modeCount).reverse() {
            let thisIndex = currentFlatIndex % modeSizes[d]
            index[d] = thisIndex
            currentFlatIndex = (currentFlatIndex-thisIndex) / modeSizes[d]
        }
        
        return index
    }
    
    /// - Returns: The given flat index moved by a given number of steps in the given mode
    func moveFlatIndex(index: Int, by: Int, mode: Int) -> Int {
        var multiIndex = [Int](count: modeCount, repeatedValue: 0)
        multiIndex[mode] = by
        
        return index + flatIndex(multiIndex)
    }
    
    /// - Returns: All flat indices lying in the given multidimensional range
    func indicesInRange(ranges: [Range<Int>]) -> [Int] {
        //create indices array with start index (corner with the lowest index)
        var indices: [Int] = [flatIndex(ranges.map({return $0.first!}))]
        
        for m in (0..<modeCount).reverse() { //for each mode (start with last to have right order)
            for i in 0..<indices.count { //for every index currently in the array
                for r in 1..<ranges[m].count { //for every number in the specified range
                    //move indicex by this number in the current mode and add them to the array
                    indices.append(moveFlatIndex(indices[i], by: r, mode: m))
                }
            }
        }
        return indices
    }
    
    func getWithFlatIndex(flatIndex: Int) -> Element {
        return values[flatIndex]
    }
    mutating func set(newElement: Element, atFlatIndex: Int) {
        values[atFlatIndex] = newElement
    }
    
    mutating func setSlice(slice: Self, modeSubscripts: [DataSliceSubscript]) {
        let subscripts = completeDataSliceSubscripts(modeSubscripts)
        
        let subscriptIndex = [Int](count: modeCount, repeatedValue: 0)
        let sliceIndex = [Int](count: slice.modeCount, repeatedValue: 0)
        
        if(values.count == 0) {
            print("error: no values to write in thread: \(NSThread.currentThread())")
        }
        
//        printMemoryAdresses(printTitle: "--set slice \(subscripts)--", printThread: true)
        values.performWithUnsafeMutableBufferPointer { (pointer) -> () in
            //print("set slice array pointer: \(pointer), in thread: \(NSThread.currentThread())")
            recurseCopy(target: self, targetPointer: pointer, from: slice, subscripts: subscripts, subscriptMode: 0, subscriptIndex: subscriptIndex, sliceMode: 0, sliceIndex: sliceIndex, copyFromSlice: true)
        }
        
//        recurseCopy(from: slice, subscripts: subscripts, subscriptMode: 0, subscriptIndex: subscriptIndex, sliceMode: 0, sliceIndex: sliceIndex, copyFromSlice: true)
    }
    
    ///Replace subscripts of type AllIndices with the complete range, same with missing subscripts
    internal func completeDataSliceSubscripts(subscripts: [DataSliceSubscript]) -> [DataSliceSubscript] {
        var newSubscripts = subscripts
        for m in 0..<modeCount {
            if(m >= subscripts.count) {
                newSubscripts.append(0..<modeSizes[m])
            }
            
            if newSubscripts[m] is AllIndices {
                newSubscripts[m] = 0..<modeSizes[m]
            }
            
            //replace a range of size 1 with the corresponding array, this is faster in most cases
            if(subscripts[m].sliceSize == 1) {
                newSubscripts[m] = subscripts[m].sliceIndices()
            }
        }
        return newSubscripts
    }
    
    ///Infer the common and outer modes for a combining function using the optional arguments
    /// - Returns:
    /// `common:` <br> The common modes, if neither common nor outer modes are defined, the whole `modeArray` is used. <br>
    /// `outer:` <br> The outer modes.
    internal func inferModes(commonModes commonModes: [Int]?, outerModes: [Int]?) -> (common: [Int], outer: [Int]) {
        if(commonModes != nil) {
            return (commonModes!, modeArray.removeValues(commonModes!))
        } else if(outerModes != nil) {
            return (modeArray.removeValues(outerModes!), outerModes!)
        } else {
            return (modeArray, [])
        }
    }
    
    ///Reorder the modes of this item
    /// - Parameter newToOld: Mapping from the new mode indices to the old ones
    /// - Returns: A copy of this item with the same values but reordered modes
    func reorderModes(newToOld: [Int]) -> Self {
        if(newToOld == Array(0..<modeCount) || newToOld.count == 0) {
            return self
        }
        
        //calculate mapping from modes in the original data to modes the new data
        let oldToNew = (0..<modeCount).map({(oldMode: Int) -> Int in
            guard let i = newToOld.indexOf(oldMode) else {
                assert(true, "mode \(oldMode) not found in mapping newToOld \(newToOld)")
                return 0
            }
            return i
        })
        
        var lastChangedMode = -1
        for d in 0..<modeCount {
            if(newToOld[d] != d) {
                lastChangedMode = d
            }
        }
        
        var newData = Self(modeSizes: newToOld.map({modeSizes[$0]}), repeatedValue: values[0])
        
        let copyLength = modeSizes[lastChangedMode+1..<modeCount].reduce(1, combine: {$0*$1})
        
        var currentOldIndex = [Int](count: modeCount, repeatedValue: 0)
        var currentNewIndex = [Int](count: modeCount, repeatedValue: 0)
        
        var copyRecursion: (Int -> Void)!
        
        copyRecursion = {(oldMode: Int) -> () in
            if(oldMode < lastChangedMode) {
                for i in 0..<self.modeSizes[oldMode] {
                    currentOldIndex[oldMode] = i
                    currentNewIndex[oldToNew[oldMode]] = i
                    copyRecursion(oldMode + 1)
                }
            } else {
                for i in 0..<self.modeSizes[oldMode] {
                    currentOldIndex[oldMode] = i
                    currentNewIndex[oldToNew[oldMode]] = i
                    
                    let oldFlatIndex = self.flatIndex(currentOldIndex)
                    let newFlatIndex = newData.flatIndex(currentNewIndex)
                    newData.values[newFlatIndex..<newFlatIndex+copyLength] = self.values[oldFlatIndex..<oldFlatIndex+copyLength]
                }
            }
        }
        
        copyRecursion(0)
        
        newData.newModeOrder(newToOld)
        
        return newData
    }
    
    /// - Returns: The data as matrix unfolded along the given mode. If allowTranspose is true, the returned matrix could be transposed, if that was computationally more efficient
    public func matrixWithMode(mode: Int, allowTranspose: Bool = true) -> (matrix: [Element], size: MatrixSize, transpose: Bool) {
        assert(mode < modeCount, "mode \(mode) not available in tensor with \(modeCount) modes")
        
        let remainingModes = (0..<modeCount).filter({$0 != mode})
        let defaultOrder = [mode] + remainingModes
        let rows = modeSizes[mode]
        let columns = remainingModes.map({modeSizes[$0]}).reduce(1, combine: {$0 * $1})
        
        if(allowTranspose) {
            let complexityDefault = reorderComplexity(defaultOrder)
            let transposeOrder = remainingModes + [mode]
            let complexityTranspose = reorderComplexity(transposeOrder)
            
            if(complexityTranspose < complexityDefault) {
                let size = MatrixSize(rows: columns, columns: rows)
                return(reorderModes(transposeOrder).values, size, true)
            }
        }
        
        let size = MatrixSize(rows: rows, columns: columns)
        return(reorderModes(defaultOrder).values, size, false)
    }
    
    /// - Returns: The number of seperate copy streaks that would be necessary for this reordering of modes
    func reorderComplexity(newToOld: [Int]) -> Int {
        let hasToChange = Array(0..<modeCount).combineWith(newToOld, combineFunction: {$0 != $1})
        
        if let lastMode = Array(hasToChange.reverse()).indexOf({$0}) { //last mode that has to change
            return modeSizes[0...(modeCount-1-lastMode)].reduce(1, combine: {$0*$1})
        } else {
            return 0
        }
    }
    
    public subscript(flatIndex: Int) -> Element {
        get {
            return getWithFlatIndex(flatIndex)
        }
        set(newValue) {
            set(newValue, atFlatIndex: flatIndex)
        }
    }
    public subscript(nestedIndex: [Int]) -> Element {
        get {
            return getWithFlatIndex(flatIndex(nestedIndex))
        }
        set(newValue) {
            set(newValue, atFlatIndex: flatIndex(nestedIndex))
        }
    }
    public subscript(nestedIndex: Int...) -> Element {
        get {
            return getWithFlatIndex(flatIndex(nestedIndex))
        }
        set(newValue) {
            set(newValue, atFlatIndex: flatIndex(nestedIndex))
        }
    }
    public subscript(slice modeIndices: [DataSliceSubscript]) -> Self {
        get {
            return getSlice(from: self, modeSubscripts: modeIndices)
        }
        
        set(newData) {
            setSlice(newData, modeSubscripts: modeIndices)
        }
    }
    public subscript(modeIndices: DataSliceSubscript...) -> Self {
        get {
            return getSlice(from: self, modeSubscripts: modeIndices)
        }
        set(newData) {
            setSlice(newData, modeSubscripts: modeIndices)
        }
    }
    
    /// Perform a given action for each index of a given subset of modes. The updating of the indices is done by another given function.
    ///
    /// - Parameter action: The action to perform for each index combination of the given modes.
    /// - Parameter indexUpdate: Function that will be called every time the index changes with the following arguments: <br>
    /// `indexNumber:` Index of `currentMode` in the `forModes` array. <br>
    /// `currentMode:`  The mode from the `forModes` where the index changed. <br>
    /// `i:` The updated index of the `currentMode`.
    ///- Parameter forModes: The subset of modes on which the `action` will be performed.
    public func perform(outerModes outerModes: [Int], action: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) -> ()) {
        
        func actionRecurse(indexNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) {
            if(indexNumber < outerModes.count) {
                let currentMode = outerModes[indexNumber]
                
                for i in 0..<modeSizes[currentMode] {
                    var newCurrentIndex = currentIndex
                    newCurrentIndex[currentMode] = i...i
                    var newOuterIndex = outerIndex
                    newOuterIndex[indexNumber] = i...i
                    actionRecurse(indexNumber + 1, currentIndex: newCurrentIndex, outerIndex: newOuterIndex)
                }
            } else {
                let thisCurrentIndex = currentIndex
                let thisOuterIndex = outerIndex
                action(currentIndex: thisCurrentIndex, outerIndex: thisOuterIndex)
            }
        }
        
        let startCurrentIndex: [DataSliceSubscript] = modeSizes.map({0..<$0})
        let startOuterIndex: [DataSliceSubscript] = outerModes.map({modeSizes[$0]}).map({0..<$0})
        
        actionRecurse(0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex)
    }
    
//    public func perform(action: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: Self, thisData: Self) -> (), outerModes: [Int], inout outputData: Self) {
//        
//        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//        let group = dispatch_group_create()
//        
//        outputData.printMemoryAdresses(printTitle: "--start output--")
//        
//        let startCurrentIndex: [DataSliceSubscript] = modeSizes.map({0..<$0})
//        let startOuterIndex: [DataSliceSubscript] = outerModes.map({modeSizes[$0]}).map({0..<$0})
//        actionRecurse(action, outerModes: outerModes, modeNumber: 0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex, outputData: &outputData, inputData: self, group: group, queue: queue)
//        
//        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
//        
//    }
    
//    public func perform(asyncAction: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], sourceData: Self) -> ([Self]),
//                        syncAction: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inputData: [Self], inout outputData: [Self]) -> (),
//                        outerModes: [Int], inout outputData: [Self]) {
//        
//        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//        let group = dispatch_group_create()
//        let sync = NSObject()
//        
//        func actionRecurse(outerModes outerModes: [Int], modeNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) {
//            if(modeNumber < outerModes.count) {
//                let currentMode = outerModes[modeNumber]
//                
//                for i in 0..<self.modeSizes[currentMode] {
//                    var newCurrentIndex = currentIndex
//                    newCurrentIndex[currentMode] = i...i
//                    var newOuterIndex = outerIndex
//                    newOuterIndex[modeNumber] = i...i
//                    
//                    actionRecurse(outerModes: outerModes, modeNumber: modeNumber + 1, currentIndex: newCurrentIndex, outerIndex: newOuterIndex)
//                }
//            } else {
//                dispatch_group_async(group, queue, { 
//                    let result = asyncAction(currentIndex:  currentIndex, outerIndex: outerIndex, sourceData: self)
//                    objc_sync_enter(sync)
//                    syncAction(currentIndex: currentIndex, outerIndex: outerIndex, inputData: result, outputData: &outputData)
//                    objc_sync_exit(sync)
//                })
//            }
//        }
//        
//        outputData[0].printMemoryAdresses(printTitle: "--start output--")
//        
//        let startCurrentIndex: [DataSliceSubscript] = modeSizes.map({0..<$0})
//        let startOuterIndex: [DataSliceSubscript] = outerModes.map({modeSizes[$0]}).map({0..<$0})
//        
//        actionRecurse(outerModes: outerModes, modeNumber: 0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex)
//        
//        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
//    }
    
    public func performForOuterModes(outerModes: [Int], inout outputData: [Self],
                                     calculate: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], sourceData: Self) -> [Self],
                                     writeOutput: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inputData: [Self], inout outputData: [Self]) -> ()) {
        
        let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
        let group = dispatch_group_create()
        let sync = NSObject()
        
        func actionRecurse(outerModes outerModes: [Int], modeNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) {
            if(modeNumber < outerModes.count) {
                let currentMode = outerModes[modeNumber]
                
                for i in 0..<self.modeSizes[currentMode] {
                    var newCurrentIndex = currentIndex
                    newCurrentIndex[currentMode] = i...i
                    var newOuterIndex = outerIndex
                    newOuterIndex[modeNumber] = i...i
                    
                    actionRecurse(outerModes: outerModes, modeNumber: modeNumber + 1, currentIndex: newCurrentIndex, outerIndex: newOuterIndex)
                }
            } else {
                dispatch_group_async(group, queue, {
                    let result = calculate(currentIndex:  currentIndex, outerIndex: outerIndex, sourceData: self)
                    objc_sync_enter(sync)
                    writeOutput(currentIndex: currentIndex, outerIndex: outerIndex, inputData: result, outputData: &outputData)
                    objc_sync_exit(sync)
                })
            }
        }
        
//        outputData[0].printMemoryAdresses(printTitle: "--start output--")
        
        let startCurrentIndex: [DataSliceSubscript] = modeSizes.map({0..<$0})
        let startOuterIndex: [DataSliceSubscript] = outerModes.map({modeSizes[$0]}).map({0..<$0})
        
        actionRecurse(outerModes: outerModes, modeNumber: 0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex)
        
        dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
    }
    
    
    /// - Returns: The flat start indices in the value array of all continuous vectors (in the last mode) that constitute the given multidimensional range
    private func startIndicesOfContinuousVectorsForRange(ranges: [Range<Int>]) -> [Int] {
        //the ranges of all modes except the last (where the continuous vectors are)
        var firstModesRanges = Array(ranges[0..<modeCount-1])
        firstModesRanges.append(ranges.last!.startIndex...ranges.last!.startIndex)
        //the flat indices of the first elements in the last mode that lie in the firstModesRanges
        let indexPositions = indicesInRange(Array(firstModesRanges))
        //add the start offset of the last mode to each index
        return indexPositions//.map({return $0 + ranges.last!.first!})
    }
    
    internal mutating func printMemoryAdresses(printTitle printTitle: String? = nil, printThread: Bool = false) {
        var infoString: String = ""
        if let title = printTitle {
            infoString = title + "\n"
        }
        infoString = infoString + "MultidimensionalData with type <\(Element.self)> and \(elementCount) elements: "
        infoString = infoString + "\n memory address: \(memoryAddress(&self))"
        infoString = infoString + "\n array address: \(memoryAddress(values))"
        if(printThread) {
            infoString = infoString + "\n in thread: \(NSThread.currentThread())"
        }
        print(infoString)
    }
}


/// Combine two `MultidimensionalData` items with the given `combineFunction`
///
/// - Parameter a: The first `MultidimensionalData` item
/// - Parameter outerModesA: The modes of `a` for which the `combineFunction` will be called
/// - Parameter b: The second `MultidimensionalData` item
/// - Parameter outerModesA: The modes of `b` for which the `combineFunction` will be called
/// - Parameter indexUpdate: This function will be called before each `combineFunction` call. Default is an empty function. <br> *Parameters*: <br>
/// `indexNumber:` The number of the `currentMode`, considering only the outerModes of both `a` and `b` together. <br>
/// `currentMode:` The index of the `currentMode` in the `modeArray` of either `a` or `b`. <br>
/// `currentModeIsA:` If true, the `currentMode` is from `a`, else from `b` <br>
/// `i`: The new index of the `currentMode`
/// - Parameter combineFunction: The action to combine `a` and `b`. <br> *Parateters*: <br>
/// `currentIndexA:` The index for `a` that gives the relevant slice for this particular call. <br>
/// `currentIndexB:` The index for `b` that gives the relevant slice for this particular call.
public func combine<T: MultidimensionalData>(a a: T, outerModesA: [Int], b: T, outerModesB: [Int], combineFunction: (indexA: [DataSliceSubscript], indexB: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) -> ()) {
    
    let outerModeCount = outerModesA.count + outerModesB.count
    var currentIndexA: [DataSliceSubscript] = a.modeSizes.map({0..<$0})
    var currentIndexB: [DataSliceSubscript] = b.modeSizes.map({0..<$0})
    var currentOuterIndex: [DataSliceSubscript] = (outerModesA.map({a.modeSizes[$0]}) + outerModesB.map({b.modeSizes[$0]})).map({0..<$0})

    func actionRecurse(indexNumber: Int) {
        if(indexNumber < outerModeCount) {
            if(indexNumber < outerModesA.count) {
                let currentMode = outerModesA[indexNumber]
                for i in 0..<a.modeSizes[currentMode] {
                    currentIndexA[currentMode] = i...i
                    currentOuterIndex[indexNumber] = i...i
                    actionRecurse(indexNumber + 1)
                }
            } else {
                let currentMode = outerModesB[indexNumber - outerModesA.count]
                for i in 0..<b.modeSizes[currentMode] {
                    currentIndexB[currentMode] = i...i
                    currentOuterIndex[indexNumber] = i...i
                    actionRecurse(indexNumber + 1)
                }
            }
        } else {
            let aIndex = currentIndexA
            let bIndex = currentIndexB
            let outerIndex = currentOuterIndex
            combineFunction(indexA: aIndex, indexB: bIndex, outerIndex: outerIndex)
        }
    }
    
    actionRecurse(0)
}

public func combine<T: MultidimensionalData>(a: T, forOuterModes outerModesA: [Int], with b: T, forOuterModes outerModesB: [Int], inout outputData: [T],
                    calculate: (indexA: [DataSliceSubscript], indexB: [DataSliceSubscript], outerIndex: [DataSliceSubscript], sourceA: T, sourceB: T) -> [T],
                    writeOutput: (indexA: [DataSliceSubscript], indexB: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inputData: [T], inout outputData: [T]) -> ()) {
    
    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
    let group = dispatch_group_create()
    let sync = NSObject()
    
    let outerModeCount = outerModesA.count + outerModesB.count
    
    func actionRecurse(modeNumber: Int, currentIndexA: [DataSliceSubscript], currentIndexB: [DataSliceSubscript], currentOuterIndex: [DataSliceSubscript]) {
        if(modeNumber < outerModeCount) {
            if(modeNumber < outerModesA.count) {
                let currentModeA = outerModesA[modeNumber]
                for i in 0..<a.modeSizes[currentModeA] {
                    var newCurrentIndexA = currentIndexA
                    newCurrentIndexA[currentModeA] = i...i
                    var newOuterIndex = currentOuterIndex
                    newOuterIndex[modeNumber] = i...i
                    actionRecurse(modeNumber + 1, currentIndexA: newCurrentIndexA, currentIndexB: currentIndexB, currentOuterIndex: newOuterIndex)
                }
            } else {
                let currentModeB = outerModesB[modeNumber - outerModesA.count]
                for i in 0..<b.modeSizes[currentModeB] {
                    var newCurrentIndexB = currentIndexB
                    newCurrentIndexB[currentModeB] = i...i
                    var newOuterIndex = currentOuterIndex
                    newOuterIndex[modeNumber] = i...i
                    actionRecurse(modeNumber + 1, currentIndexA: currentIndexA, currentIndexB: newCurrentIndexB, currentOuterIndex: newOuterIndex)
                }
                
            }
        } else {
            dispatch_group_async(group, queue, {
                let result = calculate(indexA: currentIndexA, indexB: currentIndexB, outerIndex: currentOuterIndex, sourceA: a, sourceB: b)
                objc_sync_enter(sync)
                writeOutput(indexA: currentIndexA, indexB: currentIndexB, outerIndex: currentOuterIndex, inputData: result, outputData: &outputData)
                objc_sync_exit(sync)
            })
        }
    }
    
    let startIndexA: [DataSliceSubscript] = a.modeSizes.map({0..<$0})
    let startIndexB: [DataSliceSubscript] = b.modeSizes.map({0..<$0})
    let startOuterIndex: [DataSliceSubscript] = (outerModesA.map({a.modeSizes[$0]}) + outerModesB.map({b.modeSizes[$0]})).map({0..<$0})
    
    actionRecurse(0, currentIndexA: startIndexA, currentIndexB: startIndexB, currentOuterIndex: startOuterIndex)
    
    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
}

//internal func actionRecurse<T: MultidimensionalData>(action: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: T, inputData: T) -> (),
//                            outerModes: [Int], modeNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: T, inputData: T, group: dispatch_group_t, queue: dispatch_queue_t) {
//    if(modeNumber < outerModes.count) {
//        let currentMode = outerModes[modeNumber]
//        
//        for i in 0..<inputData.modeSizes[currentMode] {
//            var newCurrentIndex = currentIndex
//            newCurrentIndex[currentMode] = i...i
//            var newOuterIndex = outerIndex
//            newOuterIndex[modeNumber] = i...i
//            
//            //outputData.printMemoryAdresses(printTitle: "----recurse--")
//            
//            actionRecurse(action, outerModes: outerModes, modeNumber: modeNumber + 1, currentIndex: newCurrentIndex, outerIndex: newOuterIndex, outputData: &outputData, inputData: inputData, group: group, queue: queue)
//        }
//    } else {
//        
//        //outputData.printMemoryAdresses(printTitle: "----recurse--")
//        
//        dispatchedAction(action, currentIndex: currentIndex, outerIndex: outerIndex, outputData: &outputData, inputData: inputData, group: group, queue: queue)
//    }
//}
//
//internal func dispatchedAction<T: MultidimensionalData>(action: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: T, inputData: T) -> (),
//                               currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: T, inputData: T, group: dispatch_group_t, queue: dispatch_queue_t) {
//    
//    
//    outputData.printMemoryAdresses(printTitle: "---before dispatch--")
//    dispatch_group_async(group, queue) {
//        outputData.printMemoryAdresses(printTitle: "--dispatch--", printThread: true)
//        action(currentIndex: currentIndex, outerIndex: outerIndex, outputData: &outputData, inputData: inputData)
////        testAction(currentIndex, outerIndex: outerIndex, outputData: &outputData, inputData: inputData)
//    }
//    
//}
//
//internal func testAction<T: MultidimensionalData>(currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: T, inputData: T) -> () {
//    
//    outputData.printMemoryAdresses(printThread: true)
//    outputData.values[0] = outputData.values[0]
//    
//}

