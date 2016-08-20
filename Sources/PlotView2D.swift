//
//  PlotView2D.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 11.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Cocoa

public struct QuickArrayPlot: CustomPlaygroundQuickLookable {
    public var plotView: PlotView2D
    
    public init(array: [Float]) {
        plotView = PlotView2D(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        var plot = LinePlot(withValueArray: array.map({CGFloat($0)}))
        plotView.addPlottable(plot)
        plotView.setPlottingBounds(plot.plotBounds)
        var xAxis = PlotAxis(direction: .x)
        var yAxis = PlotAxis(direction: .y)
        plotView.addPlottable(xAxis)
        plotView.addPlottable(yAxis)
        plotView.updatePlotting()
    }
    
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        return PlaygroundQuickLook.View(plotView)
    }
}

public class PlotView2D: NSView, Plotting2D {
    
    public var plots: [PlottableIn2D] = []
    public var plottingBounds: NSRect = NSRect(x: 0, y: -2, width: 5, height: 4)
    public var borderSize: CGSize = CGSize(width: 10, height: 10)
    public var screenBounds: CGRect {
        get {
            let rect = CGRect(x: borderSize.width,
                              y: borderSize.height,
                              width: frame.width - 2*borderSize.width,
                              height: frame.height - 2*borderSize.height)
            return rect
        }
    }
    
    override public func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        
        let thisContext = NSGraphicsContext.currentContext()
        thisContext?.shouldAntialias = true
        
        for thisPlot in plots {
            thisPlot.draw()
        }
    }
}

public class PlotAxis: PlottableIn2D {
    public enum PlotAxisDirection {
        case x
        case y
    }
    public enum TickSize {
        case auto
        case fixed(CGFloat)
    }
    public var direction: PlotAxisDirection
    public var tickSize: TickSize
    public var path: NSBezierPath = NSBezierPath()
    ///The maximum distance in pixels between automatic ticks
    public var maxPointsBetweenTicks: CGFloat = 50
    public var tickLength: CGFloat = 5
    var color = NSColor.blackColor()
    var lineWidth: CGFloat {
        get {
            return path.lineWidth
        }
        set(newWidth) {
            path.lineWidth = newWidth
        }
    }
    
    public init(direction: PlotAxisDirection, tickSize: TickSize = .auto) {
        self.direction = direction
        self.tickSize = tickSize
    }
    
    public func fitTo(plotting: Plotting2D) {
        createAxis(plotting)
    }
    
    public func draw() {
        color.setStroke()
        path.stroke()
    }
    
    public func createAxis(plotView: Plotting2D) {
        path = NSBezierPath()
        
        let axisDim, otherDim: CGPoint.Dimension
        switch direction {
        case .y:
            axisDim = .y
            otherDim = .x
        default:
            axisDim = .x
            otherDim = .y
        }

        let scaleToScreenFactor: CGFloat = axisDim == .x ? plotView.transformFromPlotToScreen.scaleX : plotView.transformFromPlotToScreen.scaleY
        //points on screen
        let startPoint: CGPoint = plotView.convertFromPlotToScreen(CGPoint(a: plotView.plottingBounds.origin.value(axisDim), b: 0, aDimension: axisDim))
        let farEdge = CGPoint(x: plotView.plottingBounds.maxX, y: plotView.plottingBounds.maxY)
        let endPoint: CGPoint = plotView.convertFromPlotToScreen(CGPoint(a: farEdge.value(axisDim), b: 0, aDimension: axisDim))
        let zeroPoint: CGPoint = plotView.convertFromPlotToScreen(CGPoint(x: 0, y: 0))
        
        print("axis start position: \(startPoint)")
        print("axis end position: \(endPoint)")
        
        //find tick distance
        let tickDistance: CGFloat
        switch tickSize {
        case .fixed(let size):
            tickDistance = size * scaleToScreenFactor
        default:
            let maxPlotTick = maxPointsBetweenTicks / scaleToScreenFactor
            tickDistance = findAutomaticTickSize(maxPlotTick) * scaleToScreenFactor
        }
        
        //axis
        path.moveToPoint(startPoint)
        path.lineToPoint(endPoint)
        //arrow
        path.moveToPoint(CGPoint(a: endPoint.value(axisDim) - 5, b: endPoint.value(otherDim) - 5, aDimension: axisDim))
        path.lineToPoint(endPoint)
        path.lineToPoint(CGPoint(a: endPoint.value(axisDim) - 5, b: endPoint.value(otherDim) + 5, aDimension: axisDim))
        
        //ticks
        let distanceToZero = startPoint.value(axisDim) - zeroPoint.value(axisDim)
        let tickModulo = distanceToZero % tickDistance
        var currentTickPosition = startPoint.value(axisDim) + (tickDistance - tickModulo)
        while currentTickPosition < endPoint.value(axisDim) {
            path.moveToPoint(CGPoint(a: currentTickPosition, b: zeroPoint.value(otherDim) - tickLength, aDimension: axisDim))
            path.lineToPoint(CGPoint(a: currentTickPosition, b: zeroPoint.value(otherDim), aDimension: axisDim))
            currentTickPosition += tickDistance
        }
        
        
    }

    func findAutomaticTickSize(maximumSize: CGFloat, possibleSteps: [CGFloat] = [1.0, 2.0, 5.0]) -> CGFloat {
        let scale = floor(log10(maximumSize))
        let factor = pow(10, scale)
        var stepSize: CGFloat = 1
        for thisStep in possibleSteps.sort({$0 > $1}) {
            let thisSize = thisStep * factor
            if(maximumSize >= thisSize) {
                stepSize = thisSize
                break
            } else {
                continue
            }
        }
        //print("step size: \(stepSize)")
        return stepSize
    }
}

