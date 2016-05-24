//
//  MasterViewController+VKDelegate.swift
//  VKAudioPlayer
//
//  Created by Nikitab Belousov on 5/24/16.
//  Copyright © 2016 Nikita Belousov. All rights reserved.
//

import VK_ios_sdk

extension MasterViewController: VKSdkDelegate, VKSdkUIDelegate {
    
    func vkSdkUserAuthorizationFailed() {
        print("Authorization failed")
        // TODO: handle appropriately
    }
    
    func vkSdkAccessAuthorizationFinishedWithResult(result: VKAuthorizationResult!) {
        //        print("Authorization finished with token: \(result.token.accessToken)")
        executeInitialRequest()
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

