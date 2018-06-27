//
//  Tensors.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

///Latin and greek letters to index modes of a tensor
public enum TensorIndex: Int {

    case notIndexed = 0

    case a = 1
    case b
    case c
    case d
    case e
    case f
    case g
    case h
    case i
    case j
    case k
    case l
    case m
    case n
    case o
    case p
    case q
    case r
    case s
    case t
    case u
    case v
    case w
    case x
    case y
    case z

    //greek letters usually index tensors in a fourdimensional spacetime
    case α
    case β
    case γ
    case δ
    case ε
    case ζ
    case η
    case θ
    case ι
    case κ
    case λ
    case μ
    case ν
    case ξ
    case ο
    case π
    case ρ
    case σ
    case τ
    case υ
    case φ
    case χ
    case ψ
    case ω

    /// - Returns: An array of unique tensor indices that does not containt any of the excluded indices.
    static public func uniqueIndexArray(_ count: Int, excludedIndices: [TensorIndex] = []) -> [TensorIndex] {
        let allPossibleIndices = Array(1...(count + excludedIndices.count))
        let withoutExcludedIndices = allPossibleIndices.removeValues(excludedIndices.map({$0.rawValue}))

        let uniqueIndices: [TensorIndex] = withoutExcludedIndices[0..<count].map({
            if let i = TensorIndex(rawValue: $0) {
                return i
            } else {
                print("cannot find a unique index for mode \($0)")
                return TensorIndex.notIndexed
            }
        })

        return uniqueIndices
    }
}


public enum TensorVariance {
    case contravariant
    case covariant
}

public struct CommonTensorIndex {
    /// the TensorIndex marking this index
    public var index: TensorIndex = .a
    /// the mode of this index in Tensor A
    public var modeA: Int = 0
    /// the mode of this index in Tensor B
    public var modeB: Int = 0
}


public struct Tensor<T: Number>: MultidimensionalData, CustomReflectable {
    //MultidimensionalData properties:
    public typealias Element = T
    public var modeSizes: [Int]
    public var values: [T] = []

    //Tensor properties:
    ///Symbolic indices of the modes
    public var indices: [TensorIndex] = []
    ///Variances of the modes
    public var variances: [TensorVariance]
    ///If true, this tensor is in Euclidian space and variances are indifferent
    public var isCartesian: Bool = true
    public var isIndexed: Bool {
        get {
            return indices.count == modeCount
        }
    }

    public var customMirror: Mirror {
        get {
            let mirror = Mirror.init(self, children: ["indices": self.indices, "mode sizes": self.modeSizes, "values": self.values], displayStyle: .tuple)
            return mirror
        }
    }

    public init(modeSizes: [Int], values: [T]) {
        let elementCount = modeSizes.reduce(1, {$0*$1})
        assert(elementCount == values.count, "Cannot initialize a tensor with \(elementCount) elements with \(values.count) values")

        self.modeSizes = modeSizes
        self.values = values
        self.indices = [TensorIndex](repeating: .notIndexed, count: modeSizes.count)
        self.variances = [TensorVariance](repeating: .contravariant, count: modeSizes.count)

//        print("new tensor with modeSized \(modeSizes)")

        if(modeSizes.count < 1) {

        }
    }

    public init(modeSizes: [Int], repeatedValue: T) {
        let elementCount = modeSizes.reduce(1, {$0*$1})

        self.modeSizes = modeSizes
        self.values = [T](repeating: repeatedValue, count: elementCount)
        self.indices = [TensorIndex](repeating: .notIndexed, count: modeSizes.count)
        self.variances = [TensorVariance](repeating: .contravariant, count: modeSizes.count)

        if(values.count == 0) {
            print("ERROR: value.count = 0!!!")
        }

//        print("new tensor with modeSized \(modeSizes)")
    }

    public init(diagonalWithModeSizes modeSizes: [Int], diagonalValues: [T]? = nil, repeatedValue: T = T(1)) {
        guard modeSizes.count > 0 else {
            self.init(scalar: T(1))
            return
        }

        let elementCount = modeSizes.reduce(1, {$0*$1})
        let modeCount = modeSizes.count
        let diagonalLength: Int = modeSizes.count > 0 ? modeSizes.min()! : 1
        var values = [T](repeating: T(0), count: elementCount)

        for i in 0..<diagonalLength {
            let index = [Int](repeating: i, count: modeCount)
            var thisFlatIndex = 0
            for d in 0..<modeCount {
                thisFlatIndex = thisFlatIndex * modeSizes[d] + index[d]
            }
            if(diagonalValues != nil) {
                values[thisFlatIndex] = diagonalValues![i]
            } else {
                values[thisFlatIndex] = repeatedValue
            }
        }

        self.init(modeSizes: modeSizes, values: values)
    }

