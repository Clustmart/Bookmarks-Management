//
//  main.swift
//  Bookmarks Management
//
//  Created by Paul Wasicsek on 24.01.2023.
//

import Foundation

func checkBookmarkRecursively(_ bookmark: [String: Any], parentTitle: String?, parentURL: String?, brokenLinksFile: FileHandle?) {
    if let title = bookmark["Title"] as? String, let type = bookmark["WebBookmarkType"] as? String {
        let url = bookmark["URLString"] as? String ?? ""
        if type == "WebBookmarkTypeList" {
            if let url = URL(string: url) {
                let semaphore = DispatchSemaphore(value: 0)
                let task = URLSession.shared.dataTask(with: url) { data, response, error in
                    if let error = error {
                        print("\(title) : \(url) : \(error.localizedDescription)")
                        brokenLinksFile?.seekToEndOfFile()
                        brokenLinksFile?.write("\(title) : \(url) : \(error.localizedDescription)\n".data(using: .utf8)!)
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode != 200 {
                        print("\(title) : \(url) : Broken Link")
                        brokenLinksFile?.seekToEndOfFile()
                        brokenLinksFile?.write("\(title) : \(url) : Broken Link\n".data(using: .utf8)!)
                    }
                    semaphore.signal()
                }
                task.resume()
                semaphore.wait()
            }
        } else if type == "WebBookmarkTypeLeaf" {
            let children = bookmark["Children"] as? [[String: Any]] ?? []
            for child in children {
                checkBookmarkRecursively(child, parentTitle: title, parentURL: url, brokenLinksFile: brokenLinksFile)
            }
        }
    }
}

func checkBookmarks() {
    let bookmarksFilePath = "~/Library/Safari/Bookmarks.plist"
    let fileURL = URL(fileURLWithPath: NSString(string: bookmarksFilePath).expandingTildeInPath)
    let fileManager = FileManager.default

    if fileManager.fileExists(atPath: fileURL.path) {
        do {
            print(fileURL.path)
            let data = try Data(contentsOf: fileURL)
            let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
            guard let bookmarks = plist as? [String: Any], let children = bookmarks["Children"] as? [[String: Any]] else {
                print("Error: Failed to parse bookmarks plist")
                return
            }
            // Create a file to write broken links
            let brokenLinksFileURL = URL(fileURLWithPath: "./brokenLinks.txt")
            if let brokenLinksFile = FileHandle(forWritingAtPath: brokenLinksFileURL.path) {
                for child in children {
                    checkBookmarkRecursively(child, parentTitle: nil, parentURL: nil, brokenLinksFile: brokenLinksFile)
                }
                brokenLinksFile.closeFile()
                // Iterate through the bookmarks to check for broken links
            } else {
                perror("FileHandle error")
                // print("Error: Failed to open file for writing")
            }
            
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
