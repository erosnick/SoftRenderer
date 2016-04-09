//
//  AudioPlayer.swift
//  SoftRenderer
//
//  Created by Princerin on 4/7/16.
//  Copyright © 2016 Princerin. All rights reserved.
//

import Foundation
import AVFoundation

class AudioPlayer {
    
    static var audioMap = [String : AVAudioPlayer]()

    static func open(audioFileName: String, ext: String) {
        
        let path = NSBundle.mainBundle().URLForResource(audioFileName, withExtension: ext)
        let audioPlayer: AVAudioPlayer!
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOfURL: path!)
            audioMap[audioFileName] = audioPlayer
        }
        catch {
            
        }
    }
    
    static func play(audioName: String) {
        audioMap[audioName]?.play()
    }

    static func pause(audioName: String) {
        audioMap[audioName]?.pause()
    }
}