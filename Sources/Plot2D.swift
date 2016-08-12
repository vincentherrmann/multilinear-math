//
//  Plot2D.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 11.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Foundation

public protocol Bounded {
    var xMin: CGFloat {get}
    var yMin: CGFloat {get}
    var xMax: CGFloat {get}
    var yMax: CGFloat {get}
    var plotBounds: CGRect {get}
}
public extension Bounded {
//    var xMin: CGFloat {
//        get {
//            return bounds.minX
//        }
//    }
//    var yMin: CGFloat {
//        get {
//            return bounds.minY
//        }
//    }
//    var xMax: CGFloat {
//        get {
//            return bounds.maxX
//        }
//    }
//    var yMax: CGFloat {
//        get {
//            return bounds.maxY
//        }
//    }
    var xRange: CGFloat {
        get {
            return xMax - xMin
        }
    }
    var yRange: CGFloat {
        get {
            return yMax - yMin
        }
    }
    var plotBounds: CGRect {
        get {
            return CGRect(x: xMin, y: yMin, width: xRange, height: yRange)
        }
    }
}
public protocol MutableBounded: Bounded {
    var xMin: CGFloat {get set}
    var yMin: CGFloat {get set}
    var xMax: CGFloat {get set}
    var yMax: CGFloat {get set}
}
public extension MutableBounded {
    var plotBounds: CGRect {
        get {
            return CGRect(x: xMin, y: yMin, width: xRange, height: yRange)
        }
        
        set(newPlotBounds) {
            xMin = newPlotBounds.minX
            yMin = newPlotBounds.minY
            xMax = newPlotBounds.maxX
            yMax = newPlotBounds.maxY
        }
    }
    
    mutating func setPlotBounds(xMin: CGFloat, xMax: CGFloat, yMin: CGFloat, yMax: CGFloat) {
        self.xMin = xMin
        self.yMin = yMin
        self.xMax = xMax
        self.yMax = yMax
    }
}

public protocol Plots2D: MutableBounded {
    var plots: [Plottable2D] {get set}
    
    func fitinPlot(thisPlot: Plottable2D)
    func updatePlot()
    mutating func addPlot(thisPlot: Plottable2D)
}
public extension Plots2D {
    mutating func addPlot(thisPlot: Plottable2D) {
        fitinPlot(thisPlot)
        plots.append(thisPlot)
    }
    
    func updatePlot() {
        for plot in plots {
            fitinPlot(plot)
        }
    }
    
    mutating func adaptBoundsTo(targetBounds: NSRect) {
        print("")
        print("set new bounds: \(targetBounds)")
        plotBounds = targetBounds
    }
}

public protocol Plottable2D: Bounded {
    func draw()
    func createTransformedVersion(scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat)
}

public extension Plottable2D {
    public func fitInto(newBounds: CGRect) {
        let scaleX = plotBounds.width / newBounds.width
        let scaleY = plotBounds.height / newBounds.height
        let translateX = -plotBounds.minX * scaleX + newBounds.minX
        let translateY = -plotBounds.minY * scaleY + newBounds.minY
        createTransformedVersion(scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
    }
}
