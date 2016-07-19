//
//  AudioCell.swift
//  VKAudioPlayer
//
//  Created by Nikita Belousov on 5/29/16.
//  Copyright © 2016 Nikita Belousov. All rights reserved.
//

import UIKit
import NAKPlaybackIndicatorView
import AddButton
import ACPDownload

protocol AudioCellDelegate: class {
    func addButtonPressed(sender: AudioCell)
    func downloadButtonPressed(sender: AudioCell)
}

class AudioCell: UITableViewCell {

    @IBOutlet weak var statusView: UIView!
    @IBOutlet weak var addButton: AddButton!
    @IBOutlet weak var artistLabel: UILabel!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleTrailingConstraint: NSLayoutConstraint!
    
    var playbackIndicator: NAKPlaybackIndicatorView!
    var downloadedIndicator: UIImageView!
    var downloadButton: ACPDownloadView!
    var audioItem: AudioItem?
    
    weak var delegate: AudioCellDelegate?
    
    private var _downloaded = false
    var downloaded: Bool {
        set {
            _downloaded = newValue
            if newValue == true {
                downloadedIndicator.hidden = false
                downloadButton.hidden = true
            } else {
                downloadedIndicator.hidden = true
                downloadButton.hidden = false
            }
        }
        get {
            return _downloaded
        }
    }
    
    private var _ownedByUser = true
    var ownedByUser: Bool {
        set {
            _ownedByUser = newValue
            if newValue == true {
                addButton.hidden = true
                titleTrailingConstraint.constant = 8
                setNeedsUpdateConstraints()
            } else {
                addButton.alpha = 1
                addButton.hidden = false
                titleTrailingConstraint.constant = addButton.frame.size.width - 8
                setNeedsUpdateConstraints()
            }
        }
        get {
            return _ownedByUser
        }
    }
    
    private var _playing = false
    var playing: Bool {
        set {
            _playing = newValue
            if newValue == true {
                playbackIndicator.hidden = false
                downloadedIndicator.hidden = true
                downloadButton.hidden = true
            } else {
                playbackIndicator.hidden = true
                downloadButton.hidden = _downloaded
                downloadedIndicator.hidden = !_downloaded
            }
        }
        get {
            return _playing
        }
    }
    
    @IBAction func addButtonPressed() {
        addButton.alpha = 0.3
        delegate?.addButtonPressed(self)
    }
    
    // MARK: Notification handlers
    
    @objc func audioItemIsBeingPlayedNotificationHandler(notification: NSNotification) {
        
        if let audioItemBeingPlayed = notification.object as? AudioItem {
            playing = audioItemBeingPlayed.id == audioItem!.id
        }
        
    }
    
    // MARK:
    
    var i = 0
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        titleTrailingConstraint.constant = 8
        addButton.hidden = true
        
        // download button
        downloadButton = ACPDownloadView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        downloadButton.backgroundColor = UIColor.clearColor()
        self.statusView.addSubview(downloadButton)
        downloadButton.hidden = true
        
        // downloaded indicator
        downloadedIndicator = UIImageView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        downloadedIndicator.image = UIImage(named: "GreenDot")
        self.statusView.addSubview(downloadedIndicator)
        downloadedIndicator.hidden = true
        
        //playbackIndicator
        playbackIndicator = NAKPlaybackIndicatorView(frame: CGRect(x: 0, y: 0, width: 35, height: 35))
        statusView.addSubview(playbackIndicator)
        playbackIndicator.state = .Playing
        playbackIndicator.backgroundColor = UIColor.whiteColor()
        playbackIndicator.hidden = true
    
        //
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(audioItemIsBeingPlayedNotificationHandler), name: "AudioItemIsBeingPlayed", object: nil)
        
        
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        
        // Configure the view for the selected state
    }

}
