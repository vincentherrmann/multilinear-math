//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let db2: [Float] = [1, 1]
let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
let db6: [Float] = [0.33267054, 0.8068915, 0.4598775, -0.13501102, -0.08544128, 0.035226293]
//let db8: [Float] = [0.32580343, 1.01094572, 0.8922014, -0.03967503, -0.26450717, 0.030841382,0.03288301, -0.010597402]

QuickArrayPlot(array: db2)
let db2Wavelet = createWaveletFromCoefficients(db2, levels: 0)
QuickArrayPlot(array: db2Wavelet)

QuickArrayPlot(array: db4)
let db4Wavelet = createWaveletFromCoefficients(db4, levels: 0)
QuickArrayPlot(array: db4Wavelet)

//
//QuickArrayPlot(array: db6)
//let db6Wavelet = createWaveletFromCoefficients(db6, levels: 6)
//QuickArrayPlot(array: db6Wavelet)
