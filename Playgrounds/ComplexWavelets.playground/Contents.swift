//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

print("playground started")

let cA4L2 = calculateComplexWaveletCoefficients(vanishingMoments: 4, delayCoefficients: 3, rootsOutsideUnitCircle: [1, 2])
let cReal = Array(cA4L2.map({$0.real}))
cReal
let cRealW = Array(zip(cReal, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())
let cImag = Array(cA4L2.map({$0.imaginary}))
cImag
let cImagW = Array(zip(cImag, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())

let filterX = (0..<cReal.count).map({Float($0)})
let cRealSFT = fullSpectrumFT(filter: cReal.map({$0 + 0*i}), x: filterX)
let cImagSFT = fullSpectrumFT(filter: cImag.map({$0 + 0*i}), x: filterX)
let cRealWFT = fullSpectrumFT(filter: cRealW.map({$0 + 0*i}), x: filterX)
let cImagWFT = fullSpectrumFT(filter: cImagW.map({$0 + 0*i}), x: filterX)

QuickLinesPlot(x: cRealSFT.xArray, y: cRealSFT.abs, cImagSFT.abs)
QuickLinesPlot(x: cImagSFT.xArray, y: cRealWFT.abs, cImagWFT.abs)


let crSum = cReal.reduce(0, {$0 + $1*$1})
crSum
let ciSum = cImag.reduce(0, {$0 + $1*$1})
ciSum

let crScaling = scalingFunction(from: cReal, levels: 6)
let ciScaling = scalingFunction(from: cImag, levels: 6)
let crWavelet = waveletFunction(scalingFunction: crScaling, coefficients: cRealW)
let ciWavelet = waveletFunction(scalingFunction: ciScaling, coefficients: cImagW)
let cWavelet = zip(crWavelet, ciWavelet).map({ComplexNumber(real: $0.0, imaginary: $0.1)})
let cScaling = zip(crScaling, ciScaling).map({ComplexNumber(real: $0.0, imaginary: $0.1)})
let cSAbsolute = cScaling.map({$0.absoluteValue})
let cSArgument = cScaling.map({$0.argument})
let cAbsolute = cWavelet.map({$0.absoluteValue})
let cArgument = cWavelet.map({$0.argument})

let xArray = (0..<crScaling.count).map({Float($0 * (cReal.count-1)) / Float(crScaling.count-1)})

QuickLinesPlot(x: xArray, y: crWavelet, ciWavelet)
//QuickLinesPlot(x: xArray, y: ciWavelet)
QuickLinesPlot(x: xArray, y: cAbsolute)
QuickLinesPlot(x: xArray, y: cArgument)

QuickLinesPlot(x: xArray, y: crScaling, ciScaling)
//QuickLinesPlot(x: xArray, y: ciScaling)
QuickLinesPlot(x: xArray, y: cSAbsolute)
QuickLinesPlot(x: xArray, y: cSArgument)

let complexScaling = zip(crScaling, ciScaling).map({$0.0 + $0.1*i})
let complexWavelet = zip(crWavelet, ciWavelet).map({$0.0 + $0.1*i})
let scalingFT = fullSpectrumFT(filter: complexScaling, x: xArray)
let waveletFT = fullSpectrumFT(filter: complexWavelet, x: xArray)

QuickLinesPlot(x: scalingFT.xArray, y: scalingFT.abs)
QuickLinesPlot(x: waveletFT.xArray, y: waveletFT.abs)

//var currentApproxR: [Float] = [1]
//var currentApproxI: [Float] = [1]
//for _ in 0..<5 {
//    currentApproxR = newFilterApproximation(currentApproxR, coefficients: cReal)
//    currentApproxI = newFilterApproximation(currentApproxI, coefficients: cImag)
//}
//
//QuickArrayPlot(array: currentApproxR, currentApproxI)
//
//let waveletApproxR = waveletFunction(scalingFunction: currentApproxR + [0], coefficients: cRealW)
//let waveletApproxI = waveletFunction(scalingFunction: currentApproxI + [0], coefficients: cImagW)
//
//QuickArrayPlot(array: waveletApproxR, waveletApproxI)
