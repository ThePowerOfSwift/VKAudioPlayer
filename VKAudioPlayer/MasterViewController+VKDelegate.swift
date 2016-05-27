//
//  MasterViewController+VKDelegate.swift
//  VKAudioPlayer
//
//  Created by Nikita Belousov on 5/24/16.
//  Copyright © 2016 Nikita Belousov. All rights reserved.
//

import VK_ios_sdk

extension MasterViewController: VKSdkDelegate, VKSdkUIDelegate {
    
    func vkSdkUserAuthorizationFailed() {
        print("Authorization failed")
        // TODO: handle appropriately
    }
    
    func vkSdkAccessAuthorizationFinishedWithResult(result: VKAuthorizationResult!) {
        let audioRequestDescription = AudioRequestDescription.usersAudioRequestDescription()
        initializeContext(audioRequestDescription)
    }
    
    func vkSdkShouldPresentViewController(controller: UIViewController!) {
        self.navigationController!.presentViewController(controller, animated: true, completion: nil)
    }
    
    func vkSdkNeedCaptchaEnter(captchaError: VKError!) {
        searchController.active = false
        let captchaController = VKCaptchaViewController.captchaControllerWithError(captchaError)
        captchaController.presentIn(self)
    }
    
}

