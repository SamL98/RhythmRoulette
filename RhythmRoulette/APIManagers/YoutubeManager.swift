//
//  YoutubeManager.swift
//  RhythmRoulette
//
//  Created by Sam Lerner on 5/20/18.
//  Copyright © 2018 Sam Lerner. All rights reserved.
//

import Foundation

class YTManager {
    
    typealias ytVid = (id: String, title: String)
    
    static let shared = YTManager()
    private struct credentials {
        static let api_key = "AIzaSyBf0JQBESUEPazGzXlAPo5_62BTVFJUxiE"
    }
    private let base_url = "https://www.googleapis.com/youtube/v3/"
    private let url_sess = URLSession(configuration: .default)
    
    func search(query: String, comp: @escaping ([ytVid]?) -> Void) {
        let funcName = "YOUTUBE SEARCH"
        let params: [String:String] = [
            "part": "snippet",
            "maxResults": "25",
            "type": "video",
            "q": query,
            "key": credentials.api_key
        ]
        var comps = URLComponents(string: "\(base_url)search")!
        var queryItems = [URLQueryItem]()
        for (k, v) in params {
            queryItems.append(URLQueryItem(name: k, value: v))
        }
        comps.queryItems = queryItems
        
        url_sess.dataTask(with: comps.url!, completionHandler: { (data, res, err) in
            let json = Util.jsonFromUncheckedDataTask(data: data, res: res, err: err, caller: funcName)
            guard let items = json["items"] as? [[String:AnyObject]] else {
                Util.log(funcName, "no items key in json")
                comp(nil); return
            }
            let vids = items.map({ self.parseItem($0) }) as [ytVid?]
            let filteredVids = vids.filter({ $0 != nil }) as! [ytVid]
            comp(filteredVids)
        }).resume()
    }
    
    func parseItem(_ item: [String:AnyObject]) -> ytVid? {
        let funcName = "PARSE ITEM"
        guard let idDict = item["id"] as? [String:AnyObject]
            , let snippet = item["snippet"] as? [String:AnyObject] else {
            Util.log(funcName, "no id dict or snippet in item dict")
            return nil
        }
        guard let id = idDict["videoId"] as? String
            , let title = snippet["title"] as? String else {
            Util.log(funcName, "no video id in id dict or title in snippet")
            return nil
        }
        return (id: id, title: title)
    }
    
}
