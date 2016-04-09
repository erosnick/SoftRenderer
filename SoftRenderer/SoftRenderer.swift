//
//  PointCloud.swift
//  SoftRenderer
//
//  Created by Princerin on 4/2/16.
//  Copyright © 2016 Princerin. All rights reserved.
//

import Foundation
import MetalKit

class SoftRenderer {
    
    var view: MTKView
    
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var vertexBuffer: MTLBuffer! = nil
    var vertexColorBuffer: MTLBuffer! = nil
    
    var verticesCount = 0
    
    var verticesData = Array<Float>()
    var tempBufferPointer: UnsafeMutablePointer<Vertex> = nil
    var verticesArrayBufferPointer: UnsafeMutablePointer<Vertex> = nil
    
    var verticesArray = Array<Vertex>()
    
    var starField =  Array<Vertex>()
    
    var avaliableResourceSemphore: dispatch_semaphore_t
    
    init(viewController: GameViewController) {
        
        self.verticesCount = WindowWidth * WindowHeight
        
        device = MTLCreateSystemDefaultDevice()
        
        // setup view properties
        self.view = viewController.view as! MTKView
        self.view.device = device
        self.view.delegate = viewController
        self.view.sampleCount = 4
        
        avaliableResourceSemphore = dispatch_semaphore_create(1)
        
        createBackBuffer()
        setupPipelineState()
    }
    
    func createBackBuffer() {
        // Make a fake backbuffer, dimension is WindowWidth x WindowHeight
        // When we draw, we actually change the corresponding pixel color
        // Result: This is not a practical solution...
        for i in 0..<WindowHeight {
            
            for j in 0..<WindowWidth {
                
                let vertex = Vertex(x: Float(j) * (1.0 / Float(WindowWidth) + EPSILON) * 2.0 - 1.0, y: Float(i) * (1.0 / Float(WindowHeight) + EPSILON) * -2.0 + 1.0, z: 1.0, r: 0.0, g: 0.0, b: 0.0, a: 1.0, size: 2.0)
                
                verticesArray.append(vertex)
            }
        }

        for vertex in verticesArray {
            verticesData += vertex.vertexBuffer()
        }
        
        let verticesDataSize = verticesData.count * sizeofValue(verticesData[0])
        
        vertexBuffer = device.newBufferWithBytes(verticesData, length: verticesDataSize, options: [])
        
        verticesArrayBufferPointer = UnsafeMutablePointer<Vertex>(vertexBuffer.contents())
        
        tempBufferPointer = verticesArrayBufferPointer
    }
    
