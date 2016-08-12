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
        plotView.addPlot(plot)
        plotView.adaptBoundsTo(plot.plotBounds)
        plotView.fitinPlot(plot)
    }
    
    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
        return PlaygroundQuickLook.View(plotView)
    }
}

public class PlotView2D: NSView, Plots2D {
    
    public var plots: [Plottable2D] = []
    public var xMin: CGFloat = 0.0
    public var yMin: CGFloat = -2.0
    public var xMax: CGFloat = 5.0
    public var yMax: CGFloat = 2.0
    public var borderSize: CGSize = CGSize(width: 10, height: 10)
    public var displayRect: CGRect {
        get {
            let disRect = CGRect(x: borderSize.width,
                                 y: borderSize.height,
                                 width: frame.width - 2*borderSize.width,
                                 height: frame.height - 2*borderSize.height)
            return disRect
        }
    }
    public var transform: (scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat) {
        get {
            let scaleX = displayRect.width / plotBounds.width
            let scaleY = displayRect.height / plotBounds.height
            let translateX = -plotBounds.minX * scaleX + displayRect.minX
            let translateY = -plotBounds.minY * scaleY + displayRect.minY
            return (scaleX, scaleY, translateX, translateY)
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
    
    public func getPixelPosition(position: CGPoint) -> CGPoint {
        let t = transform
        return CGPoint(x: position.x + t.translateX, y: position.y + t.translateY)
    }
    
    public func fitinPlot(thisPlot: Plottable2D) {
        Swift.print("Plot visible rect: \(displayRect)")
        let t = transform
        thisPlot.createTransformedVersion(t.scaleX, scaleY: t.scaleY, translateX: t.translateX, translateY: t.translateY)
    }
}

public class PlotAxis: Plottable2D {
    public enum PlotAxisDirection {
        case x
        case y
    }
    public enum TickSize {
        case auto
        case fixed(CGFloat)
    }
    public var plotView: PlotView2D
    public var direction: PlotAxisDirection
    public var tickSize: TickSize
    public var path: NSBezierPath = NSBezierPath()
    ///The maximum distance in pixels between automatic ticks
    public var automaticTickMaxDistance: CGFloat = 20
    public var tickLength: CGFloat = 5
    
    public init(plotView: PlotView2D, direction: PlotAxisDirection, tickSize: TickSize = .auto) {
        self.plotView = plotView
        self.direction = direction
        self.tickSize = tickSize
    }
    
    public func createAxis() {
        path = NSBezierPath()
        let min, max, points: CGFloat
        switch direction {
        case .y:
            min = plotView.plotBounds.minY
            max = plotView.plotBounds.maxY
            points = plotView.frame.height
        default:
            min = plotView.plotBounds.minX
            max = plotView.plotBounds.maxX
            points = plotView.frame.width
        }
        let distance = max - min
        
        let actualTickSize: CGFloat
        switch tickSize {
        case .fixed(let size):
            actualTickSize = size
        default:
            
            let maxTickSize = distance * (automaticTickMaxDistance / points)
            actualTickSize = findAutomaticTickSize(maxTickSize)
        }
        
        path.moveToPoint(plotView.getPixelPosition(CGPoint(x: min, y: 0)))
        path.lineToPoint(plotView.getPixelPosition(CGPoint(x: max, y: 0)))
        
        for
        
    }

    func findAutomaticTickSize(maximumSize: CGFloat, possibleSteps: [CGFloat] = [1.0, 2.0, 5.0]) -> CGFloat {
        let scale = floor(log10(maximumSize))
        let factor = pow(10, scale)
        var stepSize: CGFloat = 1
        for thisStep in possibleSteps {
            let thisSize = thisStep * factor
            if(maximumSize >= thisSize) {
                stepSize = thisSize
                break
            } else {
                continue
            }
        }
        return stepSize
    }
}

public class LinePlot: Plottable2D {
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
        get {
            return points.map({$0.x}).minElement({$0 < $1})!
        }
    }
    public var yMin: CGFloat {
        get {
            return points.map({$0.y}).minElement({$0 < $1})!
        }
    }
    public var xMax: CGFloat {
        get {
            return points.map({$0.x}).maxElement({$0 < $1})!
        }
    }
    public var yMax: CGFloat {
        get {
            return points.map({$0.y}).maxElement({$0 < $1})!
        }
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
    
    public func createTransformedVersion(scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat) {
        //first, create the path to get the original scaling
        createGraph()
        
        //transform it
        print("transform path with scale: \(scaleX), scaleY: \(scaleY), transX: \(translateX), transY: \(translateY)")
        path.transform(scaleX: scaleX, scaleY: scaleY, translateX: translateX, translateY: translateY)
        print("new path bounds: \(path.bounds), plot bounds: \(plotBounds)")
    }
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
