//
//  BoundingProtocols.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 12.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol Bounded2D {
    var boundingRect: NSRect {get}
}

public protocol Plotting2D {
    var plots: [PlottableIn2D] {get set}
    var screenBounds: CGRect {get}
    var plottingBounds: CGRect {get set}
    
    func updatePlotting()
}
public extension Plotting2D {
    typealias Transform = (scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat)
    
    var transformFromPlotToScreen: Transform {
        get {
            return transformParameters(plottingBounds, to: screenBounds)
        }
    }
    
    func transformParameters(from: NSRect, to: NSRect) -> Transform {
        let scaleX = to.width / from.width
        let scaleY = to.height / from.height
        let translateX = -from.minX * scaleX + to.minX
        let translateY = -from.minY * scaleY + to.minY
        return (scaleX, scaleY, translateX, translateY)
    }
    
    func convertFromPlotToScreen(point: CGPoint) -> CGPoint {
        let t = transformParameters(plottingBounds, to: screenBounds)
        return CGPoint(x: point.x * t.scaleX + t.translateX, y: point.y * t.scaleY + t.translateY)
    }
    
    func convertFromScreenToPlot(point: CGPoint) -> CGPoint {
        let t = transformParameters(screenBounds, to: plottingBounds)
        return CGPoint(x: point.x * t.scaleX + t.translateX, y: point.y * t.scaleY + t.translateY)
    }
    
    mutating func addPlottable(newPlottable: PlottableIn2D) {
        newPlottable.fitTo(self)
        plots.append(newPlottable)
    }
    
    func updatePlotting() {
        for plot in plots {
            plot.fitTo(self)
        }
    }
}

public protocol PlottableIn2D {
    func draw()
    func fitTo(plotting: Plotting2D)
}

