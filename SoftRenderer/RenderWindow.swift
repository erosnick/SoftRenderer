//
//  RenderWindow.swift
//  SoftRenderer
//
//  Created by Princerin on 4/7/16.
//  Copyright © 2016 Princerin. All rights reserved.
//
import AppKit
import Foundation

class RenderWindow: NSWindow {
    override func keyDown(theEvent: NSEvent) {
        
        gameViewController.keyDown(theEvent)
        gameViewController.keyUp(theEvent)
    }
}