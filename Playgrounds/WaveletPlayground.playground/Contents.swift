//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let db2: [Float] = [1, 1]
let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
let db6: [Float] = [0.3326705529509569, 0.8068915093133388, 0.4598775021193313, -0.13501102001039084, -0.08544127388224149, 0.035226291882100656].map({$0 * pow(2, 0.5)})
let db8: [Float] = [0.23037781330885523, 0.7148465705525415, 0.6308807679295904, -0.02798376941698385, -0.18703481171888114, 0.030841381835986965, 0.032883011666982945, -0.010597401784997278].map({$0 * pow(2, 0.5)})

QuickArrayPlot(array: db2)
let db2Wavelet = createWaveletFromCoefficients(db2, levels: 6)
QuickArrayPlot(array: db2Wavelet)

QuickArrayPlot(array: db4)
let db4Wavelet = createWaveletFromCoefficients(db4, levels: 6)
QuickArrayPlot(array: db4Wavelet)

let spectrum = FIRFilter(coefficients: db4)
let v = Array(0..<99).map({(Float($0)/100)})
let fr = v.map({spectrum.frequencyResponse(6.28*$0)})
let impulseResponse = fr.map({$0.r*$0.r + $0.i*$0.i})
impulseResponse
QuickArrayPlot(array: impulseResponse)

QuickArrayPlot(array: db6)
let db6Wavelet = createWaveletFromCoefficients(db6, levels: 6)
QuickArrayPlot(array: db6Wavelet)

//test comment
