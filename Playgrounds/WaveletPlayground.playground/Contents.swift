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
//let q = QuickLinesPlot(x: Array(0..<db4Wavelet.count).map({Float($0)*4/Float(db4Wavelet.count)}), y: db4Wavelet, bounds: CGRect(x: 0, y: -1, width: 4, height: 2))
//q
let o = db4Wavelet.count / 3
let p0 = db4Wavelet.map({$0*db4[0]}) + [Float](count: 3*o, repeatedValue: 0)
let p1 = [Float](count: 1*o, repeatedValue: 0)+db4Wavelet.map({$0*db4[1]}) + [Float](count: 2*o, repeatedValue: 0)
let p2 = [Float](count: 2*o, repeatedValue: 0)+db4Wavelet.map({$0*db4[2]}) + [Float](count: 1*o, repeatedValue: 0)
let p3 = [Float](count: 3*o, repeatedValue: 0)+db4Wavelet.map({$0*db4[3]})

let summandCount = 2 * db4Wavelet.count
let xArray = Array(0..<summandCount).map({Float($0)*3/Float(summandCount)})

let p0p = QuickLinesPlot(x: xArray, y: p0, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let p1p = QuickLinesPlot(x: xArray, y: p1, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let p2p = QuickLinesPlot(x: xArray, y: p2, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let p3p = QuickLinesPlot(x: xArray, y: p3, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))

let s1 = zip(p0, p1).map({$0.0+$0.1})
let s1p = QuickLinesPlot(x: xArray, y: s1, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let s2 = zip(s1, p2).map({$0.0+$0.1})
let s2p = QuickLinesPlot(x: xArray, y: s2, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))
let s3 = zip(s2, p3).map({$0.0+$0.1})
let s3p = QuickLinesPlot(x: xArray, y: s3, bounds: CGRect(x: 0, y: -2, width: 4, height: 4))

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
