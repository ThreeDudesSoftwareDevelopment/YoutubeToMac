//
//  YTDownloadRequest.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 6/16/19.
//  Copyright © 2021 Peer Group Software. All rights reserved.
//

import Foundation

class YTDownloadRequest {
    var destination = "~/Desktop"
    var contentURL = ""
    var audioOnly: Bool = false
    var fileFormat = FileFormat.defaultVideo // Default video file format
    var progressHandler: ((Double, Error?, YTVideo?) -> Void)!
    var completionHandler: ((YTVideo?, Error?) -> Void)!
    var error: Error?
    
    convenience init(contentURL: String, destination: String) {
        self.init()
        self.contentURL = contentURL
        self.destination = destination
    }
    
    convenience init(contentURL: String) {
        self.init()
        self.contentURL = contentURL
    }
}

enum FileFormat: String {
    case mp4 = "mp4"
    case flv = "flv"
    case webm = "webm"
    case m4a = "m4a"
    case mp3 = "mp3"
    case wav = "wav"
    case aac = "aac"
    case defaultAudio = "wav/m4a/mp3/bestaudio"
    case defaultVideo = "mp4/flv/best"
}
