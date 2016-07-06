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

extension Array {
    func shuffled() -> [Element] {
        if count < 2 { return self }
        var list = self
        for i in 0..<(list.count - 1) {
            let j = Int(arc4random_uniform(UInt32(list.count - i))) + i
            if i != j {
                swap(&list[i], &list[j])
            }
        }
        return list
    }
}

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
    var mute = false

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
		pickerData = ["Megaminx", "5x5", "4x4", "2x2", "Pyraminx"]
        Event = pickerData[0]
		generateScramble()
        mute = false
	}

    @IBAction func Sound(sender: UISwitch) {
        if sender.on {
            mute = false
        } else {
            mute = true
        }
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
						if (sec == 8 && !self.mute) {
							self.EightSeconds.play()
						} else if (sec == 12 && !self.mute) {
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
        } else if (Event == "2x2") {
            generateScramblePocket()
        } else if (Event == "Pyraminx") {
			generateScramblePyraminx()
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
		// Illegal sequence:
		// Two moves with same prefix sandwiching moves with same type (same value in the dictionary
		// e.g. U Dw Uw' U2
		// U and U2 share the same prefix, and type of Dw Uw' U2 are all 1
		let prefixes = ["R", "Rw", "L", "Lw", "U", "Uw", "D", "Dw", "F", "Fw", "B", "Bw"]
		let suffixes = ["", "'", "2"]
		let typeDictionary: [String: Int] = ["R": 0, "Rw": 0, "L": 0, "Lw": 0, "U": 1, "Uw": 1, "D": 1, "Dw": 1, "F": 2, "Fw": 2, "B": 2, "Bw": 2]
		var allPrefixes = [String]()
        Scramble.text = ""
		for _ in 0..<6 {
			var currLine = ""
			for _ in 0..<10 {
				var currPrefix: String!
				var legal = false
				while !legal {
					currPrefix = prefixes[Int(arc4random_uniform(UInt32(prefixes.count)))]
					// Check if this prefix is good
					var idx = allPrefixes.count - 1
					legal = true
					while idx >= 0 && typeDictionary[allPrefixes[idx]] == typeDictionary[currPrefix] {
						if allPrefixes[idx] == currPrefix {
							legal = false
                            break
						}
                        idx -= 1
					}
				}
				allPrefixes.append(currPrefix)
				let currSuffix = suffixes[Int(arc4random_uniform(UInt32(suffixes.count)))]
				currLine += currPrefix + currSuffix
			}
			currLine += "\n"
			Scramble.text = Scramble.text! + currLine
		}
    }
    
    func generateScramblePocket() {
		let flu = 0
		let luf = 1
		let ufl = 2
		let fur = 3
		let urf = 4
		let rfu = 5
		let fdl = 6
		let dlf = 7
		let lfd = 8
		let frd = 9
		let rdf = 10
		let dfr = 11
		let bul = 12
		let ulb = 13
		let lbu = 14
		let bru = 15
		let rub = 16
		let ubr = 17
		let bld = 18
		let ldb = 19
		let dbl = 20
		let bdr = 21
		let drb = 22
		let rbd = 23
		func randomState() -> [Int] {
            var permutation = [Int]()
			for i in 0..<7 {
				permutation.append(i * 3 + Int(arc4random_uniform(3)))
			}
			let totSum = permutation.reduce(0, combine: +)
			if totSum % 3 == 1 {
				if permutation[0] % 3 == 0 {
					permutation[0] += 2
				} else {
					permutation[0] -= 1
				}
			} else if totSum % 3 == 2 {
				if permutation[0] % 3 != 2 {
					permutation[0] += 1
				} else {
					permutation[0] -= 2
				}
			}
			permutation = permutation.shuffled()
			var rtn = [Int]()
			for piece in permutation {
				rtn.append(piece)
				if piece % 3 != 2 {
					rtn.append(piece + 1)
				} else {
					rtn.append(piece - 2)
				}
				if piece % 3 == 0 {
					rtn.append(piece + 2)
				} else {
					rtn.append(piece - 1)
				}
			}
			rtn.appendContentsOf([bdr, drb, rbd])
			return rtn
		}
        func permApply(perm: [Int], position: [Int]) -> [Int] {
			// Apply permutation perm to a list position
			var rtn = [Int]()
			for i in perm {
				rtn.append(position[i])
			}
            return rtn
		}
        func permTwice(p: [Int]) -> [Int] {
            return permApply(p, position: p)
		}
        func permInverse(p: [Int]) -> [Int] {
			let n = p.count
			var q = [Int](count: n, repeatedValue: 0)
			for i in 0..<n {
				q[p[i]] = i
			}
			return q
		}
		let I = [flu, luf, ufl, fur, urf, rfu, fdl, dlf, lfd, frd, rdf, dfr, bul, ulb, lbu, bru, rub, ubr, bld, ldb, dbl, bdr, drb, rbd]
		let F = [fdl, dlf, lfd, flu, luf, ufl, frd, rdf, dfr, fur, urf, rfu, bul, ulb, lbu, bru, rub, ubr, bld, ldb, dbl, bdr, drb, rbd]
        let Fi = permInverse(F)
		let F2 = permTwice(F)
		let L = [ulb, lbu, bul, fur, urf, rfu, ufl, flu, luf, frd, rdf, dfr, dbl, bld, ldb, bru, rub, ubr, dlf, lfd, fdl, bdr, drb, rbd]
		let Li = permInverse(L)
		let L2 = permTwice(L)
		let U = [rfu, fur, urf, rub, ubr, bru, fdl, dlf, lfd, frd, rdf, dfr, luf, ufl, flu, lbu, bul, ulb, bld, ldb, dbl, bdr, drb, rbd]
		let Ui = permInverse(U)
		let U2 = permTwice(U)
		let moves = [F, Fi, F2, L, Li, L2, U, Ui, U2]
		func quarterTwistsName(move: [Int]) -> String {
			if move == F {
				return "F"
			}
			if move == Fi {
				return "F'"
			}
			if move == F2 {
				return "F2"
			}
			if move == L {
				return "L"
			}
			if move == Li {
				return "L'"
			}
			if move == L2 {
				return "L2"
			}
			if move == U {
				return "U"
			}
			if move == Ui {
				return "U'"
			}
			if move == U2 {
				return "U2"
			}
			return ""
		}
		func randomScramble() -> String {
            var scramble = [String?]()
			while true {
				scramble = shortestPath(I, end: randomState())
				if scramble.count >= 4 {
					var rtn = ""
					for move in scramble {
						rtn += move!
					}
                    return rtn
				}
			}
		}
		func permToString(perm: [Int]) -> String {
			var rtn = ""
			for i in perm {
				rtn += String(i)
				rtn += " "
			}
            return rtn
		}
		func shortestPath(start: [Int], end: [Int]) -> [String?] {
			// Build a dictionary from state represented as string to its neighbors
			var forwardParent = [String: [String?]]()
			var backwardParent = [String: [String?]]()
			forwardParent[permToString(start)] = [nil, nil]
			backwardParent[permToString(end)] = [nil, nil]
			var forwardLevel = [start]
			var backwardLevel = [end]
			var levelCount = 0
			func retrievePath(curr: String) -> [String?] {
				var rtn = [String?]()
				let tmp = curr
                var state = curr
				while state != permToString(start) {
                    rtn.append(forwardParent[state]![1]!)
					state = forwardParent[state]![0]!
				}
                rtn = rtn.reverse()
				state = tmp
				while state != permToString(end) {
					rtn.append(backwardParent[state]![1]!)
					state = backwardParent[state]![0]!
				}
				return rtn
			}
			while forwardLevel.count > 0 && backwardLevel.count > 0 && levelCount <= 7 {
				levelCount += 1
				var frontier = [[Int]]()
				for state in forwardLevel {
					if backwardParent[permToString(state)] != nil {
						return retrievePath(permToString(state))
					}
					for move in moves {
                        let neighbor = permApply(move, position: state)
						if forwardParent[permToString(neighbor)] == nil {
							forwardParent[permToString(neighbor)] = [permToString(state), quarterTwistsName(move)]
							frontier.append(neighbor)
						}
					}
				}
				forwardLevel = frontier
				frontier = []
				for state in backwardLevel {
					if forwardParent[permToString(state)] != nil {
						return retrievePath(permToString(state))
					}
					for move in moves {
                        let neighbor = permApply(permInverse(move), position: state)
						if backwardParent[permToString(neighbor)] == nil {
							backwardParent[permToString(neighbor)] = [permToString(state), quarterTwistsName(move)]
							frontier.append(neighbor)
						}
					}
				}
				backwardLevel = frontier
			}
			return [nil]
		}
        Scramble.text = randomScramble()
    }

    func generateScramblePyraminx() {
		let flr = 0
		let lrf = 1
		let rfl = 2
		let fdl = 3
		let dlf = 4
		let lfd = 5
		let fdr = 6
		let drf = 7
		let rfd = 8
		let rld = 9
		let ldr = 10
		let drl = 11
		let fr = 12
		let rf = 13
		let lf = 14
		let fl = 15
		let df = 16
		let fd = 17
		let rl = 18
		let lr = 19
		let dr = 20
		let rd = 21
		let dl = 22
		let ld = 23
		func randomCycle(nums: [Int]) -> [Int] {
			let idx = Int(arc4random_uniform(UInt32(nums.count)))
            var rtn = [Int]()
            rtn.appendContentsOf(nums[idx..<(nums.count)])
            rtn.appendContentsOf(nums[0..<idx])
            return rtn
		}
		func arePermsEqualParity(perm0: [[Int]], perm1: [[Int]]) -> Bool {
			var transCount = 0
            var tmp = perm1
			for loc in 0..<(perm0.count - 1) {
				let p0 = perm0[loc]
				let p1 = tmp[loc]
				if p0 != p1 {
                    var sloc = loc
                    for i in loc..<(tmp.count) {
                        if tmp[i] == p0 {
                            sloc = i
                            break
                        }
                    }
					tmp[loc] = p0
					tmp[sloc] = p1
					transCount += 1
				}
			}
			return transCount % 2 == 0
		}
		func randomEvenPermutation(nums: [[Int]]) -> [[Int]] {
			while true {
				let permutation = nums.shuffled()
				if arePermsEqualParity(permutation, perm1: nums) {
					return permutation
				}
			}
		}
		func randomState() -> [Int] {
			var rtn = randomCycle([flr, lrf, rfl]) + randomCycle([fdl, dlf, lfd]) + randomCycle([fdr, drf, rfd]) + randomCycle([rld, ldr, drl])
			var pieces = randomEvenPermutation([[fr, rf], [lf, fl], [df, fd], [rl, lr], [dr, rd], [dl, ld]])
			var swapCount = 0
			for piece in pieces[0..<(pieces.count - 1)] {
				if randomBool() {
					rtn += piece.reverse()
					swapCount += 1
				} else {
					rtn += piece
				}
			}
			if swapCount % 2 == 1 {
				rtn += pieces[pieces.count - 1].reverse()
			} else {
				rtn += pieces[pieces.count - 1]
			}
			return rtn
		}
        func permApply(perm: [Int], position: [Int]) -> [Int] {
			// Apply permutation perm to a list position
			var rtn = [Int]()
			for i in perm {
				rtn.append(position[i])
			}
            return rtn
		}
        func permInverse(p: [Int]) -> [Int] {
			let n = p.count
			var q = [Int](count: n, repeatedValue: 0)
			for i in 0..<n {
				q[p[i]] = i
			}
			return q
		}
		let I = [flr, lrf, rfl, fdl, dlf, lfd, fdr, drf, rfd, rld, ldr, drl, fr, rf, lf, fl, df, fd, rl, lr, dr, rd, dl, ld]
		let U = [rfl, flr, lrf, fdl, dlf, lfd, fdr, drf, rfd, rld, ldr, drl, rl, lr, fr, rf, df, fd, lf, fl, dr, rd, dl, ld]
		let Ui = permInverse(U)
		let L = [flr, lrf, rfl, lfd, fdl, dlf, fdr, drf, rfd, rld, ldr, drl, fr, rf, dl, ld, fl, lf, rl, lr, dr, rd, fd, df]
		let Li = permInverse(L)
		let R = [flr, lrf, rfl, fdl, dlf, lfd, drf, rfd, fdr, rld, ldr, drl, df, fd, lf, fl, rd, dr, rl, lr, rf, fr, dl, ld]
		let Ri = permInverse(R)
		let B = [flr, lrf, rfl, fdl, dlf, lfd, fdr, drf, rfd, drl, rld, ldr, fr, rf, lf, fl, df, fd, dr, rd, ld, dl, lr, rl]
		let Bi = permInverse(B)
		let moves = [U, Ui, L, Li, R, Ri, B, Bi]
		func quarterTwistsName(move: [Int]) -> String {
			if move == U {
				return "U"
			}
			if move == Ui {
				return "U'"
			}
			if move == L {
				return "L"
			}
			if move == Li {
				return "L'"
			}
			if move == R {
				return "R"
			}
			if move == Ri {
				return "R'"
			}
			if move == B {
				return "B"
			}
			if move == Bi {
				return "B'"
			}
			return ""
		}
		func randomScramble() -> String {
            var scramble = [String?]()
			while true {
				scramble = shortestPath(I, end: randomState())
				if scramble.count >= 6 {
					var rtn = ""
					for move in scramble {
						rtn += move!
					}
					for move in ["l", "r", "b", "u"] {
						let tmp = arc4random_uniform(3)
						if tmp == 1 {
							rtn += move
						} else if tmp == 2 {
							rtn += move + "'"
						}
					}
					return rtn
				}
			}
		}
		func permToString(perm: [Int]) -> String {
			var rtn = ""
			for i in perm {
				rtn += String(i)
				rtn += " "
			}
            return rtn
		}
		func shortestPath(start: [Int], end: [Int]) -> [String?] {
			// Build a dictionary from state represented as string to its neighbors
			var forwardParent = [String: [String?]]()
			var backwardParent = [String: [String?]]()
			forwardParent[permToString(start)] = [nil, nil]
			backwardParent[permToString(end)] = [nil, nil]
			var forwardLevel = [start]
			var backwardLevel = [end]
			var levelCount = 0
			func retrievePath(curr: String) -> [String?] {
				var rtn = [String?]()
				let tmp = curr
                var state = curr
				while state != permToString(start) {
                    rtn.append(forwardParent[state]![1]!)
					state = forwardParent[state]![0]!
				}
                rtn = rtn.reverse()
				state = tmp
				while state != permToString(end) {
					rtn.append(backwardParent[state]![1]!)
					state = backwardParent[state]![0]!
				}
				return rtn
			}
			while forwardLevel.count > 0 && backwardLevel.count > 0 && levelCount <= 6 {
				levelCount += 1
				var frontier = [[Int]]()
				for state in forwardLevel {
					if backwardParent[permToString(state)] != nil {
						return retrievePath(permToString(state))
					}
					for move in moves {
                        let neighbor = permApply(move, position: state)
						if forwardParent[permToString(neighbor)] == nil {
							forwardParent[permToString(neighbor)] = [permToString(state), quarterTwistsName(move)]
							frontier.append(neighbor)
						}
					}
				}
				forwardLevel = frontier
				frontier = []
				for state in backwardLevel {
					if forwardParent[permToString(state)] != nil {
						return retrievePath(permToString(state))
					}
					for move in moves {
                        let neighbor = permApply(permInverse(move), position: state)
						if backwardParent[permToString(neighbor)] == nil {
							backwardParent[permToString(neighbor)] = [permToString(state), quarterTwistsName(move)]
							frontier.append(neighbor)
						}
					}
				}
				backwardLevel = frontier
			}
			return [nil]
		}
        Scramble.text = randomScramble()
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
