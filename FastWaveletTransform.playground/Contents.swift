//: Playground - noun: a place where people can play

import Cocoa
import MultilinearMath

print("start")

let h0: [Float] = [-0.00252085552, 0.0188991688, 0.0510309711, -0.0490589067, 0.0589671507, 0.79271543, 1.0953089, 0.32142213, -0.227000564, -0.0872127786, 0.0242141522, 0.0032346386]
let g0: [Float] = [-0.000504171127, -0.000253534876, 0.0460915789, 0.0190168768, -0.0825454742, 0.388706058, 1.10255682, 0.764762938, -0.0572841614, -0.188405827, -0.00831478462, 0.0161731932]
//
//let cReal = Wavelet(h0: h0, f0: h0.reversed())
//let cImag = Wavelet(h0: g0, f0: g0.reversed())
//
//let count: Int = 1024
//let length: Float = 10
//let xArray = Array(0..<count).map({Float($0) * length / Float(count)})


//let signal = Array(0..<128).map({Float($0)/10}).map({sin(3*$0)})
//var currentSignal = signal
//var analysis: [[Float]] = []
//
//var a: (r0: [Float], r1: [Float]) = ([], [])
//for _ in 0..<4 {
//    a = waveletTransformForwardStep(signal: currentSignal, h0: db4.h0, h1: db4.h1)
//    currentSignal = a.r0
//
//    analysis.append(a.r1)
//}
//
//analysis.append(a.r0)

//let h0: [Float] = [0.6830127, 1.1830127, 0.3169873, -0.1830127]
let wReal = Wavelet(h0: h0, f0: h0.reversed())
let wImag = Wavelet(h0: g0, f0: g0.reversed())

let count: Int = 2048
let sampleFrequency: Float = 1
let frequency: Float = 5.2 //64 * pow(2, 0.5) / 32
let xArray = Array(0..<count).map({Float($0) / sampleFrequency})

let signal = xArray.map({sin(2*Float.pi*frequency*$0)})
let (fSignalReal, fSignalImag) = waveletTransformForwardStep(signal: signal, h0: h0, h1: [0] + h0.dropLast())

var packetsReal: [WaveletPacket] = waveletPacketTransform(signal: fSignalReal, wavelet: wReal, innerCodes: [68])
var packetsImag: [WaveletPacket] = waveletPacketTransform(signal: fSignalImag, wavelet: wImag, innerCodes: [68])

var packetsAbs: [WaveletPacket] = zip(packetsReal, packetsImag).map({
    WaveletPacket(values: zip($0.0.values, $0.1.values).map({($0.0 + i*$0.1).absoluteValue}), code: $0.0.code)})

print("plotting...")

FastWaveletPlot(packets: packetsAbs)

FastWaveletPlot(packets: packetsReal)
FastWaveletPlot(packets: packetsImag)

let dSignal: [Float] = [0] + signal.dropLast()

let (dfSignalReal, dfSignalImag) = waveletTransformForwardStep(signal: dSignal, h0: h0, h1: [0] + h0.dropLast())

var dPacketsReal: [WaveletPacket] = waveletPacketTransform(signal: dfSignalReal, wavelet: wReal, innerCodes: [68])
var dPacketsImag: [WaveletPacket] = waveletPacketTransform(signal: dfSignalImag, wavelet: wImag, innerCodes: [68])

//estimate frequency for code 17
let code: UInt = 68
let oReal = packetsReal.filter({$0.code == code})[0].values
let oImag = packetsImag.filter({$0.code == code})[0].values
let dReal = dPacketsReal.filter({$0.code == code})[0].values
let dImag = dPacketsImag.filter({$0.code == code})[0].values

var estimatedFrequencies: [Float] = []
for n in 0..<oReal.count {
    let oR = oReal[n] / sampleFrequency
    let oI = oImag[n] / sampleFrequency
    let dR = dReal[n] / sampleFrequency
    let dI = dImag[n] / sampleFrequency

    let p1 = ((dR + i*dI) * (oR - i*oI)).imaginary
    let p2 = p1 / (2 * Float.pi * pow((oR + i*oI).absoluteValue, 2))
    estimatedFrequencies.append(p2*sampleFrequency)
}

QuickArrayPlot(array: estimatedFrequencies)

