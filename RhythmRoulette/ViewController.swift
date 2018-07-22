//
//  ViewController.swift
//  RhythmRoulette
//
//  Created by Sam Lerner on 5/20/18.
//  Copyright © 2018 Sam Lerner. All rights reserved.
//

import UIKit
import AVFoundation
import Accelerate

class ViewController: UIViewController {

    @IBOutlet weak var lChannelView: UIView!
    @IBOutlet weak var rChannelView: UIView!
    
    var lChannel: UnsafeBufferPointer<Int16>!
    var rChannel: UnsafeBufferPointer<Int16>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /*YTManager.shared.search(query: "jack mcduff") { optVids in
            guard let vids = optVids, vids.count > 0 else { print("no vids"); return }
            var vid = vids[0]
            if Util.fileExists("\(vids[0].id).wav") && vids.count > 1 { vid = vids[1] }
            print(vid.title)
            DLManager.shared.download(id: vid.id) { success in
                guard success else { print("could not download \(vid.title)"); return }
                print("success!")
            }
        }*/
        lChannelView.backgroundColor = UIColor.yellow
        rChannelView.backgroundColor = UIColor.red
        
        let id = "6YC48xLTHgg"
        let url = Util.docsDir.appendingPathComponent("\(id).wav")
        var file: AVAudioFile
        do {
            file = try AVAudioFile(forReading: url)
        } catch let error as NSError {
            print("error opening audio file: \(error)")
            return
        }
        let format = AVAudioFormat(commonFormat: .pcmFormatInt16, sampleRate: file.fileFormat.sampleRate, channels: 2, interleaved: false)!
        let buf = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: 105736192)!
        do {
            try file.read(into: buf)
        } catch let error as NSError {
            print("error reading file into buffer: \(error)")
            return
        }
        
        lChannel = UnsafeBufferPointer(start: buf.int16ChannelData?[0], count: Int(buf.frameLength))
        rChannel = UnsafeBufferPointer(start: buf.int16ChannelData?[1], count: Int(buf.frameLength))
        displayWav()
    }
    
    func fd(_ arg1: Int, _ arg2: Int) -> Double {
        return Double(arg1)/Double(arg2)
    }
    
    func displayWav() {
        let sampleCount = lChannel.count
        var lChanFl: [Float] = Array.init(repeating: 0.0, count: sampleCount)
        vDSP_vflt16(lChannel.baseAddress!, 1, &lChanFl, 1, vDSP_Length(sampleCount))
        var lChanAbs: [Float] = Array.init(repeating: 0.0, count: sampleCount)
        vDSP_vabs(&lChanFl, 1, &lChanAbs, 1, vDSP_Length(sampleCount))
        
        //for fl in lChanAbs { print(fl) }
        
//        var zeroVal = Float(Int16.max)
//        var lChanDB: [Float] = Array.init(repeating: 0.0, count: sampleCount)
//        vDSP_vdbcon(&lChanFl, 1, &zeroVal, &lChanDB, 1, vDSP_Length(sampleCount), 1)
        
        var lChanDwnSamp: [Float] = Array.init(repeating: 0.0, count: sampleCount/5000)
        var filter = [Float](repeating: 1.0/5000.0, count: 5000)
        vDSP_desamp(&lChanAbs, 5000, &filter, &lChanDwnSamp, vDSP_Length(sampleCount/5000), 5000)
        
        var rChanFl: [Float] = Array.init(repeating: 0.0, count: sampleCount)
        vDSP_vflt16(rChannel.baseAddress!, 1, &rChanFl, 1, vDSP_Length(sampleCount))
        var rChanAbs: [Float] = Array.init(repeating: 0.0, count: sampleCount)
        vDSP_vabs(&rChanFl, 1, &rChanAbs, 1, vDSP_Length(sampleCount))
        
//        var rChanDB: [Float] = Array.init(repeating: 0.0, count: sampleCount)
//        vDSP_vdbcon(&rChanFl, 1, &zeroVal, &rChanDB, 1, vDSP_Length(sampleCount), 1)
        
        var rChanDwnSamp: [Float] = Array.init(repeating: 0.0, count: sampleCount/5000)
        vDSP_desamp(&rChanAbs, 5000, &filter, &rChanDwnSamp, vDSP_Length(sampleCount/5000), 5000)
        
        let lineWidth: CGFloat = lChannelView.bounds.width / CGFloat(Double(sampleCount)) * CGFloat(5000)
        let maxHeight: CGFloat = lChannelView.bounds.height
        
        var paths: [UIBezierPath] = Array(repeating: UIBezierPath(), count: 2)
        var shapeLayers: [CAShapeLayer] = Array(repeating: CAShapeLayer(), count: 2)
        for layer in shapeLayers {
            //layer.strokeColor = UIColor.blue.cgColor
            layer.lineWidth = lineWidth
            layer.fillColor = UIColor.brown.cgColor
        }
        shapeLayers[0].strokeColor = UIColor.blue.cgColor
        shapeLayers[1].strokeColor = UIColor.green.cgColor

        for (i, (dat1, dat2)) in zip(lChanDwnSamp, rChanDwnSamp).enumerated() {
            paths[0].move(to: CGPoint(x: CGFloat(Double(i)) * lineWidth, y: lChannelView.bounds.midY))
            paths[0].addLine(to: CGPoint(x: CGFloat(Double(i)) * lineWidth, y: CGFloat(dat1/Float(Int16.max) * Float(maxHeight))))

            paths[1].move(to: CGPoint(x: CGFloat(Double(i)) * lineWidth, y: rChannelView.bounds.midY))
            paths[1].addLine(to: CGPoint(x: CGFloat(Double(i)) * lineWidth, y: CGFloat(dat2/Float(Int16.max) * Float(maxHeight))))
        }
        //paths[0].addArc(withCenter: CGPoint(x: lChannelView.bounds.midX, y: lChannelView.bounds.midY), radius: 25.0, startAngle: 0, endAngle: CGFloat(Double.pi), clockwise: true)
        
        let reflect = CGAffineTransform(scaleX: 1.0, y: -1.0)
        let translate = CGAffineTransform(translationX: 0.0, y: -lChannelView.bounds.midY)
        
        for path in paths {
            path.apply(reflect)
            path.apply(translate)
        }
        
        paths[0].stroke()
        paths[1].stroke()
        
        shapeLayers[0].path = paths[0].cgPath
        shapeLayers[1].path = paths[1].cgPath
        
        lChannelView.layer.addSublayer(shapeLayers[0])
        rChannelView.layer.addSublayer(shapeLayers[1])
    }

}

