//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

print("playground started")

let cReal: [Float] = [-0.00252085552, 0.0188991688, 0.0510309711, -0.0490589067, 0.0589671507, 0.79271543, 1.0953089, 0.32142213, -0.227000564, -0.0872127786, 0.0242141522, 0.0032346386]
//let cReal: [Float] =  [0.6830127, 1.1830127, 0.3169873, -0.1830127]

let wavelet = Wavelet(h0: cReal, f0: cReal.reversed())

let xArray = Array(0..<50).map({Float.pi * Float($0) / 50})

var filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 2))
QuickArrayPlot(array: filter.coefficients)
let ft2 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft2)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 3))
QuickArrayPlot(array: filter.coefficients)
let ft3 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft3)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 4))
QuickArrayPlot(array: filter.coefficients)
let ft4 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft4)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 5))
QuickArrayPlot(array: filter.coefficients)
let ft5 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft5)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 6))
QuickArrayPlot(array: filter.coefficients)
let ft6 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft6)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 7))
QuickArrayPlot(array: filter.coefficients)
let ft7 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft7)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 8))
QuickArrayPlot(array: filter.coefficients)
let ft8 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft8)
filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 9))
QuickArrayPlot(array: filter.coefficients)
let ft9 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft9)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 10))
QuickArrayPlot(array: filter.coefficients)
let ft10 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft10)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 11))
QuickArrayPlot(array: filter.coefficients)
let ft11 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft11)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 12))
QuickArrayPlot(array: filter.coefficients)
let ft12 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft12)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 13))
QuickArrayPlot(array: filter.coefficients)
let ft13 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft13)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 14))
QuickArrayPlot(array: filter.coefficients)
let ft14 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft14)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 15))
QuickArrayPlot(array: filter.coefficients)
let ft15 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft15)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 16))
QuickArrayPlot(array: filter.coefficients)
let ft16 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft16)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 24))
QuickArrayPlot(array: filter.coefficients)
let ft24 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft24)

filter = FIRFilter(coefficients: wavelet.analysisFilter(for: 56))
QuickArrayPlot(array: filter.coefficients)
let ft56 = filter.frequencyResponse().response.map({$0.absoluteValue})
QuickLinesPlot(x: xArray, y: ft56)