public class LinePlot: PlottableIn2D {
    var points: [CGPoint] = []
    
    var path: NSBezierPath = NSBezierPath()
    var color = NSColor.blackColor()
    var lineWidth: CGFloat {
        get {
            return path.lineWidth
        }
        set(newWidth) {
            path.lineWidth = newWidth
        }
    }
    public var xMin: CGFloat {
        get {return points.map({$0.x}).minElement({$0 < $1})!}
    }
    public var yMin: CGFloat {
        get {return points.map({$0.y}).minElement({$0 < $1})!}
    }
    public var xMax: CGFloat {
        get {return points.map({$0.x}).maxElement({$0 < $1})!}
    }
    public var yMax: CGFloat {
        get {return points.map({$0.y}).maxElement({$0 < $1})!}
    }
    public var plotBounds: CGRect {
        get {return CGRect(x: xMin, y: yMin, width: xMax-xMin, height: yMax-yMin)}
    }
    
    public init(withPoints: [CGPoint]) {
        self.points = withPoints
    }
    public init(withValueArray: [CGFloat], xStepSize: CGFloat = 1) {
        pointsFromValueArray(withValueArray, xStep: xStepSize)
    }
    
    // create graph from value array
    func pointsFromValueArray(values: [CGFloat], xStep: CGFloat) {
        var xPosition: CGFloat = 0.0
        points = []
        for value in values {
            points.append(CGPoint(x: xPosition, y: value))
            xPosition += xStep
        }
    }
    
    func createGraph() {
        path = NSBezierPath()
        
        let pointCount = points.count
        path.moveToPoint(points[0])
        for i in 1..<pointCount {
            path.lineToPoint(points[i])
        }
    }
    
    public func draw() {
        color.setStroke()
        path.stroke()
    }
    
    public func fitTo(plotting: Plotting2D) {
        //first, create the path to get the original scaling
        createGraph()
        
        let t = plotting.transformFromPlotToScreen
        path.transform(scaleX: t.scaleX, scaleY: t.scaleY, translateX: t.translateX, translateY: t.translateY)
    }
    
//    public func createTransformedVersion(scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat) {
//        //first, create the path to get the original scaling
//        createGraph()
//        
//        //transform it
//        print("transform path with scale: \(scaleX), scaleY: \(scaleY), transX: \(translateX), transY: \(translateY)")
//        path.transform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
//        print("new path bounds: \(path.bounds), plot bounds: \(plottingBounds)")
//    }
}

public class StepPlot: LinePlot {
    override public init(withValueArray: [CGFloat], xStepSize: CGFloat = 0) {
        super.init(withValueArray: [], xStepSize: 1)
        pointsFromValueArray(withValueArray, xStep: xStepSize)
    }
    
    override public init(withPoints: [CGPoint]) {
        super.init(withPoints: [])
        //create additional step points
        points = [withPoints.first!]
        for i in 1..<withPoints.count {
            let lastY = points.last!.y
            let stepPoint = CGPoint(x: withPoints[i].x, y: lastY)
            points.append(stepPoint)
            points.append(withPoints[i])
        }
    }
    override public func pointsFromValueArray(values: [CGFloat], xStep: CGFloat = 1) {
        var xPosition: CGFloat = 0.0
        points = []
        for value in values {
            points.append(CGPoint(x: xPosition, y: value))
            xPosition += xStep
            points.append(CGPoint(x: xPosition, y: value))
        }
    }
}

public class CubicPlot: LinePlot {
    override public func createGraph() {
        path = NSBezierPath()
        
        //Cubic interpolation with two control points between all regular point
        let pointCount = points.count
        if(pointCount < 2) {
            return
        }
        
        path.moveToPoint(points[0])
        var slopeX: CGFloat = 0.0
        var slopeY: CGFloat = 0.0
        var cp1 = points[0]
        
        for i in 1..<pointCount-1 {
            //the control points are calculated from the slope between the neighbouring points
            slopeX = (points[i+1].x - points[i-1].x) * 0.5
            slopeY = (points[i+1].y - points[i-1].y) * 0.5
            let cp2 = CGPoint(x: points[i].x - (1.0/3.0)*slopeX, y: points[i].y - (1.0/3.0)*slopeY)
            path.curveToPoint(points[i], controlPoint1: cp1, controlPoint2: cp2)
            cp1 = CGPoint(x: points[i].x + (1.0/3.0)*slopeX, y: points[i].y + (1.0/3.0)*slopeY)
        }
        //first and last point only have one significant control point
        path.curveToPoint(points[pointCount-1], controlPoint1: cp1, controlPoint2: points[pointCount-1])
    }
}

extension CGPoint {
    enum Dimension {
        case x
        case y
    }
    
    init(a: CGFloat, b: CGFloat, aDimension: Dimension) {
        switch aDimension {
        case .y:
            x = b
            y = a
        default:
            x = a
            y = b
        }
    }
    
    func reverse() -> CGPoint {
        return CGPoint(x: y, y: x)
    }
    
    func value(dim: Dimension) -> CGFloat {
        switch dim {
        case .y:
            return y
        default:
            return x
        }
    }
}

extension NSBezierPath {
    func transform(scaleX scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat) {
        //translates and scales path (in this order)
        
        let transform = NSAffineTransform()
        transform.translateXBy(translateX, yBy:translateY)
        transform.scaleXBy(scaleX, yBy: scaleY)
        print("translateY: \(translateY)")
        print("transform: \(transform.transformStruct)")
        self.transformUsingAffineTransform(transform)
        print("path bounds after transform: \(bounds)")
    }
    
}
