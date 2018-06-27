//
//  PlotView2D.swift
//  MultilinearMath
//
//  Created by Vincent Herrmann on 11.08.16.
//  Copyright © 2016 Vincent Herrmann. All rights reserved.
//

import Cocoa

let colors: [NSColor] = [.blue, .red, .green, .orange, .magenta, .brown, .yellow, .cyan]

public struct QuickArrayPlot: CustomPlaygroundQuickLookable {
    public var plotView: PlotView2D

    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        get {
            return PlaygroundQuickLook.view(plotView)
        }
    }

    public init(array: [Float]...) {
        plotView = PlotView2D(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        var bounds: CGRect? = nil
        for i in 0..<array.count {
            let thisArray = array[i]
            let plot = LinePlot(withValueArray: thisArray.map({CGFloat($0)}))
            plot.color = colors[i]
            plotView.addPlottable(plot)
            if bounds == nil {
                bounds = plot.plotBounds
            } else {
                bounds = bounds!.join(with: plot.plotBounds)
            }
        }
        plotView.setPlottingBounds(bounds!)
        let xAxis = PlotAxis(direction: .x)
        let yAxis = PlotAxis(direction: .y)
        plotView.addPlottable(xAxis)
        plotView.addPlottable(yAxis)
        plotView.updatePlotting()
    }

//    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
//        return PlaygroundQuickLook.view(plotView)
//    }
}

public struct QuickLinesPlot: CustomPlaygroundQuickLookable {
    public var plotView: PlotView2D

    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        get {
            return PlaygroundQuickLook.view(plotView)
        }
    }

    public init(x: [Float], y: [Float]..., bounds: CGRect? = nil) {
        plotView = PlotView2D(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        var dBounds: CGRect? = nil
        for i in 0..<y.count {
            let thisY = y[i]
            let plot = LinePlot(withPoints: zip(x, thisY).map({CGPoint(x: CGFloat($0.0), y: CGFloat($0.1))}))
            plot.color = colors[i]
            plotView.addPlottable(plot)
            if dBounds == nil {
                dBounds = plot.plotBounds
            } else {
                dBounds = dBounds!.join(with: plot.plotBounds)
            }
        }
        let theseBounds = bounds != nil ? bounds! : dBounds!
        plotView.setPlottingBounds(theseBounds)
        let xAxis = PlotAxis(direction: .x)
        let yAxis = PlotAxis(direction: .y)
        plotView.addPlottable(xAxis)
        plotView.addPlottable(yAxis)
        plotView.updatePlotting()
    }

//    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
//        return PlaygroundQuickLook.view(plotView)
//    }
}

public struct QuickDifferencePlot: CustomPlaygroundQuickLookable {
    public var plotView: PlotView2D

    public var customPlaygroundQuickLook: PlaygroundQuickLook {
        get {
            return PlaygroundQuickLook.view(plotView)
        }
    }

    public init(x: [Float], y1: [Float], y2: [Float], bounds: CGRect? = nil) {
        plotView = PlotView2D(frame: NSRect(x: 0, y: 0, width: 300, height: 200))
        let xPositions = x + x.reversed()
        let yPositions = y1 + y2.reversed()
        let plot = ClosedLinePlot(withPoints: zip(xPositions, yPositions).map({CGPoint(x: CGFloat($0.0), y: CGFloat($0.1))}))
        plotView.addPlottable(plot)
        let theseBounds = bounds != nil ? bounds! : plot.plotBounds
        plotView.setPlottingBounds(theseBounds)
        let xAxis = PlotAxis(direction: .x)
        let yAxis = PlotAxis(direction: .y)
        plotView.addPlottable(xAxis)
        plotView.addPlottable(yAxis)
        plotView.updatePlotting()
    }

//    public func customPlaygroundQuickLook() -> PlaygroundQuickLook {
//        return PlaygroundQuickLook.view(plotView)
//    }
}


public class PlotView2D: NSView, Plotting2D {

