//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
QuickArrayPlot(array: db4)
var wavelet = calculateIntegerWaveletValues(db4)
QuickArrayPlot(array: wavelet)
wavelet = newWaveletApproximation(wavelet, coefficients: db4)
QuickArrayPlot(array: wavelet)
wavelet = newWaveletApproximation(wavelet, coefficients: db4)
QuickArrayPlot(array: wavelet)

wavelet = newWaveletApproximation(wavelet, coefficients: db4)
QuickArrayPlot(array: wavelet)