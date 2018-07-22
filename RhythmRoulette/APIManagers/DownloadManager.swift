//
//  DownloadManager.swift
//  RhythmRoulette
//
//  Created by Sam Lerner on 5/20/18.
//  Copyright © 2018 Sam Lerner. All rights reserved.
//

import Foundation

class DLManager {
    
    static let shared = DLManager()
    private let base_url = "http://localhost:5000"
    private let url_sess = URLSession(configuration: .default)
    
    func download(id: String, comp: @escaping (Bool) -> Void) {
        let funcName = "YT DOWNLOAD"
        url_sess.configuration.timeoutIntervalForRequest = 60.0
        url_sess.configuration.timeoutIntervalForResource = 60.0
        url_sess.dataTask(with: URL(string: "\(base_url)/download?id=\(id)")!, completionHandler: { (data, res, err) in
            guard Util.checkDataTask(data: data, res: res, err: err, caller: funcName) else { comp(false); return }
            do {
                let url = Util.docsDir.appendingPathComponent("\(id).wav")
                try NSData(data: data!).write(to: url, options: [])
            } catch let error as NSError {
                Util.log(funcName, "error writing file to url: \(error)")
            }
            comp(true)
        }).resume()
    }
    
}