    public init(scalar: T) {
        self.init(modeSizes: [], values: [scalar])
    }

    ///Init with a CSV file
    public init(valuesFromFileAtPath path: String, modeSizes: [Int]? = nil) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: path)) else {
            print("cannot load file at path \(path)")
            self.init(modeSizes: [], values: [T(0)])
            return
        }

        guard let content = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else {
            print("cannot load file at path \(path)")
            self.init(modeSizes: [], values: [T(0)])
            return
        }

        let lines = content.components(separatedBy: CharacterSet.newlines)
        var values = [T]()

        for line in lines {
            let theseValues = line.components(separatedBy: ",")
            values.append(contentsOf: theseValues.map({T(($0 as NSString).doubleValue)}))
        }

        var actualModeSizes: [Int]
        if(modeSizes != nil) {
            actualModeSizes = modeSizes!
        } else {
            actualModeSizes = [lines.count, values.count/lines.count]
        }

        if(values.count > actualModeSizes.reduce(1, *)) {
            if(values.last == T(0)) {
                values.removeLast()
            }
        }

        self.init(modeSizes: actualModeSizes, values: values)
    }

    /// Initialize this tensor with the properties of another tensor (or some modes of that tensor)
    public init(withPropertiesOf data: Tensor<T>, onlyModes: [Int]? = nil, newModeSizes: [Int]? = nil, repeatedValue: Element = T(0), values: [Element]? = nil) {

        let modes: [Int] = (onlyModes == nil) ? data.modeArray : onlyModes!

        let sizes: [Int]
        if(newModeSizes == nil) {
            sizes = modes.map({data.modeSizes[$0]})
        } else {
            sizes = newModeSizes!
        }

        if(values == nil) {
            self.init(modeSizes: sizes, repeatedValue: repeatedValue)
        } else {
            self.init(modeSizes: sizes, values: values!)
        }

        self.indices = modes.map({data.indices[$0]})
        self.variances = modes.map({data.variances[$0]})
        self.isCartesian = data.isCartesian
    }

    /// Initialize this tensor with the combined properties of tensorA and tensorB. The order of the modes will be outerModesA - outerModesB - innerModesA - innerModesB, with corresponding size, index and variance.
    public init(combinationOfTensorA a: Tensor<T>, tensorB b: Tensor<T>, outerModesA: [Int], outerModesB: [Int], innerModesA: [Int], innerModesB: [Int], repeatedValue: T) {

        // concatenating these arrays with "+" seems to provoke long compile times
        var combinedModeSizes: [Int] = []
        combinedModeSizes.append(contentsOf: outerModesA.map({a.modeSizes[$0]}))
        combinedModeSizes.append(contentsOf: outerModesB.map({b.modeSizes[$0]}))
        combinedModeSizes.append(contentsOf: innerModesA.map({a.modeSizes[$0]}))
        combinedModeSizes.append(contentsOf: innerModesB.map({b.modeSizes[$0]}))
        self.modeSizes = combinedModeSizes

        var combinedIndices: [TensorIndex] = []
        combinedIndices.append(contentsOf: outerModesA.map({a.indices[$0]}))
        combinedIndices.append(contentsOf: outerModesB.map({b.indices[$0]}))
        combinedIndices.append(contentsOf: innerModesA.map({a.indices[$0]}))
        combinedIndices.append(contentsOf: innerModesB.map({b.indices[$0]}))
        self.indices = combinedIndices

        var combinedVariances: [TensorVariance] = []
        combinedVariances.append(contentsOf: outerModesA.map({a.variances[$0]}))
        combinedVariances.append(contentsOf: outerModesB.map({b.variances[$0]}))
        combinedVariances.append(contentsOf: innerModesA.map({a.variances[$0]}))
        combinedVariances.append(contentsOf: innerModesB.map({b.variances[$0]}))
        self.variances = combinedVariances
        if(a.isCartesian && b.isCartesian) {
            self.isCartesian = true
        } else {
            self.isCartesian = false
        }

        let elementCount = modeSizes.reduce(1, {$0*$1})
        self.values = [T](repeating: repeatedValue, count: elementCount)
    }

    public init(fromFileAt: String) {
        guard let data = try? Data(contentsOf: URL(fileURLWithPath: fromFileAt)) else {
            print("could not load file \(fromFileAt)")
            self.init(scalar: T(0))
            return
        }

        let intSize = MemoryLayout<Int>.size
        var currentLocation: Int = 0

        var dataType: Int = 0
        (data as NSData).getBytes(&dataType, range: NSRange(location: currentLocation, length: intSize))
        currentLocation += intSize

        guard dataType == 1 else {
            print("wrong data type: \(dataType)")
            self.init(scalar: T(0))
            return
        }

        var fileModeCount: Int = 0
        (data as NSData).getBytes(&fileModeCount, range: NSRange(location: currentLocation, length: intSize))
        currentLocation += intSize

        var fileModeSizes: [Int] = []
        for _ in 0..<fileModeCount {
            var thisSize: Int = 0
            (data as NSData).getBytes(&thisSize, range: NSRange(location: currentLocation, length: intSize))
            currentLocation += intSize
            fileModeSizes.append(thisSize)
        }

        self.init(modeSizes: fileModeSizes, repeatedValue: T(0))

        (data as NSData).getBytes(&values, range: NSRange(location: currentLocation, length: MemoryLayout<T>.size * elementCount))
    }

    public func writeToFile(_ path: String) {
        //file format:
        // 8 bytes: data type (1 == Float32)
        // 8 bytes: modeCount (Int)
        // 8 bytes: modeSize[0]
        // ...
        // 8 bytes: modeSize[modeCount-1]
        // bytes of the flat value array
        // ...
        var propertiesArray: [Int] = []
        let elementTypeCode: Int = (Element.self == Float.self) ? 1 : 0
        propertiesArray.append(elementTypeCode)
        propertiesArray.append(modeCount)
        propertiesArray.append(contentsOf: modeSizes)

        let data = NSMutableData(bytes: &propertiesArray, length: MemoryLayout<Int>.size*propertiesArray.count)
        data.append(values, length: MemoryLayout<Element>.size * elementCount)

        data.write(toFile: path, atomically: true)
    }

    /// - Returns: The number of seperate copy streaks that would be necessary for this reordering of indices
    public func reorderComplexityOf(_ newIndices: [TensorIndex]) -> Int {
        assert(indices.count == newIndices.count, "Cannot reorder indices \(indices) to \(newIndices)")

        let hasToChange = indices.combineWith(newIndices, combineFunction: { (oldIndex, newIndex) -> Bool in
            return oldIndex != newIndex
        })
        if let lastMode = Array(hasToChange.reversed()).index(where: {$0}) { //last mode that has to change
            return modeSizes[0...(modeCount-1-lastMode)].reduce(1, {$0*$1})
        } else {
            return 0
        }
    }

    mutating public func newModeOrder(_ newToOld: [Int], oldData: Tensor) {
        indices = newToOld.map({oldData.indices[$0]})
        variances = newToOld.map({oldData.variances[$0]})
    }

    /// - Returns: A suggestion for an order of the indices that contains the given continous index streak while leaving as many modes in place as possible, the number of modes left of the streak and the number of modes after the streak
    public func suggestOrderForIndexStreak(_ streak: [TensorIndex]) -> (indices: [TensorIndex], modesBeforeStreak: Int, modesAfterStreak: Int) {
        let modeOfLastStreakIndex = indices.index(of: streak.last!)!
        let nonStreakIndicesRight = indices[modeOfLastStreakIndex+1..<modeCount].removeValues(streak)
        let nonStreakIndicesLeft = indices[0..<modeOfLastStreakIndex].removeValues(streak)

        let newOrder = nonStreakIndicesLeft + streak + nonStreakIndicesRight
        assert(newOrder.count == modeCount, "Cannot order the indices \(indices) to have a streak \(streak)")
        return (newOrder, nonStreakIndicesLeft.count, nonStreakIndicesRight.count)
    }

    public func optimalOrderForModeStreak(_ streak: [Int]) -> (newToOld: [Int], oldToNew: [Int], streakRange: CountableRange<Int>) {
        if(streak.count == 0) {
            return (modeArray, modeArray, 0..<0)
        }

        //Example:
        // streak: (3 0 5|2|)
        // modes:  (0 1|2|3 4 5 6)
        // nonStreakModesRight = (3 4 5 6) - (3 0 5 2) = (4 6)
        // nonStreakModesLeft  = (0 1)     - (3 0 5 2) = (1)
        // newOrder = (1) (3 0 5 2) (4 6)

        //      0 1 2 3 4 5 6
        // old: a b c d e f g
        // new: b d a f c e g

        // newToOld: 1 3 0 5 2 4 6
        // oldToNew: 2 0 4 1 5 3 6

        let nonStreakModesRight = modeArray[streak.last!+1..<modeCount].removeValues(streak)
        let nonStreakModesLeft = modeArray[0..<streak.last!].removeValues(streak)

        let newOrder = nonStreakModesLeft + streak + nonStreakModesRight
        assert(newOrder.count == modeCount, "Cannot sort \(modeCount) modes to have a order \(streak)")
        let streakRange = CountableRange<Int>(start: nonStreakModesLeft.count, distance: streak.count)
        let oldToNew = (0..<modeCount).map({newOrder.index(of: $0)!})

        return (newOrder, oldToNew, streakRange)
    }

    // MARK: - Indices
    /// Label the modes with the given TensorIndices and return `self`. The number of new indices an the mode count of this tensor do not have to be the same. The indices get replaced from right to left. This means if there are more new indices than modes, only the last new indices will be used. If there are more modes than new indices, the only the indices of the last modes will be replaced.
    public subscript(newIndices: TensorIndex...) -> Tensor<T> {
        get {
            var newTensor = self
            let writableIndexCount = min(newIndices.count, newTensor.modeCount)
            newTensor.indices[(newTensor.modeCount - writableIndexCount) ..< newTensor.modeCount] = newIndices[(newIndices.count - writableIndexCount) ..< newIndices.count]
            return newTensor
        }
    }

    /// - Returns: A tensor with automatically created unique indices. If the indices were already unique, nothing changes.
    public func uniquelyIndexed(_ excludedIndices: [TensorIndex] = []) -> Tensor<T> {
        //see if there are any duplicates
        let indexSet = Set(indices + excludedIndices) //Set() removes duplicates
        if(indexSet.count == (indices.count + excludedIndices.count)) {
            return self
        }

        var newTensor = self
        newTensor.indices = TensorIndex.uniqueIndexArray(modeCount, excludedIndices: excludedIndices)
        return newTensor
    }

    /// - Returns: The number of the mode indexed with the given letter, or nil
    public func modeWithIndex(_ index: TensorIndex) -> Int? {
        return indices.index(of: index)
    }

    /// - Returns: Size of the mode with the given index
    public func sizeOfModeWithIndex(_ index: TensorIndex) -> Int? {
        if let mode = modeWithIndex(index) {
            return modeSizes[mode]
        } else {
            return nil
        }
    }

