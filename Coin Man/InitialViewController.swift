//
//  InitialViewController.swift
//  Coin Man
//
//  Created by JasonA Coverdale on 08/12/2017.
//  Copyright © 2017 JasonA Coverdale. All rights reserved.
//

import UIKit
import AudioToolbox

struct DefaultsKeys {
    // to store the high score
    static let playerHighScore = "HiScore"
    
    // to store the sound on / off
    static let soundOnOff = "SoundOnOff"
    
    static let defaults = UserDefaults.standard
}

struct SoundControl {
    // to store the sound state
    static var soundPaused = false
}

struct ScoreControl {
    // create a var to hold the score
    static var score = 0
    static var highScore = 0
}


class InitialViewController: UIViewController {
    
    @IBOutlet weak var highScoreLabel: UILabel!
    
    @IBOutlet weak var soundButton: UIButton!
    
    var btnImage: UIImage?
    
    
    // **** Method to play sounds ****
    func playSoundClip (filename: String, ext: String) {
        
        if let soundUrl = Bundle.main.url(forResource: filename, withExtension: ext) {
            
            var soundId: SystemSoundID = 0
            
            AudioServicesCreateSystemSoundID(soundUrl as CFURL, &soundId)
            
            AudioServicesAddSystemSoundCompletion(soundId, nil, nil, { (soundId, clientData) -> Void in
                AudioServicesDisposeSystemSoundID(soundId)
            }, nil)
            
            AudioServicesPlaySystemSound(soundId)
        }
    }
    
    @IBAction func soundOnOrOff(_ sender: Any) {
        
        if SoundControl.soundPaused {
            
            btnImage = UIImage(named: "speakerOn")
            soundButton.setBackgroundImage(btnImage, for: [])
            SoundControl.soundPaused = false
            playSoundClip (filename: "ButtonClickOff", ext: "mp3") // calls the sound
        } else {
            btnImage = UIImage(named: "speakerOff")
            soundButton.setBackgroundImage(btnImage, for: [])
            SoundControl.soundPaused = true
            playSoundClip (filename: "ButtonClickOff", ext: "mp3")
        }
        // ***** updates the default storage ******
        DefaultsKeys.defaults.set(SoundControl.soundPaused, forKey: DefaultsKeys.soundOnOff)
    }
    
    @IBAction func resetHighScore(_ sender: Any) {
        
        let alertController = UIAlertController(title: "Reset High Score!", message: "Are you sure?", preferredStyle: .alert)
        
        alertController.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action) in
            // code can be put here to do an action
            self.updateHighScore()
        }))
        alertController.addAction(UIAlertAction(title: "No", style: .default, handler: nil))
        
        self.present(alertController, animated: true, completion: nil)
    }
    
    func updateHighScore() {
        
        let updateScore = 0
        
        // update the variables
        ScoreControl.highScore = updateScore
        ScoreControl.score = updateScore
        
        // updates the storage
        DefaultsKeys.defaults.set(ScoreControl.highScore, forKey: DefaultsKeys.playerHighScore)
        
        // update the label
        highScoreLabel.text = String(ScoreControl.highScore)
        
    }
    
    @IBAction func play(_ sender: Any) {
        // play button segues to game
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // not used we use view did appear
    }
    
    func highScoreInitialTest() {
        
        // get the current high score from storage
        if let newHighScore = DefaultsKeys.defaults.object(forKey: DefaultsKeys.playerHighScore) {
            // update the high score with the saved data
            if let newScore = newHighScore as? Int {
                
                // update the variable
                ScoreControl.highScore = newScore
            }
        }
        // update the label
        highScoreLabel.text = String(ScoreControl.highScore)
    }
    
    
    func testInitialButtonState() {
        
        //*** get the sound on/off from defaults
        
        if let testSoundOff = DefaultsKeys.defaults.object(forKey: DefaultsKeys.soundOnOff) {
            
            // set the bool the value
            if let isSoundOff = testSoundOff as? Bool {
                
                if isSoundOff {
                    // sound is off
                    
                    SoundControl.soundPaused = isSoundOff
                    
                    // set the button image based on the soundPaused
                    btnImage = UIImage(named: "speakerOff")
                    soundButton.setBackgroundImage(btnImage, for: [])
                } else {
                    // sound is on
                    
                    // update the variable
                    SoundControl.soundPaused = isSoundOff
                    // change the buttons
                    btnImage = UIImage(named: "speakerOn")
                    soundButton.setBackgroundImage(btnImage, for: [])
                }
            }
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        highScoreInitialTest()
        testInitialButtonState()
        
        // make sure the score is set to 0
        ScoreControl.score = 0
    }
}





