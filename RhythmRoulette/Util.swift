//
//  Util.swift
//  RhythmRoulette
//
//  Created by Sam Lerner on 5/20/18.
//  Copyright © 2018 Sam Lerner. All rights reserved.
//

import Foundation

class Util {
    
    static let docsDir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    
    static func fileExists(_ filename: String) -> Bool {
        return FileManager.default.fileExists(atPath: docsDir.appendingPathComponent(filename).path)
    }
    
    static func checkDataTask(data: Data?, res: URLResponse?, err: Error?, caller: String, expStatus: Int = 200) -> Bool {
        guard err == nil else {
            Util.log(caller, "error with data task: \(err!)")
            return false
        }
        guard let r = res as? HTTPURLResponse else {
            Util.log(caller, "could not cast urlresponse to httpurl response")
            return false
        }
        let statusCode = r.statusCode
        guard statusCode == expStatus else {
            Util.log(caller, "http status code not as expected: \(statusCode)")
            return false
        }
        guard data != nil else {
            Util.log(caller, "data is nil")
            return false
        }
        return true
    }
    
    static func jsonFromUncheckedDataTask(data: Data?, res: URLResponse?, err: Error?, caller: String, expStatus: Int = 200) -> [String:AnyObject] {
        return checkDataTask(data: data, res: res, err: err, caller: caller, expStatus: expStatus) ? json(from: data!) : [String:AnyObject]()
    }
    
    static func json(from data: Data) -> [String:AnyObject] {
        var json: [String:AnyObject]? = nil
        do {
            json = try JSONSerialization.jsonObject(with: data, options: []) as? [String:AnyObject]
        } catch let error as NSError {
            Util.log("Util.JSON", "could not serialize json: \(error)")
        }
        return json ?? [String:AnyObject]()
    }
    
    static func log(_ funcName: String, _ msg: String) {
        print("\(funcName): \(msg)")
    }
    
}