//    public func getSliceofModes(indices: [TensorIndex]) -> Tensor<T> {
//        var sliceIndices = Array<DataSliceSubscript>(count: modeCount, repeatedValue: all)
//        for m in 0..<modeCount {
//            if let
//        }
//    }

    /// - Returns: The indices that this tensor has in common with the given tensor, the corresponding modes in this tensor and the corresponding modes in the given tensor. Modes with the default index `.notIndexed` cannot be common modes.
    public func commonIndicesWith(_ otherTensor: Tensor<T>) -> ([CommonTensorIndex]) {
        let commonIndices = indices.filter({otherTensor.indices.contains($0)})
        var result: [CommonTensorIndex] = []
        for thisIndex in commonIndices {
            if(thisIndex == .notIndexed) {
                continue
            }
            result.append(CommonTensorIndex(index: thisIndex, modeA: indices.index(of: thisIndex)!, modeB: otherTensor.indices.index(of: thisIndex)!))
        }
        return result
    }

//    public func customMirror() -> Mirror {
//        let mirror = Mirror.init(self, children: ["indices": self.indices, "mode sizes": self.modeSizes, "values": self.values], displayStyle: .tuple)
//        return mirror
//    }
}



// MARK: - Quick initializers
public func zeros(_ modeSizes: Int...) -> Tensor<Float> {
    return Tensor<Float>(modeSizes: modeSizes, repeatedValue: 0)
}

public func ones(_ modeSizes: Int...) -> Tensor<Float> {
    return Tensor<Float>(modeSizes: modeSizes, repeatedValue: 1)
}

public func randomTensor(min: Float = 0, max: Float = 1, modeSizes: Int...) -> Tensor<Float> {
    let elementCount = modeSizes.reduce(1, {$0*$1})
    let distance = max - min
    let values = (0..<elementCount).map({_ in (Float(arc4random()) / Float(UINT32_MAX)) * distance + min})
    return Tensor<Float>(modeSizes: modeSizes, values: values)
}

public extension Array where Element: Number {
    func tensor(_ modeSizes: [Int]) -> Tensor<Element> {
        return Tensor<Element>(modeSizes: modeSizes, values: self)
    }
}