    public var plots: [PlottableIn2D] = []
    public var plottingBounds: NSRect = NSRect(x: 0, y: -2, width: 5, height: 4)
    public var borderSize: CGSize = CGSize(width: 25, height: 25)
    public var screenBounds: CGRect {
        get {
            let rect = CGRect(x: borderSize.width,
                              y: borderSize.height,
                              width: frame.width - 2*borderSize.width,
                              height: frame.height - 2*borderSize.height)
            return rect
        }
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        let thisContext = NSGraphicsContext.current()
        thisContext?.shouldAntialias = true
        thisContext?.cgContext.setShouldSmoothFonts(true)


        for thisPlot in plots {
            thisPlot.draw()
        }
    }

    public func writeAsPdfTo(path: String) {
        let pdfData = self.dataWithPDF(inside: bounds)
        do {
            try pdfData.write(to: URL(fileURLWithPath: path))
        } catch {
            print("could not write file to \(path)")
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
    public struct PlotLabel {
        var text: NSMutableAttributedString
        var position: CGPoint
        var size: Float
    }
    public var direction: PlotAxisDirection
    public var tickSize: TickSize
    public var path: NSBezierPath = NSBezierPath()
    public var labels: [PlotLabel] = []
    ///The maximum distance in pixels between automatic ticks
    public var maxPointsBetweenTicks: CGFloat = 80
    public var tickLength: CGFloat = 5
    public var labelAttributes = [ NSFontAttributeName: NSFont(name: "Times New Roman", size: 12.0)! ]
    var color = NSColor.black
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

    public func fitTo(_ plotting: Plotting2D) {
        createAxis(plotView: plotting)
    }

    public func draw() {
        color.setStroke()
        path.stroke()

        for label in labels {
            label.text.draw(at: label.position)
        }
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
        let startPoint: CGPoint = plotView.convertFromPlotToScreen(CGPoint(a: plotView.plottingBounds.origin.value(dim: axisDim), b: 0, aDimension: axisDim))
        let farEdge = CGPoint(x: plotView.plottingBounds.maxX, y: plotView.plottingBounds.maxY)
        let endPoint: CGPoint = plotView.convertFromPlotToScreen(CGPoint(a: farEdge.value(dim: axisDim), b: 0, aDimension: axisDim))
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
            tickDistance = findAutomaticTickSize(maximumSize: maxPlotTick) * scaleToScreenFactor
        }

        //axis
        path.move(to: startPoint)
        path.line(to: endPoint)
        //arrow
        path.move(to: CGPoint(a: endPoint.value(dim: axisDim) - 5, b: endPoint.value(dim: otherDim) - 5, aDimension: axisDim))
        path.line(to: endPoint)
        path.line(to: CGPoint(a: endPoint.value(dim: axisDim) - 5, b: endPoint.value(dim: otherDim) + 5, aDimension: axisDim))

        //ticks
        let distanceToZero = startPoint.value(dim: axisDim) - zeroPoint.value(dim: axisDim)
        let tickModulo = distanceToZero.truncatingRemainder(dividingBy: tickDistance) //distanceToZero % tickDistance
        let zeroLine = zeroPoint.value(dim: otherDim)
        var currentTickPosition = startPoint.value(dim: axisDim) + (tickDistance - tickModulo)
        while currentTickPosition < endPoint.value(dim: axisDim) {
            path.move(to: CGPoint(a: currentTickPosition, b: zeroLine - tickLength, aDimension: axisDim))
            path.line(to: CGPoint(a: currentTickPosition, b: zeroLine, aDimension: axisDim))

            let value = plotView.convertFromScreenToPlot(CGPoint(a: currentTickPosition, b: 0, aDimension: axisDim)).value(dim: axisDim)
            let string = String(format: numberFormattingString, value)
            let size: Float = 10
            let s = NSMutableAttributedString(string: string, attributes: labelAttributes)
            let position: CGPoint
            if axisDim == .x {
                position = CGPoint(a: currentTickPosition - 0.5*s.size().width, b: zeroLine - s.size().height - 5, aDimension: axisDim)
            } else {
                position = CGPoint(a: currentTickPosition - 0.5*s.size().height, b: zeroLine - s.size().width - 8, aDimension: axisDim)
            }

            labels.append(PlotLabel(text: s, position: position, size: size))

            currentTickPosition += tickDistance
        }


    }

    var numberFormattingString: String = "%.0f"

    func findAutomaticTickSize(maximumSize: CGFloat, possibleSteps: [CGFloat] = [1.0, 2.0, 5.0]) -> CGFloat {
        let scale = floor(log10(maximumSize))
        let factor = pow(10, scale)
        var stepSize: CGFloat = 1
        for thisStep in possibleSteps.sorted(by: {$0 > $1}) {
            let thisSize = thisStep * factor
            if(maximumSize >= thisSize) {
                stepSize = thisSize
                break
            } else {
                continue
            }
        }
        //print("step size: \(stepSize)")

        if scale < 0 {
            let s = Int(-scale)
            numberFormattingString = "%.\(s)f"
        } else {
            numberFormattingString = "%.0f"
        }

        return stepSize
    }
}

public class LinePlot: PlottableIn2D {
    var points: [CGPoint] = []