    func setupPipelineState() {
        // load any resources required for rendering
        commandQueue = device.newCommandQueue()
        commandQueue.label = "main command queue"
        
        let defaultLibrary = device.newDefaultLibrary()!
        let fragmentProgram = defaultLibrary.newFunctionWithName("passThroughFragment")!
        let vertexProgram = defaultLibrary.newFunctionWithName("passThroughVertex")!
        
        let pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        pipelineStateDescriptor.sampleCount = view.sampleCount
        
        do {
            try pipelineState = device.newRenderPipelineStateWithDescriptor(pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    func update(timeSinceLastFrame:Float) {
        
        verticesArrayBufferPointer.initializeFrom(verticesArray)
    }
    
    func present() {
    
        dispatch_semaphore_wait(avaliableResourceSemphore, DISPATCH_TIME_FOREVER)
        
        // create a commandBuffer
        let commandBuffer = commandQueue.commandBuffer()
        commandBuffer.label = "Frame command buffer"
        
        commandBuffer.addCompletedHandler{(commandBuffer) -> Void in
            dispatch_semaphore_signal(self.avaliableResourceSemphore)
        }
    
        let renderPassDescriptor = view.currentRenderPassDescriptor!
        let drawable = view.currentDrawable!
        
        renderPassDescriptor.colorAttachments[0].clearColor = White
    
        let renderEncoder = commandBuffer.renderCommandEncoderWithDescriptor(renderPassDescriptor)
        renderEncoder.label = "render encoder"
    
        renderEncoder.pushDebugGroup("draw morphing triangle")
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, atIndex: 0)
        renderEncoder.drawPrimitives(.Point, vertexStart: 0, vertexCount: verticesCount, instanceCount: 1)
    
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        
        commandBuffer.presentDrawable(drawable)
    
        commandBuffer.commit()
    }
    
    func drawPoint(x: Int, y: Int, color: MTLClearColor) {
        
        if (x > WindowWidth || y > WindowHeight) {
            print("Fatal error...")
        }
        
        // Each vertex has a VertexSize offset
        let offset = (x + y * WindowWidth);
        
        tempBufferPointer[offset].r = Float(color.red)
        tempBufferPointer[offset].g = Float(color.green)
        tempBufferPointer[offset].b = Float(color.blue)
        tempBufferPointer[offset].a = Float(color.alpha)
        
        // Crazy link
//        let tempBufferPointer = backBufferPointer + offset
//        memcpy(tempBufferPointer, color.toFloatArray(), color.toFloatArray().count * sizeof(Float))
    }
    
    func drawLine(startX: Int, startY: Int, endX: Int, endY: Int, color: MTLClearColor) {
        
        // This function draws a line from startX, startY to endX, endY
        // using differential error
        // terms (based on Bresenhams work
        var dx: Int         // Difference in x's
        var dy: Int         // Difference in y's
        var dx2: Int        // dx, dy * 2
        var dy2: Int
        var xIncrease: Int = 0  // Amount in pixel space to move during drawing
        var yIncrease: Int = 0
        var error: Int      // The discriminant i.e. error i.e. decision variable
        var x: Int = startX
        var y: Int = startY
        
        tempBufferPointer = verticesArrayBufferPointer
        
        // Compute horizontal and vertical deltas
        dx = endX - startX;
        dy = endY - startY
        
        // Test which direction the line is going in i.e. slope angle
        if (dx >= 0) {
            xIncrease = 1
        }   // End if line is moving right
        else {
            xIncrease = -1
            
            dx = -dx    // Need absolute value
        }   // End else moveing left
        
        // Test y component of slope
        if (dy >= 0) {
            yIncrease = 1
        }   // End if line is moving down
        else {
            yIncrease = -1
            dy = -dy    // Need absolute value
        }   // End else moving up
        
        // Compute (dx, dy) * 2
        dx2 = dx << 1
        dy2 = dy << 1
        
        // Now based on which delta is greater we can draw the line
        if (dx > dy) {
            
            // Initialize error term
            error = dy2 - dx
            
            // Draw the line
            for _ in 0...dx {
                
                // Set the pixel
                drawPoint(x, y: y, color: color)
                
                // Test if error overflowed
                if (error >= 0) {
                    error -= dx2
                    
                    // Move to next line
                    y += yIncrease
                }   // End if error overflowed
                
                // Adjust the error term
                error += dy2
                
                // Move to the next pixel
                x += xIncrease
            }   // End for
        }   // End if |slope| <= 1
        else {
            // Initialize error term
            error  = dx2 - dy
            
            // Draw the line
            for _ in 0...dy {
                
                // Set the pixel
                drawPoint(x, y: y, color: color)
                
                // Test if error overflowed
                if (error >= 0) {
                    error -= dy2
                    
                    // Move to the next line
                    x += xIncrease
                } // End if error overflowed
                
                // Adjust the error term
                error += dx2
                
                // Move to the next pixel
                y += yIncrease
            }   // End for
        }   // End else |slope > 1|
    }   // End drawLine
    
    func drawClipLine(startX: Int, startY: Int, endX: Int, endY: Int, color: MTLClearColor) -> Int {
        
        var clipX1 = startX;
        var clipY1 = startY
        
        var clipX2 = endX
        var clipY2 = endY
        
        // This function clips the send line using the globally defined clipping region
        var pointCode1 = ClipCodeCenter
        var pointCode2 = ClipCodeCenter
        
        // Determine codes for point1 and point2
        if (startY < minClipY) {
            pointCode1 |= ClipCodeNorth
        }
        else if (startY > maxClipY) {
            pointCode1 |= ClipCodeSouth
        }
        
        if (startX < minClipX) {
            pointCode1 |= ClipCodeWest
        }
        else if (startX > maxClipX) {
            pointCode1 |= ClipCodeEast
        }
        
        if (endY < minClipY) {
            pointCode2 |= ClipCodeNorth
        }
        else if (endY > maxClipY) {
            pointCode2 |= ClipCodeSouth
        }
        
        if (endX < minClipX) {
            pointCode2 |= ClipCodeWest
        }
        else if (endX > maxClipX) {
            pointCode2 |= ClipCodeEast
        }
        
        // Try and trivially reject
        let value = pointCode1 & pointCode2
        
        if (Bool(value)) {
            return 0
        }
        
        // Test for totally visible, if so leave points untouched
        if (pointCode1 == 0 && pointCode2 == 0) {
            drawLine(clipX1, startY: clipY1, endX: clipX2, endY: clipY2, color: color)
            return 1
        }
        
        // Determine end clip point for p1
        switch pointCode1 {
            
        case ClipCodeCenter: break
            
        case ClipCodeNorth:
            
            let m = Float(endX - startX) / Float(endY - startY)
            clipX1 = Int(Float(startX) + 0.5 + Float(minClipY - startY) * m)
            clipY1 = minClipY
            
            break
            
        case ClipCodeSouth:
            
            let m = Float(endX - startX) / Float(endY - startY)
            clipX1 = Int(Float(startX) + 0.5 + Float(maxClipY - startY) * m)
            clipY1 = maxClipY
            
            break
            
        case ClipCodeWest:
            
            let m = Float(endY - startY) / Float(endX - startX)
            clipX1 = minClipX
            clipY1 = Int(Float(startY) + 0.5 + Float(minClipX - startX) * m)
            
        case ClipCodeEast:
            
            let m = Float(endY - startY) / Float(endX - startX)
            clipX1 = maxClipX
            clipY1 = Int(Float(startY) + 0.5 + Float(maxClipX - startX) * m)
            
            break
            
        // These cases are more complex, must compute 2 intersections
        case ClipCodeNorthEast:
            
            // North horizontal line intersection
            let m = Float(endX - startX) / Float(endY - startY)
            clipX1 = Int(Float(startX) + 0.5 + Float(minClipY - startY) * m)
            clipY1 = minClipY
            
            // Test if intersection is valid,
            // If so then done, else compute next
            if (clipX1 < minClipX || clipX1 > maxClipX) {
                
                // East vertical line intersection
                let m = Float(endY - startY) / Float(endX - startX)
                clipX1 = maxClipX
                clipY1 = Int(Float(startY) + 0.5 + Float(maxClipX - startX) * m)
            }
            
            break
            
        case ClipCodeSouthEast:
            
            let m = Float(endX - startX) / Float(endY - startY)
            clipX1 = Int(Float(startX) + 0.5 + Float(maxClipY - startY) * m)
            clipY1 = maxClipY
            
            // Test if intersection is valid
            // If so then done, else compute next
            if (clipX1 < minClipX || clipX1 > maxClipX) {
                
                let m = Float(endY - startY) / Float(endX - startX)
                clipX1 = maxClipX
                clipY1 = Int(Float(startY) + 0.5 + Float(maxClipX - startX) * m)
            }
            
            break
            
            
        case ClipCodeNouthWest:
            
            // North horizontal intersection
            let m = Float(endX - startX) / Float(endY - startY)
            clipX1 = Int(Float(startX) + 0.5 + Float(minClipY - startY) * m)
            clipY1 = minClipY
            
            // Test if intersection is valid,
            // if so then done, else compute next
            if (clipX1 < minClipX || clipX1 > maxClipX) {
                
                let m = Float(endY - startY) / Float(endX - startX)
                clipX1 = minClipX
                clipY1 = Int(Float(startY) + 0.5 + Float(minClipX - startX) * m)
            }
            
            break
            
        case ClipCoideSouthWest:
            
            // South horizontal line intersection
            let m = Float(endX - startX) / Float(endY - startY)
            clipX1 = Int(Float(startX) + 0.5 + Float(minClipY - startY) * m)
            clipY1 = maxClipY
            
            // Test if intersection is valid,
            // if so then done, else compute next
            if (clipX1 < minClipX || clipX1 > maxClipX) {
                
                let m = Float(endY - startY) / Float(endX - startX)
                clipX1 = minClipX
                clipY1 = Int(Float(startY) + 0.5 + Float(minClipX - startX) * m)
            }
            
            break
            
        default: break
            
        }
        
        // Determine end clip point for p2
        switch pointCode2 {
            
        case ClipCodeCenter: break
            
        case ClipCodeNorth:
            
            let m = Float(startX - endX) / Float(startY - endY)
            clipX2 = Int(Float(endX) + 0.5 + Float(minClipY - endY) * m)
            clipY2 = minClipY
            
            break
            
        case ClipCodeSouth:
            
            let m = Float(startX - endX) / Float(startY - endY)
            clipX2 = Int(Float(endX) + 0.5 + Float(maxClipY - endY) * m)
            clipY2 = maxClipY
            
            break
            
        case ClipCodeWest:
            
            let m = Float(startY - endY) / Float(startX - endX)
            clipX2 = minClipX
            clipY2 = Int(Float(endY) + 0.5 + Float(minClipX - endX) * m)
            
        case ClipCodeEast:
            
            let m = Float(startY - endY) / Float(startX - endX)
            clipX2 = maxClipX
            clipY2 = Int(Float(endY) + 0.5 + Float(maxClipX - endX) * m)
            
            break
            
        // These cases are more complex, must compute 2 intersections
        case ClipCodeNorthEast:
            
            // North horizontal line intersection
            let m = Float(startX - endX) / Float(startY - endY)
            clipX2 = Int(Float(endX) + 0.5 + Float(minClipY - endY) * m)
            clipY2 = minClipY
            
            // Test if intersection is valid,
            // If so then done, else compute next
            if (clipX2 < minClipX || clipX2 > maxClipX) {
                
                // East vertical line intersection
                let m = Float(startY - endY) / Float(startX - endX)
                clipX2 = maxClipX
                clipY2 = Int(Float(endY) + 0.5 + Float(maxClipX - endX) * m)
            }
            
            break
            
        case ClipCodeSouthEast:
            
            let m = Float(startX - endX) / Float(startY - endY)
            clipX2 = Int(Float(endX) + 0.5 + Float(maxClipY - endY) * m)
            clipY2 = maxClipY
            
            // Test if intersection is valid
            // If so then done, else compute next
            if (clipX2 < minClipX || clipX2 > maxClipX) {
                
                let m = Float(startY - endY) / Float(startX - endX)
                clipX2 = maxClipX
                clipY2 = Int(Float(endY) + 0.5 + Float(maxClipX - endX) * m)
            }
            
            break
            
            
        case ClipCodeNouthWest:
            
            // North horizontal intersection
            let m = Float(startX - endX) / Float(startY - endY)
            clipX2 = endX + Int(0.5 + Float(minClipY - endY) * m)
            clipY2 = minClipY
            
            // Test if intersection is valid,
            // if so then done, else compute next
            if (clipX2 < minClipX || clipX2 > maxClipX) {
                
                let m = Float(startY - endY) / Float(startX - endX)
                clipX2 = minClipX
                clipY2 = Int(Float(endY) + 0.5 + Float(minClipX - endX) * m)
            }
            
            break
            
        case ClipCoideSouthWest:
            
            // South horizontal line intersection
            let m = Float(startX - endX) / Float(startY - endY)
            clipX2 = Int(Float(endX) + 0.5 + Float(maxClipY - endY) * m)
            clipY2 = maxClipY
            
            // Test if intersection is valid,
            // if so then done, else compute next
            if (clipX2 < minClipX || clipX2 > maxClipX) {
                
                let m = Float(startY - endY) / Float(startX - endX)
                clipX2 = minClipX
                clipY2 = Int(Float(endY) + 0.5 + Float(minClipX - endX) * m)
            }
            
            break
            
        default: break
            
        }
        
        // Do bounds check
        if ((clipX1 < minClipX) || (clipX1 > maxClipX) ||
            (clipY1 < minClipY) || (clipY1 > maxClipY) ||
            (clipX2 < minClipX) || (clipX2 > maxClipY) ||
            (clipY2 < minClipY) || (clipY2 > maxClipY)) {
            return 0
        }
        
        drawLine(clipX1, startY: clipY1, endX: clipX2, endY: clipY2, color: color)
        return 1
    }
    
    deinit{
            dispatch_semaphore_signal(self.avaliableResourceSemphore)
    }
}