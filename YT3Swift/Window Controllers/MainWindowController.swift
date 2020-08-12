//
//  MainWindowController.swift
//  YT3Swift
//
//  Created by Jake Spann on 1/8/18.
//  Copyright © 2018 Peer Group. All rights reserved.
//

import Cocoa

class MainWindowController: NSWindowController, NSTouchBarDelegate {
    
    var audioOnlyButton: NSButton?
    
    override func windowDidLoad() {
        super.windowDidLoad()
        
        if #available(OSX 10.13, *) {
            window?.backgroundColor = NSColor(named: "WindowBackground")
        } else {
            window?.backgroundColor = .white
        }
        
        window?.isMovableByWindowBackground = true
        window?.titlebarAppearsTransparent = true
    }
    
    func updateTBAudioButton(withState state: NSButton.StateValue) {
        if audioOnlyButton != nil {
            audioOnlyButton!.state = state
        }
    }
    
    @available(OSX 10.12.1, *)
    override func makeTouchBar() -> NSTouchBar? {
        let touchBar = NSTouchBar()
        touchBar.delegate = self
        touchBar.principalItemIdentifier = NSTouchBarItem.Identifier(rawValue: "group")
        touchBar.customizationIdentifier = "com.youtubetomac.touchbarbar"
        touchBar.defaultItemIdentifiers = [NSTouchBarItem.Identifier("group")]
        
        return touchBar
    }
    
    @objc func handleButtonPress(sender: NSButton) {
        switch sender.identifier {
        case NSUserInterfaceItemIdentifier("audioTBButton"):
            //print("audio")
            (contentViewController as! ViewController).audioToggle(sender)
        case NSUserInterfaceItemIdentifier("downloadTBButton"):
            //print("download")
            (contentViewController as! ViewController).startTasks(sender)
            sender.isEnabled = false
        default:
            break
        }
    }
    
    @available(OSX 10.12.1, *)
    func touchBar(_ touchBar: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        let audioButton = NSCustomTouchBarItem(identifier:NSTouchBarItem.Identifier(rawValue: "audioButton"))
        let button = NSButton(title: "Audio Only", target: self, action: #selector(handleButtonPress))
        audioOnlyButton = button
        button.setButtonType(.pushOnPushOff)
        button.identifier = NSUserInterfaceItemIdentifier(rawValue: "audioTBButton")
        audioButton.view = button
        
        let downloadTBButton = NSCustomTouchBarItem(identifier:NSTouchBarItem.Identifier(rawValue: "downloadButton"))
        let downloadButton = NSButton(title: "Download", target: self, action: #selector(handleButtonPress))
        downloadButton.bezelColor = .red
        downloadButton.identifier = NSUserInterfaceItemIdentifier(rawValue: "downloadTBButton")
        downloadTBButton.view = downloadButton
        
        let itemGroup = NSGroupTouchBarItem(identifier: NSTouchBarItem.Identifier(rawValue: "group"), items: [audioButton, downloadTBButton])
        return itemGroup
    }
    
}
