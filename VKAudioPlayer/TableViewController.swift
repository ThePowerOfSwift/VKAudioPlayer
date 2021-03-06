//
//  ViewController.swift
//  VKAudioPlayer
//
//  Created by Nikita Belousov on 5/6/16.
//  Copyright © 2016 Nikita Belousov. All rights reserved.
//

import UIKit
import VK_ios_sdk
import AVFoundation
import LNPopupController
import Cache

class TableViewController: UITableViewController {
    
    // MARK: Interface builder
    @IBOutlet var footerView: UIView!
    @IBOutlet weak var searchButton: UIBarButtonItem!
    
    @IBAction func searchButtonPressed(sender: AnyObject) {
        search()
    }
    
    var flag = false
    @IBAction func settingsButtonPressed(sender: AnyObject) {
        
    }
    
    // MARK: -
    let searchController = UISearchController(searchResultsController: nil)
    let audioPlayerViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("AudioPlayerViewController")
    var indicatorView = UIActivityIndicatorView()
    var context = AudioContext()
    
    // MARK: -
    func search() {
        UIView.animateWithDuration(0.3, animations: {
            self.tableView.contentOffset = CGPoint(x: 0, y: -self.tableView.contentInset.top)
        })
        self.searchController.searchBar.becomeFirstResponder()
    }
    
    // MARK: -
    func refresh(sender: AnyObject) {
        tableView.userInteractionEnabled = false
        searchButton.enabled = false
        
        let scope = ["audio"]
//        indicatorView.startAnimating()
        VKSdk.wakeUpSession(scope, completeBlock: { state, error in
//            self.indicatorView.stopAnimating()
            if state == VKAuthorizationState.Authorized {
                // ready to go
                
//                print(VKSdk.accessToken().accessToken)
                let audioRequestDescription = AudioRequestDescription.userAudioRequestDescription()
                self.initializeContext(audioRequestDescription)
                
            } else if state == VKAuthorizationState.Initialized {
                // auth needed
                VKSdk.authorize(scope)
            } else if state == VKAuthorizationState.Error {
                self.showMessage("You're now switched to cache-only mode. Pull down to retry.", title: "Failed to authorize")
                // TODO: Handle appropriately
            } else if error != nil {
                fatalError(error.description)
                // TODO: Handle appropriately
            }
        })
    }
    
    // MARK: -
    var allowedToFetchNewData = true
    override func scrollViewDidScroll(scrollView: UIScrollView) {
        if context.userAudio.count != 0 || context.globalAudio.count != 0 {
            let height = scrollView.frame.size.height
            let contentYoffset = scrollView.contentOffset.y
            let distanceFromBottom = scrollView.contentSize.height - contentYoffset
            if distanceFromBottom - height < distanceFromBottomToPreload && context.busy() == false && allowedToFetchNewData {
                if context.hasMoreToLoad() {
                    tableView.tableFooterView = footerView
                }
                context.loadNextPortion()
                allowedToFetchNewData = false
            }
        }
    }
    
    // MARK: -
    func initializeContext(audioRequestDescription: AudioRequestDescription) {
        context.cancel()
        context = AudioContext(audioRequestDescription: audioRequestDescription)
        tableView.tableFooterView = footerView
        tableView.reloadData()
        context.delegate = self
        context.loadNextPortion()
    }
    
    // MARK: - View controller customization
    override func viewDidLoad() {
        super.viewDidLoad()
    
//        VKSdk.forceLogout()
        
        let sdkInstance = VKSdk.initializeWithAppId(appID)
        sdkInstance.uiDelegate = self
        sdkInstance.registerDelegate(self)
        
        indicatorView.center = view.center
        indicatorView.activityIndicatorViewStyle = .Gray
        indicatorView.hidesWhenStopped = true
        view.addSubview(indicatorView)
        
        searchController.searchResultsUpdater = self
        searchController.searchBar.delegate = self
        searchController.dimsBackgroundDuringPresentation = false
        tableView.tableHeaderView = searchController.searchBar
        tableView.tableFooterView = footerView
        
        navigationController?.popupContentView.popupCloseButton?.setImage(UIImage(named: "DismissChevron"), forState: .Normal)
        
        refreshControl!.addTarget(self, action: #selector(refresh(_:)), forControlEvents: UIControlEvents.ValueChanged)
        self.refresh(self)
        
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return  UIStatusBarStyle.LightContent
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
}