//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let db2: [Float] = [1, 1]
let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
let db4w: [Float] = [0.6830127, -1.1830127, 0.3169873, 0.1830127]
let db6: [Float] = [0.3326705529509569, 0.8068915093133388, 0.4598775021193313, -0.13501102001039084, -0.08544127388224149, 0.035226291882100656].map({$0 * pow(2, 0.5)})
let db8: [Float] = [0.23037781330885523, 0.7148465705525415, 0.6308807679295904, -0.02798376941698385, -0.18703481171888114, 0.030841381835986965, 0.032883011666982945, -0.010597401784997278].map({$0 * pow(2, 0.5)})

QuickArrayPlot(array: db2)
let db2Wavelet = createWaveletFromCoefficients(db2, levels: 6)
QuickArrayPlot(array: db2Wavelet)

QuickArrayPlot(array: db4)
let db4Wavelet = createWaveletFromCoefficients(db4, levels: 6)
//let db4WaveletP = QuickArrayPlot(array: db4Wavelet)
let db4WaveletY = Array(0..<db4Wavelet.count).map({Float($0)/64})
let db4WaveletP = QuickLinesPlot(x: db4WaveletY, y: db4Wavelet, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//db4WaveletP.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4ScalingFunction.pdf")
//let q = QuickLinesPlot(x: Array(0..<db4Wavelet.count).map({Float($0)*4/Float(db4Wavelet.count)}), y: db4Wavelet, bounds: CGRect(x: 0, y: -1, width: 4, height: 2))
//q

//let db4WaveletW = createWaveletFromCoefficients(db4w, levels: 6)
////let db4WaveletP = QuickArrayPlot(array: db4Wavelet)
//let db4WaveletWP = QuickLinesPlot(x: db4WaveletY, y: db4WaveletW, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//db4WaveletWP.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletFunction.pdf")
//let q = QuickLinesPlot(x: Array(0..<db4Wavelet.count).map({Float($0)*4/Float(db4Wavelet.count)}), y: db4Wavelet, bounds: CGRect(x: 0, y: -1, width: 4, height: 2))


let o = db4Wavelet.count / 3
//let p0 = db4Wavelet.map({$0*db4[0]}) + [Float](count: 3*o, repeatedValue: 0)
//let p1 = [Float](count: 1*o, repeatedValue: 0)+db4Wavelet.map({$0*db4[1]}) + [Float](count: 2*o, repeatedValue: 0)
//let p2 = [Float](count: 2*o, repeatedValue: 0)+db4Wavelet.map({$0*db4[2]}) + [Float](count: 1*o, repeatedValue: 0)
//let p3 = [Float](count: 3*o, repeatedValue: 0)+db4Wavelet.map({$0*db4[3]})

let p0 = db4Wavelet.map({$0*0.2}) + [Float](repeating: 0, count: 3*o)
let p1 = [Float](repeating: 0, count: 1*o)+db4Wavelet.map({$0*0.4}) + [Float](repeating: 0, count: 2*o)
let p2 = [Float](repeating: 0, count: 2*o)+db4Wavelet.map({$0*0.6}) + [Float](repeating: 0, count: 1*o)
let p3 = [Float](repeating: 0, count: 3*o)+db4Wavelet.map({$0*0.8})

let summandCount = 2 * db4Wavelet.count
let xArray = Array(0..<summandCount).map({Float($0)*3/Float(summandCount)})

let p0p = QuickLinesPlot(x: xArray, y: p0, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//p0p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF0.pdf")

let p1p = QuickLinesPlot(x: xArray, y: p1, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//p1p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF1.pdf")

let p2p = QuickLinesPlot(x: xArray, y: p2, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//p2p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF2.pdf")

let p3p = QuickLinesPlot(x: xArray, y: p3, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//p3p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF3.pdf")

let s1 = zip(p0, p1).map({$0.0+$0.1})
let s1p = QuickLinesPlot(x: xArray, y: s1, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let s2 = zip(s1, p2).map({$0.0+$0.1})
let s2p = QuickLinesPlot(x: xArray, y: s2, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let s3 = zip(s2, p3).map({$0.0+$0.1})
let s3p = QuickLinesPlot(x: xArray, y: s3, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
//s3p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/summedDB4WaveletW.pdf")

//let c1 = newFilterApproximation([1], coefficients: db4)
//let c1y = Array(0..<c1.count).map({Float($0)/2})
//let c1p = QuickLinesPlot(x: c1y, y: c1, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
////c1p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4FilterC1.pdf")
//
//let c2 = newFilterApproximation(c1, coefficients: db4)
//let c2y = Array(0..<c2.count).map({Float($0)/4})
//let c2p = QuickLinesPlot(x: c2y, y: c2, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
////c2p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4FilterC2.pdf")
//
//let c3 = newFilterApproximation(c2, coefficients: db4)
//let c3y = Array(0..<c3.count).map({Float($0)/8})
//let c3p = QuickLinesPlot(x: c3y, y: c3, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
////c3p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4FilterC3.pdf")
//
//let c4 = newFilterApproximation(c3, coefficients: db4)
//let c4y = Array(0..<c4.count).map({Float($0)/16})
//let c4p = QuickLinesPlot(x: c4y, y: c4, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
////c4p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db4FilterC4.pdf")
//
//let spectrum = FIRFilter(coefficients: db4)
//let v = Array(0..<99).map({(Float($0)/100)})
//let fr = v.map({spectrum.frequencyResponse(6.28*$0)})
//let impulseResponse = fr.map({$0.r*$0.r + $0.i*$0.i})
//impulseResponse
//QuickArrayPlot(array: impulseResponse)
//
//QuickArrayPlot(array: db6)
//let db6Wavelet = createWaveletFromCoefficients(db6, levels: 6)
//QuickArrayPlot(array: db6Wavelet)

//test comment
