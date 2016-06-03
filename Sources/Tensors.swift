//
//  Tensors.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 27.03.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

///Latin and greek letters to index modes of a tensor
public enum TensorIndex: Hashable {
    
    case notIndexed
    
    case a
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


public struct Tensor<T: Number>: MultidimensionalData {
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
    
    public init(modeSizes: [Int], values: [T]) {
        let elementCount = modeSizes.reduce(1, combine: {$0*$1})
        assert(elementCount == values.count, "Cannot initialize a tensor with \(elementCount) elements with \(values.count) values")
        
        self.modeSizes = modeSizes
        self.values = values
        self.indices = [TensorIndex](count: modeSizes.count, repeatedValue: .notIndexed)
        self.variances = [TensorVariance](count: modeSizes.count, repeatedValue: .contravariant)
        
//        print("new tensor with modeSized \(modeSizes)")
        
        if(modeSizes.count < 1) {
            
        }
    }
    
    public init(modeSizes: [Int], repeatedValue: T) {
        let elementCount = modeSizes.reduce(1, combine: {$0*$1})
        
        self.modeSizes = modeSizes
        self.values = [T](count: elementCount, repeatedValue: repeatedValue)
        self.indices = [TensorIndex](count: modeSizes.count, repeatedValue: .notIndexed)
        self.variances = [TensorVariance](count: modeSizes.count, repeatedValue: .contravariant)
        
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
        
        let elementCount = modeSizes.reduce(1, combine: {$0*$1})
        let modeCount = modeSizes.count
        var diagonalLength: Int = modeSizes.count > 0 ? modeSizes.minElement()! : 1
        var values = [T](count: elementCount, repeatedValue:T(0))
        
        for i in 0..<diagonalLength {
            let index = [Int](count: modeCount, repeatedValue: i)
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
        guard let data = NSData(contentsOfFile: path) else {
            print("cannot load file at path \(path)")
            self.init(modeSizes: [], values: [T(0)])
            return
        }
        
        guard let content = NSString(data: data, encoding: NSUTF8StringEncoding) else {
            print("cannot load file at path \(path)")
            self.init(modeSizes: [], values: [T(0)])
            return
        }
        
        let lines = content.componentsSeparatedByCharactersInSet(NSCharacterSet.newlineCharacterSet())
        var values = [T]()
        
        for line in lines {
            let theseValues = line.componentsSeparatedByString(",")
            values.appendContentsOf(theseValues.map({T(($0 as NSString).doubleValue)}))
        }
        
        var actualModeSizes: [Int]
        if(modeSizes != nil) {
            actualModeSizes = modeSizes!
        } else {
            actualModeSizes = [lines.count, values.count/lines.count]
        }
        
        if(values.count > actualModeSizes.reduce(1, combine: *)) {
            if(values.last == T(0)) {
                values.removeLast()
            }
        }
        
        self.init(modeSizes: actualModeSizes, values: values)
    }
    
    /// Initialize this tensor with the properties of another tensor (or some modes of that tensor)
    public init(withPropertiesOf data: Tensor<T>, onlyModes: [Int]? = nil, repeatedValue: Element = T(0), values: [Element]? = nil) {
        
        let modes: [Int] = (onlyModes == nil) ? data.modeArray : onlyModes!
        let sizes = modes.map({data.modeSizes[$0]})
        
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
        combinedModeSizes.appendContentsOf(outerModesA.map({a.modeSizes[$0]}))
        combinedModeSizes.appendContentsOf(outerModesB.map({b.modeSizes[$0]}))
        combinedModeSizes.appendContentsOf(innerModesA.map({a.modeSizes[$0]}))
        combinedModeSizes.appendContentsOf(innerModesB.map({b.modeSizes[$0]}))
        self.modeSizes = combinedModeSizes
        
        var combinedIndices: [TensorIndex] = []
        combinedIndices.appendContentsOf(outerModesA.map({a.indices[$0]}))
        combinedIndices.appendContentsOf(outerModesB.map({b.indices[$0]}))
        combinedIndices.appendContentsOf(innerModesA.map({a.indices[$0]}))
        combinedIndices.appendContentsOf(innerModesB.map({b.indices[$0]}))
        self.indices = combinedIndices
        
        var combinedVariances: [TensorVariance] = []
        combinedVariances.appendContentsOf(outerModesA.map({a.variances[$0]}))
        combinedVariances.appendContentsOf(outerModesB.map({b.variances[$0]}))
        combinedVariances.appendContentsOf(innerModesA.map({a.variances[$0]}))
        combinedVariances.appendContentsOf(innerModesB.map({b.variances[$0]}))
        self.variances = combinedVariances
        if(a.isCartesian && b.isCartesian) {
            self.isCartesian = true
        } else {
            self.isCartesian = false
        }
        
        let elementCount = modeSizes.reduce(1, combine: {$0*$1})
        self.values = [T](count: elementCount, repeatedValue: repeatedValue)
    }
    
    /// - Returns: The number of seperate copy streaks that would be necessary for this reordering of indices
    public func reorderComplexityOf(newIndices: [TensorIndex]) -> Int {
        assert(indices.count == newIndices.count, "Cannot reorder indices \(indices) to \(newIndices)")
        
        let hasToChange = indices.combineWith(newIndices, combineFunction: { (oldIndex, newIndex) -> Bool in
            return oldIndex != newIndex
        })
        if let lastMode = Array(hasToChange.reverse()).indexOf({$0}) { //last mode that has to change
            return modeSizes[0...(modeCount-1-lastMode)].reduce(1, combine: {$0*$1})
        } else {
            return 0
        }
    }
    
    mutating public func newModeOrder(newToOld: [Int]) {
        indices = newToOld.map({indices[$0]})
        variances = newToOld.map({variances[$0]})
    }
    
    /// - Returns: A suggestion for an order of the indices that contains the given continous index streak while leaving as many modes in place as possible, the number of modes left of the streak and the number of modes after the streak
    public func suggestOrderForIndexStreak(streak: [TensorIndex]) -> (indices: [TensorIndex], modesBeforeStreak: Int, modesAfterStreak: Int) {
        let modeOfLastStreakIndex = indices.indexOf(streak.last!)!
        let nonStreakIndicesRight = indices[modeOfLastStreakIndex+1..<modeCount].removeValues(streak)
        let nonStreakIndicesLeft = indices[0..<modeOfLastStreakIndex].removeValues(streak)
        
        let newOrder = nonStreakIndicesLeft + streak + nonStreakIndicesRight
        assert(newOrder.count == modeCount, "Cannot order the indices \(indices) to have a streak \(streak)")
        return (newOrder, nonStreakIndicesLeft.count, nonStreakIndicesRight.count)
    }
    
    public func optimalOrderForModeStreak(streak: [Int]) -> (newToOld: [Int], oldToNew: [Int], streakRange: Range<Int>) {
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
        assert(newOrder.count == modeCount, "Cannot \(modeCount) modes to have a order \(streak)")
        let streakRange = Range<Int>(start: nonStreakModesLeft.count, distance: streak.count)
        let oldToNew = (0..<modeCount).map({newOrder.indexOf($0)!})
        
        return (newOrder, oldToNew, streakRange)
    }
    
    
    /// Label the modes with the given TensorIndices and return self
    public subscript(newIndices: TensorIndex...) -> Tensor<T> {
        get {
            var newTensor = self
            newTensor.indices = newIndices
            return newTensor
        }
    }
    
    /// - Returns: The number of the mode indexed with the given letter, or nil
    public func modeWithIndex(index: TensorIndex) -> Int? {
        return indices.indexOf(index)
    }
    
    /// - Returns: Size of the mode with the given index
    public func sizeOfModeWithIndex(index: TensorIndex) -> Int? {
        if let mode = modeWithIndex(index) {
            return modeSizes[mode]
        } else {
            return nil
        }
    }
    
    /// - Returns: The indices that this tensor has in common with the given tensor, the corresponding modes in this tensor and the corresponding modes in the given tensor
    public func commonIndicesWith(otherTensor: Tensor<T>) -> ([CommonTensorIndex]) {
        let commonIndices = Array(Set(indices).intersect(otherTensor.indices))
        var result: [CommonTensorIndex] = []
        for thisIndex in commonIndices {
            result.append(CommonTensorIndex(index: thisIndex, modeA: indices.indexOf(thisIndex)!, modeB: otherTensor.indices.indexOf(thisIndex)!))
        }
        return result
    }
    /// - Returns: The indices that this index has not in common with the given tensor, and the corresponding modes
    public func indicesNotInCommonWith(otherTensor: Tensor<T>) -> ([(index: TensorIndex, mode: Int)]) {
        let remainingIndices = Array(Set(indices).subtract(otherTensor.indices))
        var result: [(index: TensorIndex, mode: Int)] = []
        for thisIndex in remainingIndices {
            result.append((thisIndex, indices.indexOf(thisIndex)!))
        }
        return result
    }
}

public func zeros(modeSizes: Int...) -> Tensor<Float> {
    return Tensor<Float>(modeSizes: modeSizes, repeatedValue: 0)
}

public func ones(modeSizes: Int...) -> Tensor<Float> {
    return Tensor<Float>(modeSizes: modeSizes, repeatedValue: 1)
}

public func randomTensor(modeSizes: Int...) -> Tensor<Float> {
    let elementCount = modeSizes.reduce(1, combine: {$0*$1})
    let values = (0..<elementCount).map({_ in Float(arc4random()) / Float(UINT32_MAX)})
    return Tensor<Float>(modeSizes: modeSizes, values: values)
}

public extension Array where Element: Number {
    func tensor(modeSizes: [Int]) -> Tensor<Element> {
        return Tensor<Element>(modeSizes: modeSizes, values: self)
    }
}

