//
//  main.swift
//  Bookmarks Management
//
//  Created by Paul Wasicsek on 24.01.2023.
//  Version: 0.2.0
//  Extract from Safari bookmark file:
//      - all broken links to brokenLinks.txt
//      - all working links to workingLinks.txt
//

import Foundation

func checkBookmarkRecursively(_ bookmark: [String: Any], parentTitle: String?, parentURL: String?, brokenLinksFile: FileHandle?, workingLinksFile: FileHandle?) {
    let uriDict = bookmark["URIDictionary"] as? [String: Any]
    let title = uriDict?["title"] as? String
    let type = bookmark["WebBookmarkType"] as? String
    let url = bookmark["URLString"] as? String ?? ""
        
    if type == "WebBookmarkTypeLeaf" {
        if let url = URL(string: url) {
            let semaphore = DispatchSemaphore(value: 0)
            let task = URLSession.shared.dataTask(with: url) { data, response, error in
                if let error = error {
                    print("\(uriDict?["title"] as? String ?? "") ; \(url) ; \(error.localizedDescription)")
                    brokenLinksFile?.seekToEndOfFile()
                    brokenLinksFile?.write("\(uriDict?["title"] as? String ?? "") ; \(url) ; \(error.localizedDescription)\n".data(using: .utf8)!)
                } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                    print("\(uriDict?["title"] as? String ?? "") ; \(url) ; Broken Link")
                    brokenLinksFile?.seekToEndOfFile()
                    brokenLinksFile?.write("\(uriDict?["title"] as? String ?? "") ; \(url) ; Broken Link\n".data(using: .utf8)!)
                } else {
                    print("\(uriDict?["title"] as? String ?? "") ; \(url) ; OK")
                    workingLinksFile?.seekToEndOfFile()
                    workingLinksFile?.write("\(uriDict?["title"] as? String ?? "") ; \(url) ; OK\n".data(using: .utf8)!)
                }
                semaphore.signal()
            }
            task.resume()
            semaphore.wait()
        }
    } else if type == "WebBookmarkTypeList" {
        let children = bookmark["Children"] as? [[String: Any]] ?? []
        for child in children {
            checkBookmarkRecursively(child, parentTitle: title, parentURL: url, brokenLinksFile: brokenLinksFile, workingLinksFile: workingLinksFile)
        }
    }
}

func checkBookmarks() {
    let bookmarksFilePath = "~/Library/Safari/Bookmarks.plist"
    let fileURL = URL(fileURLWithPath: NSString(string: bookmarksFilePath).expandingTildeInPath)
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: fileURL.path) {
        do {
            print("Bookmark file path:", fileURL.path)
            let data = try Data(contentsOf: fileURL)
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            guard let bookmarks = plist as? [String: Any], let children = bookmarks["Children"] as? [[String: Any]] else {
                print("Error: Failed to parse bookmarks plist")
                return
            }
            
            // Create a file to write broken links
            let brokenLinksFilePath = "./brokenLinks.txt"
            if !fileManager.fileExists(atPath: brokenLinksFilePath) {
                fileManager.createFile(atPath: brokenLinksFilePath, contents: nil, attributes: nil)
            }
            let brokenLinksFileURL = URL(fileURLWithPath: brokenLinksFilePath)
            
            // Create a file to write working links
            let workingLinksFilePath = "./workingLinks.txt"
            if !fileManager.fileExists(atPath: workingLinksFilePath) {
                fileManager.createFile(atPath: workingLinksFilePath, contents: nil, attributes: nil)
            }
            let workingLinksFileURL = URL(fileURLWithPath: workingLinksFilePath)
            let workingLinksFile = FileHandle(forWritingAtPath: workingLinksFileURL.path)
            
            if let brokenLinksFile = FileHandle(forWritingAtPath: brokenLinksFileURL.path) {
                for child in children {
                    checkBookmarkRecursively(child, parentTitle: nil, parentURL: nil, brokenLinksFile: brokenLinksFile, workingLinksFile: workingLinksFile)
                }
                brokenLinksFile.closeFile()
                
                // Iterate through the bookmarks to check for broken links
            } else {
                perror("FileHandle error")
                // print("Error: Failed to open file for writing")
            }
            workingLinksFile?.closeFile()
            
        } catch {
            print("Error: Failed to read bookmarks plist")
        }
    } else {
        // File does not exist, handle error or create it
        print("Bookmarks.plist file not found!")
    }
}

func main() {
    print("Starting bookmarks check")
    checkBookmarks()
}

main()
