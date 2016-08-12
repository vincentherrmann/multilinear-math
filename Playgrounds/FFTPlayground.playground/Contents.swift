//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

//setup nodes
//let forwardFFT = FourierTransform(modeSizes: [4, 4])
//let inverseFFT = InverseFourierTransform(modeSizes: [4, 4])
//
//let inputSignal = randomTensor(modeSizes: 2, 4, 4).uniquelyIndexed()
//let transformedSignal = forwardFFT.execute([inputSignal])

let a: [Float] = [0, -2, 2.0, -2, 1, 0.5, -0.2, 3.0]
let quickLook = QuickArrayPlot(array: a)
let bounds = quickLook.plotView.plottingBounds
//let p = quickLook.plotView.plots[0].plotBounds


