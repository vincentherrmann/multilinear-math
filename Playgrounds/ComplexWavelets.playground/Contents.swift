//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let db4 = calculateDaubechiesCoefficients(vanishingMoments: 2)
print("")

let cA4L2 = calculateComplexWaveletCoefficients(vanishingMoments: 3, delayCoefficients: 3)
let cReal = cA4L2.map({$0.real})
let cImag = cA4L2.map({$0.imaginary})

let crSum = cReal.reduce(0, {$0 + $1*$1})
crSum

let crWavelet = createWaveletFromCoefficients(cReal.map({$0}), levels: 6)
let ciWavelet = createWaveletFromCoefficients(cImag, levels: 5)

QuickArrayPlot(array: crWavelet)
QuickArrayPlot(array: ciWavelet)
