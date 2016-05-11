//
//  ViewController.swift
//  MegaminxTimer
//
//  Created by bowendeng on 5/9/16.
//  Copyright © 2016 bowendeng. All rights reserved.
// Credit:
// Create male voice with command line tool say and lame See: http://stackoverflow.com/questions/16501663/macs-say-command-to-mp3
// Created logo by makeappicon.com

import UIKit
import AVFoundation

class ViewController: UIViewController {
    // The state:
    // 0 - DNS or finish solving
    // 1 - during inspection
    // 2 - start solving
    var State = 0
    var EightSeconds: AVAudioPlayer!
    var TwelveSeconds: AVAudioPlayer!
    var startTime = NSDate()
    var endTime = NSDate()
    var experimentId = 0
    var times = [Double]()

    override func viewDidLoad() {
        super.viewDidLoad()
        State = 0
        ButtonText.setTitle("Tap to inspect", forState: .Normal)
        do {
            EightSeconds = try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("eight",ofType: "mp3")!))
            TwelveSeconds = try AVAudioPlayer(contentsOfURL: NSURL(fileURLWithPath: NSBundle.mainBundle().pathForResource("twelve", ofType: "mp3")!))
        } catch {
            print("Sound file not successfully loaded!")
        }
        generateScramble()
    }
    
    @IBOutlet weak var Scramble: UILabel!
    @IBOutlet weak var ButtonText: UIButton!
    @IBOutlet weak var NumOfSolves: UILabel!
    @IBOutlet weak var BestSingle: UILabel!
    @IBOutlet weak var TrimmedMean: UILabel!
    
    @IBAction func ButtonPressed(sender: UIButton) {
        if (State == 0) {
            State = 1
            for sec in 0...15 {
                let currExperimentId = experimentId
                delay(Double(sec)) {
                    if (self.State == 1 && self.experimentId == currExperimentId) {
                        self.ButtonText.setTitle(String(15 - sec), forState: .Normal)
                        if (sec == 8) {
                            self.EightSeconds.play()
                        } else if (sec == 12) {
                            self.TwelveSeconds.play()
                        } else if (sec == 15) {
                            self.ButtonText.setTitle("DNF", forState: .Normal)
                            self.State = 0
                        }
                    }
                }
            }
        } else if (State == 1) { // Start the timer
            State = 2
            startTime = NSDate()
            ButtonText.setTitle("Solving...", forState: .Normal)
            experimentId += 1
        } else if (State == 2) { // Stop the timer
            State = 0
            endTime = NSDate()
            var elapsedTime = endTime.timeIntervalSinceDate(startTime)
            elapsedTime = Double(round(1000 * elapsedTime) / 1000)
            times.append(elapsedTime)
            ButtonText.setTitle(String(elapsedTime), forState: .Normal)
            // Update the results
            updateResults()
        }
    }
    
    func updateResults() {
        // Update number of solves, best single and trimmed mean
        let numSolve = times.count
        NumOfSolves.text = "Number of solves: " + String(numSolve)
        let bestSingle = times.minElement()
        let worstSingle = times.maxElement()
        let totSum = times.reduce(0, combine: +)
        if numSolve > 0 {
            BestSingle.text = "Best single: " + TimeConverter(bestSingle!)
        } else {
            BestSingle.text = "Best single: N/A"
        }
        if numSolve > 2 {
            var trimmedMean = (totSum - bestSingle! - worstSingle!) / Double(numSolve - 2)
            trimmedMean = Double(round(1000 * trimmedMean) / 1000)
            TrimmedMean.text = "Trimmed mean: " + TimeConverter(trimmedMean)
        } else {
            TrimmedMean.text = "Trimmed mean: N/A"
        }
    }
    
    @IBAction func Reset(sender: UIButton) {
        if State == 0 {
            times = []
            updateResults()
        }
    }
    
    func delay(delay:Double, closure:()->()) { // Delay the following operation for delay seconds
        dispatch_after(
            dispatch_time(
                DISPATCH_TIME_NOW,
                Int64(delay * Double(NSEC_PER_SEC))
            ),
            dispatch_get_main_queue(), closure)
    }
    
    func generateScramble() {
        Scramble.text = ""
        for _ in 0..<7 {
            var currLine = ""
            for _ in 0..<5 {
                currLine += "R"
                currLine += randomBool() ? "++" : "--"
                currLine += "D"
                currLine += randomBool() ? "++" : "--"
            }
            currLine += "U"
            if randomBool() {
                currLine += "'"
            }
            currLine += "\n"
            Scramble.text = Scramble.text! + currLine
        }
    }
    
    func randomBool() -> Bool {
        return arc4random_uniform(2) == 0 ? true : false
    }
    
    func TimeConverter(rawTime: Double) -> String {
        // Returns the raw time as a beautiful string
        // e.g.
        // 10.55 -> 10.55
        // 70.55 -> 1:10.55
        let minute = Int(floor(rawTime / 60.0))
        let seconds = rawTime - Double(minute) * 60.0
        if minute == 0 {
            return String(seconds)
        } else if seconds >= 10.0 {
            return String(minute) + ":" + String(seconds)
        } else {
            return String(minute) + ": " + String(seconds)
        }
    }
}
