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

class ViewController: UIViewController, UIPickerViewDelegate, UIPickerViewDataSource {
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
	var pickerData: [String] = [String]()
    var Event: String!

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
		// Setup the picker options
		self.EventPicker.delegate = self
		self.EventPicker.dataSource = self
		pickerData = ["Megaminx", "5x5", "4x4"]
        Event = pickerData[0]
		generateScramble()
	}

	@IBOutlet weak var Scramble: UILabel!
	@IBOutlet weak var ButtonText: UIButton!
	@IBOutlet weak var NumOfSolves: UILabel!
	@IBOutlet weak var BestSingle: UILabel!
	@IBOutlet weak var TrimmedMean: UILabel!
    @IBOutlet weak var EventPicker: UIPickerView!

	func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
		return 1
	}

	func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
		return pickerData.count
	}

	func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
		return pickerData[row]
	}

	func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
		// http://codewithchris.com/uipickerview-example/
		// This method is triggered whenever the user makes a change to the picker selection.
		// The parameter named row and component represents what was selected.
        Event = pickerData[row]
        Reset()
        generateScramble()
	}

	@IBAction func ButtonPressed(sender: UIButton) {
		if (State == 0) {
			State = 1
			let currExperimentId = experimentId
			for sec in 0...15 {
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
			let currExperimentId = experimentId
			for sec in 0...120 {
				delay(Double(sec)) {
					if (self.experimentId == currExperimentId) {
						self.ButtonText.setTitle(self.TimeConverter(Double(sec)), forState: .Normal)
					}
				}
			}
			delay(121.0) {
				if (self.experimentId == currExperimentId) {
					self.ButtonText.setTitle("> 2 minutes", forState: .Normal)
				}
			}
		} else if (State == 2) { // Stop the timer
			experimentId += 1
			State = 0
			endTime = NSDate()
			var elapsedTime = endTime.timeIntervalSinceDate(startTime)
			elapsedTime = Double(round(1000 * elapsedTime) / 1000)
			times.append(elapsedTime)
			ButtonText.setTitle(TimeConverter(elapsedTime), forState: .Normal)
			// Update the results
			updateResults()
			generateScramble()
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

	@IBAction func ResetPressed(sender: UIButton) {
        Reset()
    }
    
    func Reset() {
		if State == 0 {
			times = []
			updateResults()
			ButtonText.setTitle("Tap to inspect", forState: .Normal)
		}
	}

	func delay(delay:Double, closure:()->()) { // Delay the following operation for delay seconds
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(delay * Double(NSEC_PER_SEC))), dispatch_get_main_queue(), closure)
	}

	func generateScramble() {
        if (Event == "Megaminx") {
            generateScrambleMegaminx()
        } else {
            generateScrambleFive()
        }
    }
    
    func generateScrambleMegaminx() {
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
    
    func generateScrambleFive() {
		let symbols = ["R2", "F", "Lw", "B'", "D2", "Dw", "R", "B", "Fw2", "F2", "Rw", "Bw'", "D", "U", "R'", "D'", "L2", "U'", "F'", "Uw2", "Dw2", "Bw", "L'", "Rw2", "B2", "Fw", "Uw'", "Rw'", "Lw'", "Bw2", "Dw'", "Lw2", "L", "Fw'", "U2"]
        Scramble.text = ""
		for _ in 0..<6 {
			var currLine = ""
			for _ in 0..<10 {
				currLine += symbols[Int(arc4random_uniform(UInt32(symbols.count)))]
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
		var seconds = rawTime - Double(minute) * 60.0
		seconds = Double(round(1000 * seconds) / 1000)
		if minute == 0 {
			return String(seconds)
		} else if seconds >= 10.0 {
			return String(minute) + ":" + String(seconds)
		} else {
			return String(minute) + ": " + String(seconds)
		}
	}
}
