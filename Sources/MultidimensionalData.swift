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
    associatedtype Element

    /// the size in of mode
    var modeSizes: [Int] {get set}
    /// the raw values in a flat array
    var values: [Element] {get set}

    init(modeSizes: [Int], values: [Element])
    // TODO: Maybe replace this init with at `.makeWithSameProperties()` method?
    init(withPropertiesOf data: Self, onlyModes: [Int]?, newModeSizes: [Int]?, repeatedValue: Element, values: [Element]?)

    /// Will get called everytime the order of the modes changes. If there are any changes to be done, implement them here, else do nothing
    mutating func newModeOrder(_ newToOld: [Int], oldData: Self)
}

public extension MultidimensionalData {
    typealias S = Self

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
            return modeSizes.reduce(1, {$0*$1})
        }
    }

    /// simply Array(0..<modeCount)
    var modeArray: [Int] {
        get {
            return Array(0..<modeCount)
        }
    }

    init(modeSizes: [Int], repeatedValue: Element) {
        let count = modeSizes.reduce(1, {$0*$1})
        self.init(modeSizes: modeSizes, values: [Element](repeating: repeatedValue, count: count))
    }

    /// Convert a nested multidimensional index into a flat index
    /// - Returns: The flattened index
    func flatIndex(_ index: [Int]) -> Int {

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
    func nestedIndex(_ flatIndex: Int) -> [Int] {
        //converts a flat index into a multidimensional index
        var currentFlatIndex = flatIndex
        var index: [Int] = [Int](repeating: 0, count: max(modeCount, 1))

        for d in (0..<modeCount).reversed() {
            let thisIndex = currentFlatIndex % modeSizes[d]
            index[d] = thisIndex
            currentFlatIndex = (currentFlatIndex-thisIndex) / modeSizes[d]
        }

        return index
    }

    /// - Returns: The given flat index moved by a given number of steps in the given mode
    func moveFlatIndex(_ index: Int, by: Int, mode: Int) -> Int {
        var multiIndex = [Int](repeating: 0, count: modeCount)
        multiIndex[mode] = by

        return index + flatIndex(multiIndex)
    }

    /// - Returns: All flat indices lying in the given multidimensional range
    func indicesInRange(_ ranges: [CountableRange<Int>]) -> [Int] {
        //create indices array with start index (corner with the lowest index)
        var indices: [Int] = [flatIndex(ranges.map({return $0.first!}))]

        for m in (0..<modeCount).reversed() { //for each mode (start with last to have right order)
            for i in 0..<indices.count { //for every index currently in the array
                for r in 1..<ranges[m].count { //for every number in the specified range
                    //move indicex by this number in the current mode and add them to the array
                    indices.append(moveFlatIndex(indices[i], by: r, mode: m))
                }
            }
        }
        return indices
    }

    func getWithFlatIndex(_ flatIndex: Int) -> Element {
        return values[flatIndex]
    }
    mutating func set(_ newElement: Element, atFlatIndex: Int) {
        values[atFlatIndex] = newElement
    }

    mutating func setSlice(_ slice: S, modeSubscripts: [DataSliceSubscript]) {
        let subscripts = completeDataSliceSubscripts(modeSubscripts)

        let subscriptIndex = [Int](repeating: 0, count: modeCount)
        let sliceIndex = [Int](repeating: 0, count: slice.modeCount)

        if(values.count == 0) {
            print("error: no values to write in thread: \(Thread.current)")
        }

//        printMemoryAdresses(printTitle: "--set slice \(subscripts)--", printThread: true)
        values.performWithUnsafeMutableBufferPointer { (pointer) -> () in
            //print("set slice array pointer: \(pointer), in thread: \(NSThread.currentThread())")
//            recurseCopy(target: self, targetPointer: pointer, from: slice, subscripts: subscripts, subscriptMode: 0, subscriptIndex: subscriptIndex, sliceMode: 0, sliceIndex: sliceIndex, copyFromSlice: true)
            copySliceFrom(slice, to: self, targetPointer: pointer, subscripts: subscripts, copyFromSlice: true)
        }

//        recurseCopy(from: slice, subscripts: subscripts, subscriptMode: 0, subscriptIndex: subscriptIndex, sliceMode: 0, sliceIndex: sliceIndex, copyFromSlice: true)
    }

    ///Replace subscripts of type AllIndices with the complete range, same with missing subscripts
    internal func completeDataSliceSubscripts(_ subscripts: [DataSliceSubscript]) -> [DataSliceSubscript] {
        var newSubscripts = subscripts
        for m in 0..<modeCount {
            if(m >= subscripts.count) {
                newSubscripts.append(0..<modeSizes[m])
                continue
            }

            if newSubscripts[m] is AllIndices {
                newSubscripts[m] = 0..<modeSizes[m]
            }

            if let n = newSubscripts[m] as? CountableClosedRange<Int> {
                newSubscripts[m] = n.lowerBound..<n.upperBound+1
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
    internal func inferModes(commonModes: [Int]?, outerModes: [Int]?) -> (common: [Int], outer: [Int]) {
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
    func reorderModes(_ newToOld: [Int]) -> S {
        if(newToOld == Array(0..<modeCount) || newToOld.count == 0) {
            return self
        }

        //calculate mapping from modes in the original data to modes the new data
        let oldToNew = (0..<modeCount).map({(oldMode: Int) -> Int in
            guard let i = newToOld.index(of: oldMode) else {
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

        var newData = S(modeSizes: newToOld.map({modeSizes[$0]}), repeatedValue: values[0])

        let copyLength = modeSizes[lastChangedMode+1..<modeCount].reduce(1, {$0*$1})

        var currentOldIndex = [Int](repeating: 0, count: modeCount)
        var currentNewIndex = [Int](repeating: 0, count: modeCount)

        var copyRecursion: ((Int) -> Void)!

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

        newData.newModeOrder(newToOld, oldData: self)

        return newData
    }

//    public func changeOrderOfMode(mode: Int, newOrder: [Int]) -> S {
//        let outerModes = [mode]
//        var newData = S(withPropertiesOf: self, onlyModes: modeArray, repeatedValue: values[0], values: nil) as S
//        var outputData = [newData]
//
//        performOn(self, forOuterModes: outerModes, outputData: &outputData, calculate: ({ (currentIndex, outerIndex, sourceData) -> [S] in
//            let indexPosition = currentIndex[mode].sliceIndices()[0]
//            var newCurrentIndex = currentIndex
//            newCurrentIndex[mode] = newOrder[indexPosition]...newOrder[indexPosition]
//            return [(sourceData[slice: newCurrentIndex])]
//        }), writeOutput: ({ (currentIndex, outerIndex, inputData, outputData) in
//            outputData[slice: currentIndex] = inputData[0]
//        }))
//
//
//
//
//        return outputData[0]
//    }

//    public func shuffleMode(mode: Int) -> S {
//        let shuffledOrder = (0..<modeSizes[mode]).shuffle()
//        let shuffledData = changeOrderOfMode(mode, newOrder: shuffledOrder)
//        return shuffledData
//    }


    /// - Returns: The data as matrix unfolded along the given mode. If allowTranspose is true, the returned matrix could be transposed, if that was computationally more efficient
    public func matrixWithMode(_ mode: Int, allowTranspose: Bool = true) -> (matrix: [Element], size: MatrixSize, transpose: Bool) {
        assert(mode < modeCount, "mode \(mode) not available in tensor with \(modeCount) modes")

        let remainingModes = (0..<modeCount).filter({$0 != mode})
        let defaultOrder = [mode] + remainingModes
        let rows = modeSizes[mode]
        let columns = remainingModes.map({modeSizes[$0]}).reduce(1, {$0 * $1})

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
    func reorderComplexity(_ newToOld: [Int]) -> Int {
        let hasToChange = Array(0..<modeCount).combineWith(newToOld, combineFunction: {$0 != $1})

        if let lastMode = Array(hasToChange.reversed()).index(where: {$0}) { //last mode that has to change
            return modeSizes[0...(modeCount-1-lastMode)].reduce(1, {$0*$1})
        } else {
            return 0
        }
    }

    // MARK: - Subscripts
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
//    public func perform(outerModes outerModes: [Int], action: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) -> ()) {
//
//        func actionRecurse(indexNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) {
//            if(indexNumber < outerModes.count) {
//                let currentMode = outerModes[indexNumber]
//
//                for i in 0..<modeSizes[currentMode] {
//                    var newCurrentIndex = currentIndex
//                    newCurrentIndex[currentMode] = i...i
//                    var newOuterIndex = outerIndex
//                    newOuterIndex[indexNumber] = i...i
//                    actionRecurse(indexNumber + 1, currentIndex: newCurrentIndex, outerIndex: newOuterIndex)
//                }
//            } else {
//                let thisCurrentIndex = currentIndex
//                let thisOuterIndex = outerIndex
//                action(currentIndex: thisCurrentIndex, outerIndex: thisOuterIndex)
//            }
//        }
//
//        let startCurrentIndex: [DataSliceSubscript] = modeSizes.map({0..<$0})
//        let startOuterIndex: [DataSliceSubscript] = outerModes.map({modeSizes[$0]}).map({0..<$0})
//
//        actionRecurse(0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex)
//    }

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
    // MARK: - Perform functions
    public func performForOuterModes(_ outerModes: [Int], outputData: inout [Self],
                                     calculate: @escaping (_ currentIndex: [DataSliceSubscript], _ outerIndex: [DataSliceSubscript], _ sourceData: Self) -> [Self],
                                     writeOutput: @escaping (_ currentIndex: [DataSliceSubscript], _ outerIndex: [DataSliceSubscript], _ inputData: [Self], _ outputData: inout [Self]) -> ()) {

        let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
        let group = DispatchGroup()
        let sync = NSObject()

        var shadowOutputData = outputData; defer { outputData = shadowOutputData } //don't know if this works... see proposal 0035-limit-inout-capture

        func actionRecurse(outerModes: [Int], modeNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) {
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
                queue.async(group: group, execute: {
                    let result = calculate(currentIndex, outerIndex, self)

                    objc_sync_enter(sync)
                    writeOutput(currentIndex, outerIndex, result, &shadowOutputData)
                    objc_sync_exit(sync)
                })
            }
        }

//        outputData[0].printMemoryAdresses(printTitle: "--start output--")

        let startCurrentIndex: [DataSliceSubscript] = modeSizes.map({0..<$0})
        let startOuterIndex: [DataSliceSubscript] = outerModes.map({modeSizes[$0]}).map({0..<$0})

        actionRecurse(outerModes: outerModes, modeNumber: 0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex)

        group.wait(timeout: DispatchTime.distantFuture)
    }


    /// - Returns: The flat start indices in the value array of all continuous vectors (in the last mode) that constitute the given multidimensional range
    fileprivate func startIndicesOfContinuousVectorsForRange(_ ranges: [CountableRange<Int>]) -> [Int] {
        //the ranges of all modes except the last (where the continuous vectors are)
        var firstModesRanges = Array(ranges[0..<modeCount-1])
        firstModesRanges.append(ranges.last!.startIndex..<ranges.last!.startIndex+1)
        //the flat indices of the first elements in the last mode that lie in the firstModesRanges
        let indexPositions = indicesInRange(Array(firstModesRanges))
        //add the start offset of the last mode to each index
        return indexPositions//.map({return $0 + ranges.last!.first!})
    }

    internal mutating func printMemoryAdresses(printTitle: String? = nil, printThread: Bool = false) {
        var infoString: String = ""
        if let title = printTitle {
            infoString = title + "\n"
        }
        infoString = infoString + "MultidimensionalData with type <\(Element.self)> and \(elementCount) elements: "
        infoString = infoString + "\n memory address: \(memoryAddress(&self))"
        infoString = infoString + "\n array address: \(memoryAddress(values))"
        if(printThread) {
            infoString = infoString + "\n in thread: \(Thread.current)"
        }
        print(infoString)
    }
}

//public func performOn<T: MultidimensionalData>(data: T, forOuterModes outerModes: [Int], inout outputData: [T],
//                                 calculate: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], sourceData: T) -> [T],
//                                 writeOutput: (currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inputData: [T], inout outputData: [T]) -> ()) {
//
//    let queue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
//    let group = dispatch_group_create()
//    let sync = NSObject()
//
//    func actionRecurse(outerModes outerModes: [Int], modeNumber: Int, currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript]) {
//        if(modeNumber < outerModes.count) {
//            let currentMode = outerModes[modeNumber]
//
//            for i in 0..<data.modeSizes[currentMode] {
//                var newCurrentIndex = currentIndex
//                newCurrentIndex[currentMode] = i...i
//                var newOuterIndex = outerIndex
//                newOuterIndex[modeNumber] = i...i
//
//                actionRecurse(outerModes: outerModes, modeNumber: modeNumber + 1, currentIndex: newCurrentIndex, outerIndex: newOuterIndex)
//            }
//        } else {
//            dispatch_group_async(group, queue, {
//                let result = calculate(currentIndex:  currentIndex, outerIndex: outerIndex, sourceData: data)
//
//                objc_sync_enter(sync)
//                writeOutput(currentIndex: currentIndex, outerIndex: outerIndex, inputData: result, outputData: &outputData)
//                objc_sync_exit(sync)
//            })
//        }
//    }
//
//    //        outputData[0].printMemoryAdresses(printTitle: "--start output--")
//
//    let startCurrentIndex: [DataSliceSubscript] = data.modeSizes.map({0..<$0})
//    let startOuterIndex: [DataSliceSubscript] = outerModes.map({data.modeSizes[$0]}).map({0..<$0})
//
//    actionRecurse(outerModes: outerModes, modeNumber: 0, currentIndex: startCurrentIndex, outerIndex: startOuterIndex)
//
//    dispatch_group_wait(group, DISPATCH_TIME_FOREVER)
//}


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
//
//public func combine<T: MultidimensionalData>(a: T, outerModesA: [Int], b: T, outerModesB: [Int], combineFunction: @escaping (_ indexA: [DataSliceSubscript], _ indexB: [DataSliceSubscript], _ outerIndex: [DataSliceSubscript]) -> ()) {
//
//    let outerModeCount = outerModesA.count + outerModesB.count
//    var currentIndexA: [DataSliceSubscript] = a.modeSizes.map({0..<$0})
//    var currentIndexB: [DataSliceSubscript] = b.modeSizes.map({0..<$0})
//    var currentOuterIndex: [DataSliceSubscript] = (outerModesA.map({a.modeSizes[$0]}) + outerModesB.map({b.modeSizes[$0]})).map({0..<$0})
//
//    func actionRecurse(_ indexNumber: Int) {
//        if(indexNumber < outerModeCount) {
//            if(indexNumber < outerModesA.count) {
//                let currentMode = outerModesA[indexNumber]
//                for i in 0..<a.modeSizes[currentMode] {
//                    currentIndexA[currentMode] = i...i
//                    currentOuterIndex[indexNumber] = i...i
//                    actionRecurse(indexNumber + 1)
//                }
//            } else {
//                let currentMode = outerModesB[indexNumber - outerModesA.count]
//                for i in 0..<b.modeSizes[currentMode] {
//                    currentIndexB[currentMode] = i...i
//                    currentOuterIndex[indexNumber] = i...i
//                    actionRecurse(indexNumber + 1)
//                }
//            }
//        } else {
//            let aIndex = currentIndexA
//            let bIndex = currentIndexB
//            let outerIndex = currentOuterIndex
//            combineFunction(aIndex, bIndex, outerIndex)
//        }
//    }
//
//    actionRecurse(0)
//}

public func combine<T: MultidimensionalData>(_ a: T, forOuterModes outerModesA: [Int], with b: T, forOuterModes outerModesB: [Int], outputData: inout [T],
                    calculate: @escaping (_ indexA: [DataSliceSubscript], _ indexB: [DataSliceSubscript], _ outerIndex: [DataSliceSubscript], _ sourceA: T, _ sourceB: T) -> [T],
                    writeOutput: @escaping (_ indexA: [DataSliceSubscript], _ indexB: [DataSliceSubscript], _ outerIndex: [DataSliceSubscript], _ inputData: [T], _ outputData: inout [T]) -> ()) {

    let queue = DispatchQueue.global(priority: DispatchQueue.GlobalQueuePriority.default)
    let group = DispatchGroup()
    let sync = NSObject()

    let outerModeCount = outerModesA.count + outerModesB.count

    var shadowOutputData = outputData; defer { outputData = shadowOutputData } //don't know if this works... see proposal 0035-limit-inout-capture

    func actionRecurse(_ modeNumber: Int, currentIndexA: [DataSliceSubscript], currentIndexB: [DataSliceSubscript], currentOuterIndex: [DataSliceSubscript]) {
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
            queue.async(group: group, execute: {
                let result = calculate(currentIndexA, currentIndexB, currentOuterIndex, a, b)
                objc_sync_enter(sync)




                writeOutput(currentIndexA, currentIndexB, currentOuterIndex, result, &shadowOutputData)

                objc_sync_exit(sync)
            })
        }
    }

    let startIndexA: [DataSliceSubscript] = a.modeSizes.map({0..<$0})
    let startIndexB: [DataSliceSubscript] = b.modeSizes.map({0..<$0})
    let startOuterIndex: [DataSliceSubscript] = (outerModesA.map({a.modeSizes[$0]}) + outerModesB.map({b.modeSizes[$0]})).map({0..<$0})

    actionRecurse(0, currentIndexA: startIndexA, currentIndexB: startIndexB, currentOuterIndex: startOuterIndex)

    group.wait(timeout: DispatchTime.distantFuture)
}

public func concatenate<T: MultidimensionalData>(_ a: T, b: T, alongMode: Int) -> T {
    var newModeSizes: [Int]
    var sliceA: [DataSliceSubscript]
    var sliceB: [DataSliceSubscript]

    if(a.modeCount == b.modeCount) {
        sliceA = a.modeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = CountableRange(start: a.modeSizes[alongMode], distance: b.modeSizes[alongMode])

        newModeSizes = a.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + b.modeSizes[alongMode]
    } else if(a.modeCount == b.modeCount+1) {
        sliceA = a.modeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = CountableRange(start: a.modeSizes[alongMode], distance: 1)

        newModeSizes = a.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + 1
    } else if(a.modeCount == b.modeCount-1) {
        var aModeSizes = a.modeSizes
        aModeSizes.insert(1, at: alongMode)
        sliceA = aModeSizes.map({0..<$0})
        sliceB = sliceA
        sliceB[alongMode] = CountableRange(start: 1, distance: b.modeSizes[alongMode])
        newModeSizes = b.modeSizes
        newModeSizes[alongMode] = newModeSizes[alongMode] + 1
    } else {
        print("tensors with mode sizes \(a.modeSizes) and \(b.modeSizes) cannot be concatenated along mode \(alongMode)")
        return a
    }

    var concatData = T(modeSizes:  newModeSizes, repeatedValue: a.values[0])
    concatData[slice: sliceA] = a
    concatData[slice: sliceB] = b

    return concatData
}

//internal func testAction<T: MultidimensionalData>(currentIndex: [DataSliceSubscript], outerIndex: [DataSliceSubscript], inout outputData: T, inputData: T) -> () {
//
//    outputData.printMemoryAdresses(printThread: true)
//    outputData.values[0] = outputData.values[0]
//
//}
