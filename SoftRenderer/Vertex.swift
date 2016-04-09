//
//  Vertex.swift
//  MetalTest
//
//  Created by Princerin on 3/13/16.
//  Copyright © 2016 Princerin. All rights reserved.
//

import Foundation

struct Vertex {
    var x: Float = 0.0  // position
    var y: Float = 0.0
    var z: Float = 0.0
    var r: Float = 0.0
    var g: Float = 0.0
    var b: Float = 0.0
    var a: Float = 0.0   // color
    var size: Float = 2.0
    
    init() {
    
    }
    
    init(x: Float, y: Float, z: Float, r: Float, g: Float, b: Float, a: Float, size: Float) {
        
        self.x = x
        self.y = y
        self.z = z
        self.r = r
        self.g = g
        self.b = b
        self.a = a
        self.size = size
    }
    
    func positionBuffer() -> [Float] {
        return [x, y, z]
    }
    
    func colorBuffer() -> [Float] {
        return [r, g, b, a]
    }
    
    func vertexBuffer() -> [Float] {
        return [x, y, z, r, g, b, a, size]
    }
}