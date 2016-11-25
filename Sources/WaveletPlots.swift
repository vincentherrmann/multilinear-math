//
//  WaveletPlots.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 07.11.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Cocoa

public struct FastWaveletPlot: CustomPlaygroundQuickLookable {
    public var waveletView: WaveletView
    
    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        get {
            return PlaygroundQuickLook.view(waveletView)
        }
    }
    
    public init(packets: [WaveletPacket]) {
        waveletView = WaveletView(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        var bounds: CGRect? = nil
        for i in 0..<packets.count {
            let thisPacket = packets[i]
            let plot = WaveletPacketPlot(packet: thisPacket)
            waveletView.addPlottable(plot)
            if bounds == nil {
                bounds = plot.plotBounds
            } else {
                bounds = bounds!.join(with: plot.plotBounds)
            }
        }
        waveletView.setPlottingBounds(bounds!)
        waveletView.updatePlotting()
    }
}

public class WaveletView: PlotView2D {
    override public var screenBounds: CGRect {
        get {
            return CGRect(origin: CGPoint(x: 0, y: 0), size: frame.size)
        }
    }
    var maxValue: CGFloat = CGFloat.leastNormalMagnitude
    
    public override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        plottingBounds = NSRect(x: 0, y: 0, width: 32, height: 1)
    }
    
    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        for thisPlot in plots {
            thisPlot.draw()
        }
    }
    
    public func updatePlotting() {
        maxValue = CGFloat.leastNormalMagnitude
        for thisPlot in plots {
            if let w = thisPlot as? WaveletPacketPlot {
                if let m = w.packet.values.max() {
                    if CGFloat(m) > maxValue {maxValue = CGFloat(m)}
                }
            }
        }
        
        super.updatePlotting()
    }
}

public class WaveletPacketPlot: PlottableIn2D {
    public var packet: WaveletPacket
    var tiles: [CGRect] = []
    var maxValue: CGFloat = 1
    public var plotBounds: CGRect {
        get {
            let yMinP = CGFloat(packet.position) / CGFloat(packet.length)
            let height = 1 / CGFloat(packet.length)
            let width = CGFloat(packet.length * packet.values.count)
            let bounds = CGRect(x: 0, y: yMinP, width: width, height: height)
            return bounds
        }
    }
    
    public init(packet: WaveletPacket) {
        self.packet = packet
    }
    
    public func draw() {
        for i in 0..<packet.values.count {
            if let color = #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).blended(withFraction: CGFloat(packet.values[i]) / maxValue, of: #colorLiteral(red: 1, green: 1, blue: 1, alpha: 1)) {
                color.setFill()
            } else {
                #colorLiteral(red: 0, green: 0, blue: 0, alpha: 1).setFill()
            }
            
            let path = NSBezierPath(rect: tiles[i])
            path.fill()
        }
    }
    
    public func fitTo(_ plotting: Plotting2D) {
        let t = plotting.transformFromPlotToScreen
        
        let yMin = (plotBounds.minY + t.translateY) * t.scaleY
        let height = plotBounds.height * t.scaleY

        let xStart = t.translateX * t.scaleX
        let width = CGFloat(packet.length) * t.scaleX
        
        var p = xStart
        tiles = []
        for _ in 0..<packet.values.count {
            tiles.append(CGRect(x: p, y: yMin, width: width, height: height))
            p += width
        }
        
        if let view = plotting as? WaveletView {
            maxValue = view.maxValue
        } else {
            maxValue = 1
        }
        
    }
}
