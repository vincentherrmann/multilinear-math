//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

//setup nodes
let forwardFFT = FourierTransform(modeSizes: [4, 4])
let inverseFFT = InverseFourierTransform(modeSizes: [4, 4])

let inputSignal = randomTensor(modeSizes: 2, 4, 4).uniquelyIndexed()
let transformedSignal = forwardFFT.execute([inputSignal])


