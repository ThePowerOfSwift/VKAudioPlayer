# VKAudioPlayer #

VKAudioPlayer allows you to listen to music from your VK profile and cache it for later playback. 

<img src="./Supplements/screen1.gif" width="320"/> <img src="./Supplements/screen2.gif" width="320"/>

## Features ##
- Manage the music in your VK profile: add, remove, search for new tracks
- Cache for future playback 

## How to install ##
First open Terminal and clone the project:
```
cd ~/Documents/
git clone http://github.com/neekeetab/VKAudioPlayer
cd VKAudioPlayer
```
For the following steps, you need to have [CocoaPods](https://cocoapods.org) installed. To install CocoaPods run this command:
```
sudo gem install cocoapods
```
When you're done, run the following command. Ensure that you're in the project directory:
```
pod install
```
OK. Now open Finder, go to the project directory and open ```VKAudioPlayer.xcworkspace```.
Note, you need to have [Xcode](https://itunes.apple.com/en/app/xcode/id497799835) installed. 

Choose your iOS device from the menu in the top left and run the project by clicking on play button. It might not work properly in iOS Simulator. 

## Known limitations / TODO list ##
- You need an internet connection to use the app even if you have some audio cached. The reason for this is that although VKAudioPlayer stores the cache, it doesn't store the list of the chached files. 
- Settings screen isn't implemented yet.

## Acknowledgements ##
- [LNPopupController](https://github.com/LeoNatan/LNPopupController) 
- [Cache](https://github.com/hyperoslo/Cache)
- [ACPDownload](https://github.com/antoniocasero/ACPDownload)
- [NAKPlaybackIndicatorView](https://github.com/yujinakayama/NAKPlaybackIndicatorView)
- [AddButton](https://github.com/svenbacia/AddButton)
- [BufferSlider](https://github.com/raxcat/BufferSlider)
- [MarqueeLabel](https://github.com/cbpowell/MarqueeLabel)
