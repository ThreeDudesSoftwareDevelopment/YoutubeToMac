//
//  YTDLDownloader.swift
//  YoutubeToMac
//
//  Created by Jake Spann on 11/14/20.
//  Copyright © 2020 Peer Group Software. All rights reserved.
//

import Foundation

class YTDLDownloader: ContentDownloader {
    var delegate: ContentDownloaderDelegate?
    private var outputPipe:Pipe!
    private var errorPipe:Pipe!
    private var downloadTask:Process!
    private let downloadQOS: DispatchQoS.QoSClass  = .userInitiated
    static let executableName = "youtube-dl-2020-11-01"
    
    // If an error contains the string, the error matching the code is called
    private let errors: [(String, Int)] = [
        ("requested format not available", 415),
        ("has already been downloaded", 409),
        ("Premieres in", 403),
        ("This live event will begin in", 403),
        ("who has blocked it on copyright grounds", 451),
        ("is not a valid URL", 400),
        ("Unable to extract video data",404)
    ]
    
    var isRunning = false
    
    func download(content targetURL: String, with targetFormat: MediaFormat, to downloadDestination: URL, completion: () -> Void) {
        let downloadQueue = DispatchQueue.global(qos: downloadQOS)
        
        downloadQueue.async {
            
            let executablePath = Bundle.main.path(forResource: YTDLDownloader.executableName, ofType: "sh")
            self.downloadTask = Process()
            
            if #available(OSX 10.13, *) {
                self.downloadTask.executableURL = URL(fileURLWithPath: executablePath!)
            } else {
                self.downloadTask.launchPath = executablePath
            }
            
            self.downloadTask.arguments = ["-f \(targetFormat.fileExtension)", "-o%(title)s.%(ext)s", targetURL]
            self.downloadTask.currentDirectoryPath = downloadDestination.absoluteString
            
            self.downloadTask.terminationHandler = { task in
                DispatchQueue.main.async(execute: {
                    self.isRunning = false
                })
                
            }
            
            // Set up output processing for the task
            self.registerOutputHandlers(for: self.downloadTask, progressHandler:
            {(percent) in
                if self.delegate != nil {
                    self.delegate?.downloadDidProgress(to: percent)
                }
            }, errorHandler: {(error) in
                
                //progressHandler(100, error, self.currentVideo)
            })
            
            // Set up error handling for the download task
            self.registerErrorHandlers(for: self.downloadTask, errorHandler:
            {(error) in
                #if DEBUG
//                    print(error) //Debug
                #endif
                if self.delegate != nil {
                    self.delegate?.downloadDidProgress(to: 100)
                }
            })
            
            //Launch the task
            if #available(OSX 10.13, *) {
                try! self.downloadTask.run()
                print("Started download")
            } else {
                self.downloadTask.launch()
                print("Started download")
            }
            self.downloadTask.waitUntilExit()
            
        }
    }
    
    private func registerOutputHandlers(for task:Process, progressHandler: @escaping (Double) -> Void, errorHandler: @escaping (Error) -> Void/*, infoHandler: @escaping (YTVideo) -> Void*/) {
        
        outputPipe = Pipe()
        task.standardOutput = outputPipe
        outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: NSNotification.Name.NSFileHandleDataAvailable, object: outputPipe.fileHandleForReading , queue: nil) {
            notification in
            
            let output = self.outputPipe.fileHandleForReading.availableData
            let outputString = String(data: output, encoding: String.Encoding.utf8) ?? ""
            
            #if DEBUG
                print(outputString)
            #endif
            
            if outputString.contains("has already been downloaded") {
                self.stopDownload(withError: 409)
            } else if outputString.contains("[download]") {
                if outputString.contains("Destination:") {
                    var videonameString = (outputString.components(separatedBy: "\n").first! .replacingOccurrences(of: "[download] Destination: ", with: ""))
                    videonameString.removeLast(4) // Remove extension // This should probably be made better, don't assume extension length
                    if self.delegate != nil {
                        self.delegate?.didGetVideoName(videonameString)
                    }
                    print(videonameString)
                } else {
                    print("download update")
                    for i in (outputString.split(separator: " ")) {
                        if i.contains("%") {
                            if self.delegate != nil {
                                self.delegate?.downloadDidProgress(to: (Double(i.replacingOccurrences(of: "%", with: "")))!)
                            }
                        }
                    }
                }
            } else if outputString.contains("[youtube]") && outputString.contains("Downloading webpage") {
                print((outputString.split(separator: " "))[1].replacingOccurrences(of: ":", with: ""))
            }
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
        
    }
    
    private func registerErrorHandlers(for task:Process, errorHandler: @escaping (Error) -> Void) {
        errorPipe = Pipe()
        task.standardError = errorPipe
        errorPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        
        NotificationCenter.default.addObserver(forName: .NSFileHandleDataAvailable, object: errorPipe.fileHandleForReading , queue: nil) { notification in
            
            let errorData = self.errorPipe.fileHandleForReading.availableData
            let errorString = String(data: errorData, encoding: String.Encoding.utf8) ?? ""
            
            #if DEBUG
                print(errorString)
            #endif
            
            if !errorString.isEmpty {
                print("ERROR: \(errorString)")
                
                for error in self.errors {
                    if errorString.contains(error.0) {
                        self.stopDownload(withError: error.1)
                    }
                }
            }
            self.outputPipe.fileHandleForReading.waitForDataInBackgroundAndNotify()
        }
    }
    
    func stopDownload(withError downloadError: Int?) {
        downloadTask.terminate()
        if self.delegate != nil {
            self.delegate?.didCompleteDownload(error: downloadError)
        }
    }
    
    
}