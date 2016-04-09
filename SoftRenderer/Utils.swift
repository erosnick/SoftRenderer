//
//  Utils.swift
//  SoftRenderer
//
//  Created by Princerin on 4/3/16.
//  Copyright © 2016 Princerin. All rights reserved.
//

import Foundation
import MetalKit

let WindowWidth: Int = 800
let WindowHeight: Int = 600
let WindowSize = NSMakeSize(CGFloat(WindowWidth), CGFloat(WindowHeight))
let ViewDistance: Float = 320.0
let NearZ: Float = 10.0
let FarZ: Float = 2000.0
let VertexSize: Int = 8
let Pitch = VertexSize * WindowWidth

let Black = MTLClearColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
let White = MTLClearColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
let Red = MTLClearColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 1.0)
let CornFlower = MTLClearColor(red: 1.0 / 255.0 * 100.0, green: 1.0 / 255.0 * 149.0, blue: 1.0 / 255.0 * 237.0, alpha: 1.0)

let EPSILON: Float = 0.0000000001

// Key Codes
let Key_Space: UInt16 = 49
let Key_Left: UInt16 = 123
let Key_Right: UInt16 = 124
let Key_Down: UInt16 = 125
let Key_Up: UInt16 = 126

// Clip directions
let ClipCodeCenter = 0x0000
let ClipCodeNorth = 0x0008
let ClipCodeSouth = 0x0004
let ClipCodeEast = 0x0002
let ClipCodeWest = 0x0001
let ClipCodeNorthEast = 0x000a
let ClipCodeSouthEast = 0x0006
let ClipCodeNouthWest = 0x0009
let ClipCoideSouthWest = 0x0005

enum Direction {
    case None
    case Up
    case Down
    case Left
    case Right
}

// Clip region
let minClipX = 0
let maxClipX = WindowWidth - 1
let minClipY = 0
let maxClipY = WindowHeight - 1

struct Vector {
    let x, y, z: Float
}

struct Line {
    var v1, v2: Int   // Indices to endpoints of line in vertex list
    var color: float4
}

func drand48f() -> Float {
    return Float(drand48())
}

func randomi(upperBound: Int) -> Int {
    return Int(arc4random_uniform(UInt32(upperBound)))
}

func randomVertex() -> Vertex {
    return Vertex(x: drand48f() * 2.0 - 1.0, y: drand48f() * 2.0 - 1.0, z: 1.0, r: drand48f(), g: drand48f(), b: drand48f(), a: 1.0, size: 2.0)
}

extension MTLClearColor {
    func toFloatArray() -> [Float] {
        return [Float(self.red), Float(self.green), Float(self.blue), Float(self.alpha)]
    }
}