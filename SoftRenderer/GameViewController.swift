//
//  GameViewController.swift
//  SoftRenderer
//
//  Created by Princerin on 4/9/16.
//  Copyright (c) 2016 Princerin. All rights reserved.
//

import Cocoa
import MetalKit

var gameViewController: GameViewController!

class GameViewController: NSViewController, MTKViewDelegate {
    
    var renderer: SoftRenderer!
    
    var isPlaying = false
    
    let numStars = 512
    let numTies = 32
    let numExplosions = 32
    let numTieVertices = 10
    let numTieEdges = 8
    
    let crossVelocity = 4
    
    let playerZVelocity = 8
    
    var crossX = 0
    var crossY = 0
    var crossScreenX = WindowWidth / 2
    var crossScreenY = WindowHeight / 2
    var targetScreenX = WindowWidth / 2
    var targetScreenY = WindowHeight / 2
    
    var cannonState = 0
    var cannonCount = 0
    
    // Ship structure
    struct Tie {
        var state: Int       // Ship state, 0 for dead, 1 for alive
        var x, y, z: Float     // Ship position
        var vx, vy, vz: Float  // Ship velocity
    }
    
    // Explosion structure
    struct Explosion {
        
        var state: Int
        var counter: Int
        var color: float4
        var edgeStarts: [Float]
        var edgeEnds: [Float]
        var velocities: [Vector]
    }
    
    var tieVerticesList = [Vertex]()
    var tieShape = [Line]()
    var ties = [Tie]()
    var starField =  [Vertex]()
    var explosions = [Explosion]()
    
    var misses = 0
    var hits = 0
    var score = 0
    
    var isKeyDown = false
    var direction = Direction.None
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        gameViewController = self
        
        // Play background music
        AudioPlayer.open("bg", ext: "mp3")
        //        AudioPlayer.play("bg")
        
        AudioPlayer.open("shocker", ext: "mp3")
        
        isPlaying = true
        
