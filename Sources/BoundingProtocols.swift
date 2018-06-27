//
//  BoundingProtocols.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 12.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol Joinable {
    func join(with: Self...) -> Self

    static func join(_ j: [Self]) -> Self
}

extension CGRect: Joinable {
    public func join(with: CGRect...) -> CGRect {
        let j = [self] + with
        return CGRect.join(j)
    }

    public static func join(_ j: [CGRect]) -> CGRect {
        let minX = j.map({$0.minX}).min()!
        let minY = j.map({$0.minY}).min()!
        let maxX = j.map({$0.maxX}).max()!
        let maxY = j.map({$0.maxY}).max()!
        return CGRect(x: minX, y: minY, width: maxX-minX, height: maxY-minY)
    }
}

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

    func transformParameters(_ from: NSRect, to: NSRect) -> Transform {
        let scaleX = to.width / from.width
        let scaleY = to.height / from.height
        let translateX = -from.minX * scaleX + to.minX
        let translateY = -from.minY * scaleY + to.minY
        return (scaleX, scaleY, translateX, translateY)
    }

    func convertFromPlotToScreen(_ point: CGPoint) -> CGPoint {
        let t = transformParameters(plottingBounds, to: screenBounds)
        return CGPoint(x: point.x * t.scaleX + t.translateX, y: point.y * t.scaleY + t.translateY)
    }

    func convertFromScreenToPlot(_ point: CGPoint) -> CGPoint {
        let t = transformParameters(screenBounds, to: plottingBounds)
        return CGPoint(x: point.x * t.scaleX + t.translateX, y: point.y * t.scaleY + t.translateY)
    }

    mutating func addPlottable(_ newPlottable: PlottableIn2D) {
        newPlottable.fitTo(self)
        plots.append(newPlottable)
    }

    mutating func setPlottingBounds(_ newBounds: NSRect) {
        plottingBounds = newBounds
        if(newBounds.width == 0) {
            plottingBounds.origin.x += -0.5
            plottingBounds.size.width = 1
        }
        if(newBounds.height == 0) {
            plottingBounds.origin.y += -0.5
            plottingBounds.size.height = 1
        }
    }

    func updatePlotting() {
        for plot in plots {
            plot.fitTo(self)
        }
    }
}

public protocol PlottableIn2D {
    func draw()
    func fitTo(_ plotting: Plotting2D)
}
