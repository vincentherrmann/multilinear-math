//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

let db2: [Float] = [1, 1]
let db4: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
let db6: [Float] = [0.3326705529509569, 0.8068915093133388, 0.4598775021193313, -0.13501102001039084, -0.08544127388224149, 0.035226291882100656].map({$0 * pow(2, 0.5)})
let db8: [Float] = [0.23037781330885523, 0.7148465705525415, 0.6308807679295904, -0.02798376941698385, -0.18703481171888114, 0.030841381835986965, 0.032883011666982945, -0.010597401784997278].map({$0 * pow(2, 0.5)})

let dbWavelet = Array(createWaveletFromCoefficients(db4, levels: 6).dropLast())
QuickArrayPlot(array: dbWavelet)

let dbReverse = Array(createWaveletFromCoefficients(db4.reversed(), levels: 6).dropLast())
QuickArrayPlot(array: dbReverse)

let waveletLength = 3
let waveletCount = 6
let o = dbWavelet.count / waveletLength
let viewLength = waveletLength + (waveletCount-1)

let p0 = dbWavelet + [Float](repeating: 0, count: 5*o)
let p1 = [Float](repeating: 0, count: 1*o)+dbWavelet + [Float](repeating: 0, count: 4*o)
let p2 = [Float](repeating: 0, count: 2*o)+dbWavelet + [Float](repeating: 0, count: 3*o)
let p3 = [Float](repeating: 0, count: 3*o)+dbWavelet + [Float](repeating: 0, count: 2*o)
let p4 = [Float](repeating: 0, count: 4*o)+dbWavelet + [Float](repeating: 0, count: 1*o)
let p5 = [Float](repeating: 0, count: 5*o)+dbWavelet

//let summandCount = 2 * dbWavelet.count
let viewValues = o * viewLength
let xArray = Array(0..<viewValues).map({Float(viewLength*$0)/Float(viewValues)})


let f = xArray.map({0.4*$0 - 1.7})
let fPlot = QuickLinesPlot(x: xArray, y: f, bounds: CGRect(x: 0, y: -2, width: viewLength, height: 4))
//fPlot.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4SynthFunction.pdf")


let scaleFactor = 10 / Float(f.count)

let a0 = zip(f, p0).map({$0.0*$0.1}).reduce(1, {$0+$1})*scaleFactor
a0
let a1 = zip(f, p1).map({$0.0*$0.1}).reduce(1, {$0+$1})*scaleFactor
a1
let a2 = zip(f, p2).map({$0.0*$0.1}).reduce(1, {$0+$1})*scaleFactor
a2
let a3 = zip(f, p3).map({$0.0*$0.1}).reduce(1, {$0+$1})*scaleFactor
a3
let a4 = zip(f, p4).map({$0.0*$0.1}).reduce(1, {$0+$1})*scaleFactor
a4
let a5 = zip(f, p5).map({$0.0*$0.1}).reduce(1, {$0+$1})*scaleFactor
a5

let r0 = dbReverse.map({$0*a0}) + [Float](repeating: 0, count: 5*o)
let r1 = [Float](repeating: 0, count: 1*o)+dbReverse.map({$0*a1}) + [Float](repeating: 0, count: 4*o)
let r2 = [Float](repeating: 0, count: 2*o)+dbReverse.map({$0*a2}) + [Float](repeating: 0, count: 3*o)
let r3 = [Float](repeating: 0, count: 3*o)+dbReverse.map({$0*a3}) + [Float](repeating: 0, count: 2*o)
let r4 = [Float](repeating: 0, count: 4*o)+dbReverse.map({$0*a4}) + [Float](repeating: 0, count: 1*o)
let r5 = [Float](repeating: 0, count: 5*o)+dbReverse.map({$0*a5})

let p0p = QuickLinesPlot(x: xArray, y: r0, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//p0p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF0.pdf")

let p1p = QuickLinesPlot(x: xArray, y: r1, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//p1p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF1.pdf")

let p2p = QuickLinesPlot(x: xArray, y: r2, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//p2p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF2.pdf")

let p3p = QuickLinesPlot(x: xArray, y: r3, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//p3p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF3.pdf")

let p4p = QuickLinesPlot(x: xArray, y: r4, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//p4p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4WaveletF4.pdf")

let p5p = QuickLinesPlot(x: xArray, y: r5, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//p5p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db6WaveletF5.pdf")



let s1 = zip(r0, r1).map({$0.0+$0.1})
let s1p = QuickLinesPlot(x: xArray, y: s1, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
let d1p = QuickDifferencePlot(x: xArray, y1: r0, y2: s1, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
d1p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4Synth1.pdf")

let s2 = zip(s1, r2).map({$0.0+$0.1})
let s2p = QuickLinesPlot(x: xArray, y: s2, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
let d2p = QuickDifferencePlot(x: xArray, y1: s1, y2: s2, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
d2p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4Synth2.pdf")

let s3 = zip(s2, r3).map({$0.0+$0.1})
let s3p = QuickLinesPlot(x: xArray, y: s3, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
let d3p = QuickDifferencePlot(x: xArray, y1: s2, y2: s3, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
d3p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4Synth3.pdf")

let s4 = zip(s3, r4).map({$0.0+$0.1})
let s4p = QuickLinesPlot(x: xArray, y: s4, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
let d4p = QuickDifferencePlot(x: xArray, y1: s3, y2: s4, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
d4p.plotView.writeAsPdfTo(path: "/Users/vincentherrmann/Documents/Projekte/Wavelets/db4Synth4.pdf")

let s5 = zip(s4, r5).map({$0.0+$0.1})
let s5p = QuickLinesPlot(x: xArray, y: s5, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
let d5p = QuickDifferencePlot(x: xArray, y1: s4, y2: s5, bounds: CGRect(x: 0, y: -3, width: viewLength, height: 4))
//d5p.plotView.writeAsPdfTo("/Users/vincentherrmann/Documents/Projekte/Wavelets/db6Synth5.pdf")
print("finished")