    var path: NSBezierPath = NSBezierPath()
    var color = NSColor.black

    var lineWidth: CGFloat {
        get {
            return path.lineWidth
        }
        set(newWidth) {
            path.lineWidth = newWidth
        }
    }
    public var xMin: CGFloat {
        get {return points.map({$0.x}).min(by: {$0 < $1})!}
    }
    public var yMin: CGFloat {
        get {return points.map({$0.y}).min(by: {$0 < $1})!}
    }
    public var xMax: CGFloat {
        get {return points.map({$0.x}).max(by: {$0 < $1})!}
    }
    public var yMax: CGFloat {
        get {return points.map({$0.y}).max(by: {$0 < $1})!}
    }
    public var plotBounds: CGRect {
        get {return CGRect(x: xMin, y: yMin, width: xMax-xMin, height: yMax-yMin)}
    }

    public init(withPoints: [CGPoint]) {
        self.points = withPoints
    }
    public init(withValueArray: [CGFloat], xStepSize: CGFloat = 1) {
        pointsFromValueArray(values: withValueArray, xStep: xStepSize)
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
        path.move(to: points[0])
        for i in 1..<pointCount {
            path.line(to: points[i])
        }
    }

    public func draw() {
        color.setStroke()
        path.stroke()
    }

    public func fitTo(_ plotting: Plotting2D) {
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
        pointsFromValueArray(values: withValueArray, xStep: xStepSize)
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

public class ClosedLinePlot: LinePlot {
    override public func createGraph() {
        super.createGraph()
        path.close()
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

        path.move(to: points[0])
        var slopeX: CGFloat = 0.0
        var slopeY: CGFloat = 0.0
        var cp1 = points[0]

        for i in 1..<pointCount-1 {
            //the control points are calculated from the slope between the neighbouring points
            slopeX = (points[i+1].x - points[i-1].x) * 0.5
            slopeY = (points[i+1].y - points[i-1].y) * 0.5
            let cp2 = CGPoint(x: points[i].x - (1.0/3.0)*slopeX, y: points[i].y - (1.0/3.0)*slopeY)
            path.curve(to: points[i], controlPoint1: cp1, controlPoint2: cp2)
            cp1 = CGPoint(x: points[i].x + (1.0/3.0)*slopeX, y: points[i].y + (1.0/3.0)*slopeY)
        }
        //first and last point only have one significant control point
        path.curve(to: points[pointCount-1], controlPoint1: cp1, controlPoint2: points[pointCount-1])
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
    func transform(scaleX: CGFloat, scaleY: CGFloat, translateX: CGFloat, translateY: CGFloat) {
        //translates and scales path (in this order)

        var transform = AffineTransform() //NSAffineTransform()
        transform.translate(x: translateX, y: translateY)
        //transform.translateX(by: translateX, yBy:translateY)
        //transform.scaleX(by: scaleX, yBy: scaleY)
        transform.scale(x: scaleX, y: scaleY)
//        print("translateY: \(translateY)")
//        print("transform: \(transform.description)")
        self.transform(using: transform)
//        print("path bounds after transform: \(bounds)")
    }

}
