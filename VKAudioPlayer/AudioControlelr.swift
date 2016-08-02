//
//  AudioController.swift
//  VKAudioPlayer
//
//  Created by Nikita Belousov on 7/19/16.
//  Copyright © 2016 Nikita Belousov. All rights reserved.
//

import Foundation
import AVFoundation

enum AudioControllerRepeatMode {
    case Dont
    case One
    case All
}

enum AudioContextSection {
    case UserAudio
    case GlobalAudio
}

class AudioController {
    
    static let sharedAudioController = AudioController()
    
    private(set) var player = AVPlayer()
    private(set) var indexOfCurrentAudioItem: Int?
    private(set) var audioContext: AudioContext?
    private(set) var audioContextSection: AudioContextSection?
    private(set) var playedToEnd: Bool = false
    
    
    var currentAudioItem: AudioItem? {
        return audioItemForAudioContextSection(audioContextSection, index: indexOfCurrentAudioItem)
    }
    
    var _repeatMode: AudioControllerRepeatMode = .Dont
    var repeatMode: AudioControllerRepeatMode {
        get {
            return _repeatMode
        }
        set {
            _repeatMode = newValue
        }
    }
    
    func audioItemForAudioContextSection(audioContextSection: AudioContextSection?, index: Int?) -> AudioItem? {
        if audioContextSection == nil || index == nil {
            return nil
        }
        if audioContextSection == .GlobalAudio {
            return audioContext?.globalAudio[index!]
        } else if audioContextSection == .UserAudio {
            return audioContext?.userAudio[index!]
        }
        return nil
    }
    
    func playAudioItemFromContext(audioContext: AudioContext?, audioContextSection: AudioContextSection?, index: Int?) {
        
        playedToEnd = false
        
        self.audioContext = audioContext
        self.audioContextSection = audioContextSection
        self.indexOfCurrentAudioItem = index
    
        if let audioItem = audioItemForAudioContextSection(audioContextSection, index: index) {

            let notification = NSNotification(name: AudioContorllerWillStartPlayingAudioItemNotification, object: nil, userInfo: [
                "audioItem": audioItem
                ])
            NSNotificationCenter.defaultCenter().postNotification(notification)
            
            CacheController.sharedCacheController.playerItemForAudioItem(audioItem, completionHandler: { playerItem, cached in
                
    //            self.player = AVPlayer(playerItem: playerItem)
    //            self.player.play()
                
                dispatch_async(dispatch_get_main_queue(), {
                    self.player.replaceCurrentItemWithPlayerItem(playerItem)
                    self.player.seekToTime(CMTime(seconds: 0, preferredTimescale: 1))
                    self.player.play()
                })
                
                let notification = NSNotification(name: AudioControllerDidStartPlayingAudioItemNotification, object: nil, userInfo: [
                    "audioItem": playerItem.audioItem
                    ])
                NSNotificationCenter.defaultCenter().postNotification(notification)
            })
        }
    }
    
    var paused: Bool {
        return !((player.rate != 0) && (player.error == nil))
    }
    
    func resume() {
        player.play()
        if let audioItem = currentAudioItem {
            let notification = NSNotification(name: AudioControllerDidResumeAudioItemNotification, object: nil, userInfo: [
                "audioItem": audioItem
                ])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }

    func pause() {
        player.pause()
        if let audioItem = currentAudioItem {
            let notification = NSNotification(name: AudioControllerDidPauseAudioItemNotification, object: nil, userInfo: [
                "audioItem": audioItem
                ])
            NSNotificationCenter.defaultCenter().postNotification(notification)
        }
    }
    
    func replay() {
        playAudioItemFromContext(audioContext, audioContextSection: audioContextSection, index: indexOfCurrentAudioItem)
    }
    
    // TODO:  next, prev
    
    // MARK: Notifications handling
    
    @objc private func playerItemDidPlayToEndNotificationHandler(notification: NSNotification) {
        
        playedToEnd = true
        
        let notification = NSNotification(name: AudioControllerDidPlayAudioItemToEndNotification, object: nil, userInfo: [
            "audioItem": currentAudioItem!
            ])
        NSNotificationCenter.defaultCenter().postNotification(notification)
        
        switch repeatMode {
        case .Dont:
            break
            
        case .One:
            playAudioItemFromContext(audioContext, audioContextSection: audioContextSection, index: indexOfCurrentAudioItem)
            break
            
        default:
            break
        }
        
    }
    
    // MARK:
    
    private init() {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(playerItemDidPlayToEndNotificationHandler), name: AVPlayerItemDidPlayToEndTimeNotification, object: nil)
        
    }
    
}
