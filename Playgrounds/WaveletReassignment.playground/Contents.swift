//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

print("playground started")

//h0 filters
let cReal: [Float] = [-0.00252085552, 0.0188991688, 0.0510309711, -0.0490589067, 0.0589671507, 0.79271543, 1.0953089, 0.32142213, -0.227000564, -0.0872127786, 0.0242141522, 0.0032346386]
let cImag: [Float] = [-0.000504171127, -0.000253534876, 0.0460915789, 0.0190168768, -0.0825454742, 0.388706058, 1.10255682, 0.764762938, -0.0572841614, -0.188405827, -0.00831478462, 0.0161731932]

//h1 filters
let cRealW = Array(zip(cReal, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())
let cImagW = Array(zip(cImag, Array(0..<cImag.count)).map({$0 * pow(-1, Float($1))}).reversed())

//scaling and wavelet functions
let crScaling = scalingFunction(from: cReal, levels: 6)
let ciScaling = scalingFunction(from: cImag, levels: 6)
let crWavelet = waveletFunction(scalingFunction: crScaling, coefficients: cRealW)
let ciWavelet = waveletFunction(scalingFunction: ciScaling, coefficients: cImagW)

let res = Float((crScaling.count-1) / (cReal.count-1))
let xArray = (0..<crScaling.count).map({Float($0) / res})

//plot functions
QuickLinesPlot(x: xArray, y: crScaling, ciScaling)
QuickLinesPlot(x: xArray, y: crWavelet, ciWavelet)

let freq: Float = 0.7 // 0.5 * pow(2, 0.5)
let phase: Float = 0.5
let signal = xArray.map({sin(phase + freq * 2 * Float.pi * $0)})
QuickLinesPlot(x: xArray, y: signal)

//let complexWavelet = zip(crWavelet, ciWavelet).map({$0.0 + i*$0.1})
//let ft = fullSpectrumFT(filter: complexWavelet, x: xArray, resolution: 1000)
//QuickLinesPlot(x: ft.xArray, y: ft.abs, bounds: CGRect(x: 0, y: 0, width: 1, height: 150))

//derivatives
let crScalingDer = zip(Array(crScaling.dropFirst()) + [0], crScaling).map({res * ($0.0 - $0.1)})
let ciScalingDer = zip(Array(ciScaling.dropFirst()) + [0], ciScaling).map({res * ($0.0 - $0.1)})
let crWaveletDer = zip(Array(crWavelet.dropFirst()) + [0], crWavelet).map({res * ($0.0 - $0.1)})
let ciWaveletDer = zip(Array(ciWavelet.dropFirst()) + [0], ciWavelet).map({res * ($0.0 - $0.1)})

//plot derivatives
QuickLinesPlot(x: xArray, y: crScalingDer, ciScalingDer)

QuickLinesPlot(x: xArray, y: crWaveletDer, ciWaveletDer)

let aReal = zip(signal, crWavelet).reduce(0, {$0 + $1.0*$1.1}) / res
aReal
let aImag = zip(signal, ciWavelet).reduce(0, {$0 + $1.0*$1.1}) / res
aImag
let amplitude = (aReal + i*aImag).absoluteValue

let dReal = zip(signal, crWaveletDer).reduce(0, {$0 + $1.0*$1.1}) / res
dReal
let dImag = zip(signal, ciWaveletDer).reduce(0, {$0 + $1.0*$1.1}) / res
dImag

let p1 = ((dReal + i*dImag) * (aReal - i*aImag)).imaginary
//estimated frequency:
let p2 = p1 / (2 * Float.pi * pow((aReal + i*aImag).absoluteValue, 2))

//time ramps
let crScalingRamp = zip(crScaling, xArray).map({$0.0 * $0.1})
let ciScalingRamp = zip(ciScaling, xArray).map({$0.0 * $0.1})
let crWaveletRamp = zip(crWavelet, xArray).map({$0.0 * $0.1})
let ciWaveletRamp = zip(ciWavelet, xArray).map({$0.0 * $0.1})

QuickLinesPlot(x: xArray, y: crScalingRamp, ciScalingRamp)
QuickLinesPlot(x: xArray, y: crWaveletRamp, ciWaveletRamp)

//time ramp scaling filter
let crScalingRampFilter = coefficientsFromScalingFunction(values: crScalingRamp, count: cReal.count)
let ciScalingRampFilter = coefficientsFromScalingFunction(values: ciScalingRamp, count: cReal.count)
let crScalingRampFunction = scalingFunction(from: crScalingRampFilter, levels: 6)
let ciScalingRampFunction = scalingFunction(from: ciScalingRampFilter, levels: 6)

let crWaveletRampFilter = Array(zip(crScalingRampFilter, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())
let ciWaveletRampFilter = Array(zip(ciScalingRampFilter, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())
let crWaveletRampFunction = waveletFunction(scalingFunction: crScalingRampFunction, coefficients: crWaveletRampFilter)
let ciWaveletRampFunction = waveletFunction(scalingFunction: ciScalingRampFunction, coefficients: ciWaveletRampFilter)

QuickLinesPlot(x: xArray, y: crScalingRampFunction, ciScalingRampFunction)
QuickLinesPlot(x: xArray, y: crWaveletRampFunction, ciWaveletRampFunction)

let scalingRealTest = coefficientsFromScalingFunction(values: crScaling, count: cReal.count)
let scalingImagTest = coefficientsFromScalingFunction(values: ciScaling, count: cReal.count)

//derivative scaling filter
let crScalingDerFilter = coefficientsFromScalingFunction(values: crScalingDer, count: cReal.count)
let ciScalingDerFilter = coefficientsFromScalingFunction(values: ciScalingDer, count: cReal.count)
let crScalingDerFunction = scalingFunction(from: crScalingDerFilter, levels: 6)
let ciScalingDerFunction = scalingFunction(from: ciScalingDerFilter, levels: 6).map({-$0})

let crWaveletDerFilter = Array(zip(crScalingDerFilter, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())
let ciWaveletDerFilter = Array(zip(ciScalingDerFilter, Array(0..<cReal.count)).map({$0 * pow(-1, Float($1))}).reversed())
let crWaveletDerFunction = waveletFunction(scalingFunction: crScalingDerFunction, coefficients: crWaveletDerFilter)
let ciWaveletDerFunction = waveletFunction(scalingFunction: ciScalingDerFunction, coefficients: ciWaveletDerFilter)

QuickLinesPlot(x: xArray, y: crScalingDerFunction, ciScalingDerFunction)
QuickLinesPlot(x: xArray, y: crWaveletDerFunction, ciWaveletDerFunction)



QuickArrayPlot(array: cReal, crScalingDerFilter, crScalingRampFilter)

let crDerQuotient = zip(cReal, crScalingDerFilter).map({$0.0 / $0.1})
QuickArrayPlot(array: crDerQuotient)
let crRampQuotient = zip(cReal, crScalingRampFilter).map({$0.0 / $0.1})
QuickArrayPlot(array: crRampQuotient)


QuickArrayPlot(array: cImag, ciScalingDerFilter, ciScalingRampFilter)

let ciDerQuotient = zip(cImag, ciScalingDerFilter).map({$0.0 / $0.1})
QuickArrayPlot(array: ciDerQuotient)
let ciRampQuotient = zip(cImag, ciScalingRampFilter).map({$0.0 / $0.1})
QuickArrayPlot(array: ciRampQuotient)
