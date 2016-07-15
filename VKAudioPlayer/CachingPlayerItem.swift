//
//  CachingPlayerItem.swift
//  AudioStreamer
//
//  Created by Nikita Belousov on 7/9/16.
//  Copyright © 2016 Nikita Belousov. All rights reserved.
//

import AVFoundation

@objc protocol CachingPlayerItemDelegate {
    
    // called when file is fully downloaded
    optional func playerItem(playerItem: CachingPlayerItem, didFinishLoadingData data: NSData)
    
    // called every time new portion of data is received
    optional func playerItem(playerItem: CachingPlayerItem, didLoadBytesSoFar bytesLoaded: Int, outOf bytesExpected: Int)
    
    // called after prebuffering is finished, so player item is ready to play. Called only once, after initial prebuffering
    optional func playerItemReadyToPlay(playerItem: CachingPlayerItem)
    
    // called when some media did not arrive in time to continue playback
    optional func playerItemDidStopPlayback(playerItem: CachingPlayerItem)
    
}

extension NSURL {
    
    func urlWithCustomScheme(scheme: String) -> NSURL {
        let components = NSURLComponents(URL: self, resolvingAgainstBaseURL: false)
        components?.scheme = scheme
        return components!.URL!
    }
    
}

class CachingPlayerItem: AVPlayerItem {
    
    class ResourceLoaderDelegate: NSObject, AVAssetResourceLoaderDelegate, NSURLSessionDelegate, NSURLSessionDataDelegate, NSURLSessionTaskDelegate {
        
        var session: NSURLSession?
        var songData: NSMutableData?
        var response: NSURLResponse?
        var pendingRequests = Set<AVAssetResourceLoadingRequest>()
        weak var owner: CachingPlayerItem?
        
        //MARK: AVAssetResourceLoader delegate
        
        func resourceLoader(resourceLoader: AVAssetResourceLoader, shouldWaitForLoadingOfRequestedResource loadingRequest: AVAssetResourceLoadingRequest) -> Bool {
            
            if session == nil {
                let interceptedURL = loadingRequest.request.URL!.urlWithCustomScheme(owner!.scheme)
                startDataRequest(withURL: interceptedURL)
            }
            
            pendingRequests.insert(loadingRequest)
            processPendingRequests()
            return true
        }
        
        func startDataRequest(withURL url: NSURL) {
            let request = NSURLRequest(URL: url)
            let configuration = NSURLSessionConfiguration.defaultSessionConfiguration()
            configuration.requestCachePolicy = .ReloadIgnoringLocalAndRemoteCacheData
            session = NSURLSession(configuration: configuration, delegate: self, delegateQueue: nil)
            let task = session?.dataTaskWithRequest(request)
            task?.resume()
        }
        
        func resourceLoader(resourceLoader: AVAssetResourceLoader, didCancelLoadingRequest loadingRequest: AVAssetResourceLoadingRequest) {
            pendingRequests.remove(loadingRequest)
        }

        //MARK: NSURLSession delegate
        
        func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveData data: NSData) {
            songData?.appendData(data)
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didLoadBytesSoFar: songData!.length, outOf: Int(dataTask.countOfBytesExpectedToReceive))
        }
        
        func URLSession(session: NSURLSession, dataTask: NSURLSessionDataTask, didReceiveResponse response: NSURLResponse, completionHandler: (NSURLSessionResponseDisposition) -> Void) {
            completionHandler(NSURLSessionResponseDisposition.Allow)
            songData = NSMutableData()
            self.response = response
            processPendingRequests()
        }
        
        func URLSession(session: NSURLSession, task: NSURLSessionTask, didCompleteWithError error: NSError?) {
            if error != nil {
                print(error)
                return
            }
            processPendingRequests()
            owner?.delegate?.playerItem?(owner!, didFinishLoadingData: songData!)
        }
        
        //MARK:
        
        func processPendingRequests() {
            var requestsCompleted = Set<AVAssetResourceLoadingRequest>()
            for loadingRequest in pendingRequests {
                fillInContentInforation(loadingRequest.contentInformationRequest)
                let didRespondCompletely = respondWithDataForRequest(loadingRequest.dataRequest!)
                if didRespondCompletely {
                    requestsCompleted.insert(loadingRequest)
                    loadingRequest.finishLoading()
                }
            }
            for i in requestsCompleted {
                pendingRequests.remove(i)
            }
        }
        
        func fillInContentInforation(contentInformationRequest: AVAssetResourceLoadingContentInformationRequest?) {
            
            if contentInformationRequest == nil || response == nil {
                return
            }
            
            let mimeType = response?.MIMEType
            contentInformationRequest!.contentType = mimeType
            contentInformationRequest!.contentLength = response!.expectedContentLength
            contentInformationRequest!.byteRangeAccessSupported = true
        }
        
        func respondWithDataForRequest(dataRequest: AVAssetResourceLoadingDataRequest) -> Bool {
            
            let requestedOffset = Int(dataRequest.requestedOffset)
            let requestedLength = dataRequest.requestedLength
            let startOffset = Int(dataRequest.currentOffset)
        
            // Don't have any data at all for this request
            if songData == nil || songData!.length < startOffset {
                return false
            }
            
            // This is the total data we have from startOffset to whatever has been downloaded so far
            let bytesUnread = songData!.length - Int(startOffset)
            
            // Respond fully or whaterver is available if we can't satisfy the request fully yet
            let bytesToRespond = min(bytesUnread, requestedLength + Int(requestedOffset))
            dataRequest.respondWithData(songData!.subdataWithRange(NSMakeRange(startOffset, bytesToRespond)))
            
            let didRespondFully = songData!.length >= requestedLength + Int(requestedOffset)
            return didRespondFully
            
        }
        
        deinit {
            session?.invalidateAndCancel()
        }
        
    }
    
    private var resourceLoaderDelegate = ResourceLoaderDelegate()
    private let scheme: String!
    private var url: NSURL!
    
    var delegate: CachingPlayerItemDelegate?
    
    init(url: NSURL) {
        
        self.url = url
        
        let components = NSURLComponents(URL: url, resolvingAgainstBaseURL: false)!
        scheme = components.scheme
        
        let asset = AVURLAsset(URL: url.urlWithCustomScheme("streaming"))
        asset.resourceLoader.setDelegate(resourceLoaderDelegate, queue: dispatch_get_main_queue())
        super.init(asset: asset, automaticallyLoadedAssetKeys: nil)
        resourceLoaderDelegate.owner = self
        
        self.addObserver(self, forKeyPath: "status", options: NSKeyValueObservingOptions.New, context: nil)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(didStop), name:AVPlayerItemPlaybackStalledNotification, object: self)
        
    }
    
    func download() {
        if resourceLoaderDelegate.session == nil {
            resourceLoaderDelegate.startDataRequest(withURL: url)
        }
    }
    
    override init(asset: AVAsset, automaticallyLoadedAssetKeys: [String]?) {
        fatalError("not implemented")
    }
    
    //MARK: KVO
    
    override func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        delegate?.playerItemReadyToPlay?(self)
    }
    
    func didStop() {
        delegate?.playerItemDidStopPlayback?(self)
    }
    
    //MARK: deinit
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        removeObserver(self, forKeyPath: "status")
        resourceLoaderDelegate.session?.invalidateAndCancel()
    }
    
}