        loadAssets()
    }
    
    func initStarField() {
        
        for _ in 0..<500 {
            
            let x = Float(-WindowWidth / 2 + Int(drand48f() * Float(WindowWidth)))
            let y = Float(-WindowHeight / 2 + Int(drand48f() * Float(WindowHeight)))
            let z = NearZ + Float(arc4random() % UInt32(FarZ - NearZ))
            
            starField.append(Vertex(x: x, y: y, z: z, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0))
        }
    }
    
    func updateStarField() {
        
        for i in 0..<500 {
            starField[i].z -= 1
            
            if (starField[i].z < NearZ) {
                starField[i].z = FarZ
            }
        }
    }
    
    func drawStarField() {
        
        for i in 0..<500 {
            
            // Compute perspective coordinate
            let perX = ViewDistance * starField[i].x / starField[i].z
            let perY = ViewDistance * starField[i].y / starField[i].z
            
            // Convert to screen space
            let screenX = WindowWidth / 2 + Int(perX)
            let screenY = WindowHeight / 2 - Int(perY)
            
            if (screenX >= WindowWidth || screenX < 0 || screenY >= WindowHeight || screenY < 0) {
                continue
            }
            else {
                renderer.drawPoint(screenX, y: screenY, color: White)
            }
        }
    }
    
    func initTieVerticesList() {
        
        // Tie ship vertex list
        tieVerticesList = [Vertex(x: -40, y:  40, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x: -40, y:   0, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x: -40, y: -40, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x: -10, y:   0, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x:   0, y:  20, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x:  10, y:   0, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x:   0, y: -20, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x:  40, y:  40, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x:  40, y:   0, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0),
                           Vertex(x:  40, y: -40, z: 0, r: 1.0, g: 1.0, b: 1.0, a: 1.0, size: 2.0)]
        
        // Tie ship edge list
        tieShape = [Line(v1: 0, v2: 2, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 1, v2: 3, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 3, v2: 4, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 4, v2: 5, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 5, v2: 6, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 6, v2: 3, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 5, v2: 8, color: float4(0.0, 1.0, 0.0, 1.0)),
                    Line(v1: 7, v2: 9, color: float4(0.0, 1.0, 0.0, 1.0))]
    }
    
    func generateTie() -> Tie {
        
        let x = Float(-WindowWidth + Int(drand48f() * Float(WindowWidth) * 2))
        let y = Float(-WindowHeight + Int(drand48f() * Float(WindowHeight) * 2))
        let z = Float(FarZ * 4)
        
        let vx = Float(-4 + randomi(8))
        let vy = Float(-4 + randomi(8))
        let vz = Float(-4 - randomi(64))
        
        let tie = Tie(state: 1, x: x, y: y, z: z, vx: vx, vy: vy, vz: vz)
        
        return tie
    }
    
    func initTie(index: Int) {
        
        let tie = generateTie()
        
        ties[index] = tie
    }
    
    func initTies() {
        
        for _ in 0..<numTies {
            
            ties.append(generateTie())
        }
    }
    
    func  updateTies() {
        
        for index in 0..<numTies {
            
            // If ship is hited
            if (ties[index].state == 0) {
                continue
            }
            
            // Process next ship
            ties[index].x += ties[index].vx
            ties[index].y += ties[index].vy
            ties[index].z += ties[index].vz
            
            // Check if ship fly over NearZ
            if (ties[index].z <= NearZ) {
                
                initTie(index)
                
                misses += 1
            }
        }
    }
    
    func startExplosion(index: Int) {
        
        
    }
    
    func drawTies() {
        
        var boundBoxMinX, boundBoxMinY, boundBoxMaxX, boundBoxMaxY: Int
        
        for index in 0..<numTies {
            
            if (ties[index].state == 0) {
                continue
            }
            
            // Set the boundbox to impossible value
            boundBoxMinX = 100000
            boundBoxMaxX = -100000
            boundBoxMinY = 100000
            boundBoxMaxY = -100000
            
            let colorFactor = ties[index].z / FarZ * 4
            
            for edge in 0..<numTieEdges {
                
                // Endpoints
                var endPointPerspective1 = Vertex()
                var endPointPerspective2 = Vertex()
                
                // Apply perspective transform to endpoints
                endPointPerspective1.x = ViewDistance * (ties[index].x + tieVerticesList[tieShape[edge].v1].x) / (tieVerticesList[tieShape[edge].v1].z + ties[index].z)
                
                endPointPerspective1.y = ViewDistance * (ties[index].y + tieVerticesList[tieShape[edge].v1].y) / (tieVerticesList[tieShape[edge].v1].z + ties[index].z)
                
                endPointPerspective2.x = ViewDistance * (ties[index].x + tieVerticesList[tieShape[edge].v2].x) / (tieVerticesList[tieShape[edge].v2].z + ties[index].z)
                
                endPointPerspective2.y = ViewDistance * (ties[index].y + tieVerticesList[tieShape[edge].v2].y) / (tieVerticesList[tieShape[edge].v2].z + ties[index].z)
                
                // Compute screen space coordinate
                let endPointScreenX1 = WindowWidth / 2 + Int(endPointPerspective1.x)
                let endPointScreenY1 = WindowHeight / 2 - Int(endPointPerspective1.y)
                
                let endPointScreenX2 = WindowWidth / 2 + Int(endPointPerspective2.x)
                let endPointScreenY2 = WindowHeight / 2 - Int(endPointPerspective2.y)
                
                // Draw it
                renderer.drawClipLine(endPointScreenX1, startY: endPointScreenY1, endX: endPointScreenX2, endY: endPointScreenY2, color: MTLClearColor(red: Double(1.0 * colorFactor), green: Double(1.0 * colorFactor), blue: Double(1.0 * colorFactor), alpha: 1.0))
                
                // Update bound box
                let minX = min(endPointScreenX1, endPointScreenX2)
                let maxX = max(endPointScreenX1, endPointScreenX2)
                
                let minY = min(endPointScreenY1, endPointScreenY2)
                let maxY = min(endPointScreenY1, endPointScreenY2)
                
                boundBoxMinX = min(boundBoxMinX, minX)
                boundBoxMinY = min(boundBoxMinY, minY)
                
                boundBoxMaxX = max(boundBoxMaxX, maxX)
                boundBoxMaxY = max(boundBoxMaxY, maxY)
            }
            
            // Check if ship was hit
            if (cannonState == 1) {
                
                // Check if target position in bound box
                if (targetScreenX > boundBoxMinX && targetScreenX < boundBoxMaxX &&
                    targetScreenY > boundBoxMinY && targetScreenY < boundBoxMaxY) {
                    
                    // Hit
                    startExplosion(index)
                    
                    // Add score
                    score += Int(ties[index].z)
                    
                    // Update hit count
                    hits += 1
                    
                    initTie(index)
                }
            }
        }
    }
    
    func drawExplosions() {
        
        
    }
    
    func drawCrossHair() {
        
        // Compute corsshair screen coordinate
        crossScreenX = WindowWidth / 2 + crossX
        crossScreenY = WindowHeight / 2 - crossY
        
        // Draw crosshair in screen space
        renderer.drawClipLine(crossScreenX - 16, startY: crossScreenY, endX: crossScreenX + 16, endY: crossScreenY, color: Red)
        renderer.drawClipLine(crossScreenX, startY: crossScreenY - 16, endX: crossScreenX, endY: crossScreenY + 16, color: Red)
        renderer.drawClipLine(crossScreenX - 16, startY: crossScreenY - 16, endX: crossScreenX - 16, endY: crossScreenY + 16, color: Red)
        renderer.drawClipLine(crossScreenX + 16, startY: crossScreenY - 16, endX: crossScreenX + 16, endY: crossScreenY + 16, color: Red)
    }
    
    func drawLaserBeam() {
        
        if (cannonState == 1) {
            
            // Right laser
            if (random() % 2 == 1) {
                renderer.drawClipLine(WindowWidth - 1, startY: WindowHeight - 1, endX: -4 + random() % 8 + targetScreenX, endY: -4 + random() % 8 + targetScreenY, color: White)
            }
                
                // Left laser
            else {
                renderer.drawClipLine(0, startY: WindowHeight - 1, endX: -4 + random() % 8 + targetScreenX, endY: -4 + random() % 8 + targetScreenY, color: White)
            }
        }
    }
    
    func updateCrossHair() {
        
        if (isKeyDown) {
            
            switch direction {
                
            case Direction.Up:
                
                crossY += crossVelocity
                
                if (crossY > WindowHeight / 2) {
                    crossY = WindowHeight / 2
                }
                
                break
                
            case Direction.Down:
                
                crossY -= crossVelocity
                
                if (crossY < -WindowHeight / 2) {
                    crossY = WindowHeight / 2
                }
                
                break
                
            case Direction.Left:
                
                crossX -= crossVelocity
                
                if (crossX < -WindowWidth / 2) {
                    crossY = -WindowWidth / 2
                }
                
                break
                
            case Direction.Right:
                
                crossX += crossVelocity
                
                if (crossX > WindowWidth / 2) {
                    crossX = WindowWidth / 2
                }
                
                break
                
            default:
                break
            }
        }
    }
    
    func updateCannonFire() {
        
        // Fire stage
        if (cannonState == 1) {
            
            cannonCount += 1
            if (cannonCount > 15) {
                
                cannonState = 2
            }
        }
        
        // Cooldown stage
        if (cannonState == 2) {
            
            cannonCount += 1
            if (cannonCount > 20) {
                
                cannonState = 0
            }
        }
    }

    func loadAssets() {
        
        initTieVerticesList()
        
        initStarField()
        initTies()
        
        renderer = SoftRenderer(viewController: self)
    }
    
    func update() {
        
        updateStarField()
        updateTies()
        updateCannonFire()
        
        targetScreenX = crossScreenX
        targetScreenY = crossScreenY
        
        updateCrossHair()
        
        renderer.update(0)
    }
    
    func render() {
        
        drawStarField()
        drawTies()
        drawCrossHair()
        drawLaserBeam()
    }

    func drawInMTKView(view: MTKView) {
        
        update()
        
        render()
        
        renderer.present()
    }
    
    func mtkView(view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    override func keyDown(theEvent: NSEvent) {
        
        switch theEvent.keyCode {
            
        case Key_Space:
            
            if (cannonState == 0) {
                
                cannonState = 1
                cannonCount = 0
                
                targetScreenX = crossScreenX
                targetScreenY = crossScreenY
                
                AudioPlayer.play("shocker")
            }
            
            break
            
        case Key_Up:
            
            isKeyDown = true
            
            direction = Direction.Up
            
            break
            
        case Key_Down:
            
            isKeyDown = true
            
            direction = Direction.Down
            
            crossY -= crossVelocity
            
            break
            
        case Key_Left:
            
            isKeyDown = true
            
            direction = Direction.Left
            
            crossX -= crossVelocity
            
            break
            
        case Key_Right:
            
            isKeyDown = true
            
            direction = Direction.Right
            
            crossX += crossVelocity
            
            break
            
        default:
            break
        }
    }
    
    override func keyUp(theEvent: NSEvent) {
        
        isKeyDown = false
        
        switch theEvent.keyCode {
            
        case Key_Space:
            
            cannonState = 0
            
            break
        default:
            break
        }
    }
}
