//
//  GameScene.swift
//  Coin Man
//
//  Created by JasonA Coverdale on 02/12/2017.
//  Copyright © 2017 JasonA Coverdale. All rights reserved.
//

// Version 1.0 


import SpriteKit
import GameplayKit
import AVFoundation


// **** random number generator ****
public func randomNumber<T : SignedInteger>(inRange range: ClosedRange<T> = 1...6) -> T {
    let length = Int64(range.upperBound - range.lowerBound + 1)
    let value = Int64(arc4random()) % length + Int64(range.lowerBound)
    return T(value)
}

extension Collection {
    func randomItem() -> Self.Iterator.Element {
        let count = distance(from: startIndex, to: endIndex)
        let roll = randomNumber(inRange: 0...count-1)
        return self[index(startIndex, offsetBy: roll)]
    }
}
// ************************************

struct GameSceneDismissControl {
    // to be used to segue to intial view
    static var gamescene_delegate : GameOverDelegate?
}

@objc protocol GameOverDelegate {
    func gameOverDelegateFunc()
}

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // create a player for the background music
    var player = AVAudioPlayer()
    var playerLoaded = false
    
    // add as class property so sound is preloaded and always ready
    let explosionSound = SKAction.playSoundFileNamed("grenade.mp3", waitForCompletion: false)
    let wooshSound = SKAction.playSoundFileNamed("Woosh.mp3", waitForCompletion: false)
    let dohSound = SKAction.playSoundFileNamed("Doh.mp3", waitForCompletion: false)
    
    /* **** create the variables for the:
     coinMan, ceiling, ground, explosion, grass **** */
    var coinMan: SKSpriteNode?
    var ceiling: SKSpriteNode?
    var ground: SKSpriteNode?
    let bombExplosion = SKSpriteNode(imageNamed: "explosion")
    let sizingGrass = SKSpriteNode(imageNamed: "grass")
    var minusNumImage: SKSpriteNode? 
    
    // values for explosion contact position
    var explosionX: CGFloat = 0
    var explosionY: CGFloat = 0
    
    // create the timers
    var coinTimer: Timer?
    var bombTimer: Timer?
    var bombTypeTimer: Timer?
    
    // var to change the bomb type
    var bombType = "bomb"
    
    // test for game over
    var gamOverTest = false
    
    // create the labels
    var scoreLabel: SKLabelNode?
    var yourScoreLabel: SKLabelNode?
    var finalScoreLabel: SKLabelNode?
    var highScoreLabel: SKLabelNode?
    
    // create the categories for the objects
    let coinManCategory: UInt32 = 0x1 << 1  // binary value = 1 - 1
    let coinCategory: UInt32 = 0x1 << 2     // binary value = 2 - 10
    let bombCategory: UInt32 = 0x1 << 3     // binary value = 4 - 100
    let groundAndCeilingCatagory: UInt32 = 0x1 << 4  // binary value = 8 - 1000
    let grassCagagory: UInt32 = 0x1 << 5 // binary value = 16 - 10000
    
    
    
    
    // **************n Inital load up method *******************
    override func didMove(to view: SKView) {
        
        // allow the game to work on multiple devices and render correctly
        
        // 1. request an UITraitCollection instance
        let deviceIdiom = UIScreen.main.traitCollection.userInterfaceIdiom
        
        // 2. check the idiom
        switch (deviceIdiom) {
            
        case .pad:
            // iPad style UI
            scene?.scaleMode = SKSceneScaleMode.aspectFit
        case .phone:
            // iPhone and iPod touch style UI
            print("iphone")
        case .tv:
            // tvOS style UI
            print("tv")
        default:
            // Unspecified UI idiom
            print("u/k")
        }
        
        
        physicsWorld.contactDelegate = self
        
        // ******* set up the coinMan ********
        coinMan = childNode(withName: "coinMan") as? SKSpriteNode
        // add the category to coinMan
        coinMan?.physicsBody?.categoryBitMask = coinManCategory
        // set who the coinMan is going to make contact with
        coinMan?.physicsBody?.contactTestBitMask = coinCategory | bombCategory
        // only allow coinMan to collied with ground & celing
        coinMan?.physicsBody?.collisionBitMask = groundAndCeilingCatagory
        
        // ****** CoinMan array ********
        var coinManRun: [SKTexture] = []
        for number in 1...5 {
            coinManRun.append(SKTexture(imageNamed: "runningMan-\(number)"))
        }
        SKAction.repeatForever(SKAction.animate(with: coinManRun, timePerFrame: 0.11))
        coinMan?.run(SKAction.repeatForever(SKAction.animate(with: coinManRun, timePerFrame: 0.11)))
        
        // ****** set up the celing ********
        ceiling = childNode(withName: "ceiling") as? SKSpriteNode  // sets it to the ceiling object
        ceiling?.physicsBody?.categoryBitMask = groundAndCeilingCatagory
        ceiling?.physicsBody?.collisionBitMask = coinManCategory
        
        // ******** set up the ground *******
        ground = childNode(withName: "floor") as? SKSpriteNode // set the floor to run on
        ground?.physicsBody?.categoryBitMask = groundAndCeilingCatagory
        ground?.physicsBody?.collisionBitMask = coinManCategory
        
        // ******* set up the background ******
        let backGround = SKSpriteNode(imageNamed: "background")
        backGround.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backGround.size.height = size.height 
        backGround.size.width = size.width
        backGround.zPosition = -1
        addChild(backGround)
        
        // ****** set up the labels *******
        scoreLabel = childNode(withName: "scoreLabel") as? SKLabelNode
        highScoreLabel = childNode(withName: "highScoreLabel") as? SKLabelNode
        
        //***** update the score labels from the variable****
        highScoreLabel?.text = "\(ScoreControl.highScore)"
        scoreLabel?.text = "Score: \(ScoreControl.score)"
        
        // **** test when the app enteers back or foreground ****
        let app = UIApplication.shared
        
        //application went into background
        let notificationCenter = NotificationCenter.default
        notificationCenter.addObserver(self, selector: #selector(appMovedToBackground), name: Notification.Name.UIApplicationWillResignActive, object: app)
        
        //application became active
        let notificationCenter2 = NotificationCenter.default
        notificationCenter2.addObserver(self, selector: #selector(appMovedToForeground), name: Notification.Name.UIApplicationDidBecomeActive, object: app)
        
        // set gravity
        self.physicsWorld.gravity = CGVector(dx: 0, dy: -20)
        
        // ******* start the timers ********
        beginTimers()
        createGrass()
        loadMusic()
    }
    
    // ***** Method to Create the background music *****
    func loadMusic() {
        
        // loads the music and allows us to reset it
        if let audioPath = Bundle.main.path(forResource: "Computer-melody-80s-style", ofType: "mp3") {
            
            do {
                try player = AVAudioPlayer(contentsOf: URL(fileURLWithPath: audioPath))
                // this overrides the ringer on silent mode
                try AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryPlayback)
                playerLoaded = true
            } catch let error as NSError {
                print(error)
            }
        }
        
        // test if the sound is paused
        if SoundControl.soundPaused {
            
            if playerLoaded {
                player.pause()
            }
            
        } else {
            // sound is not paused we want it playing
            if playerLoaded {
                player.play()
                player.volume = 0.5 // so its not blasting out
                player.numberOfLoops = -1 // runs on constant loop
            }
        }
    }
    
    // ***********  Create Grass Method ***********
    func createGrass() {
        
        // find the number of grass images we need to fill the screen
        let numberOfGrass = Int(size.width / sizingGrass.size.width) + 1
        
        // loop over the number and add a new object for each number
        for number in 0...numberOfGrass {
            // create a new grass object each loop
            let grass = SKSpriteNode(imageNamed: "grass")
            
            // apply the physics
            grass.physicsBody = SKPhysicsBody(rectangleOf: grass.size)
            grass.physicsBody?.categoryBitMask = grassCagagory
            //grass.physicsBody?.collisionBitMask = coinCategory
            grass.physicsBody?.affectedByGravity = false
            grass.physicsBody?.isDynamic = false
            
            // add the grass to the screen
            addChild(grass)
            
            // set the grass position
            let grassX = (-size.width / 2 + grass.size.width / 2) + (grass.size.width * CGFloat(number))
            let grassY = -size.height / 2 + ((grass.size.height / 2))
            grass.position = CGPoint(x: grassX, y: grassY)
            
            // set the movement of the grass
            let speed = 100.0
            let firstMoveLeft = SKAction.moveBy(x: -grass.size.width - grass.size.width * CGFloat(number), y: 0, duration: TimeInterval(grass.size.width + grass.size.width * CGFloat(number)) / speed)
            
            // reset the grass
            let resetGrass = SKAction.moveBy(x: size.width + grass.size.width, y: 0, duration: 0)
            let grassFullMove = SKAction.moveBy(x: -size.width - grass.size.width, y: 0, duration: TimeInterval(size.width + grass.size.width) / speed)
            let grassMovingForever = SKAction.repeatForever(SKAction.sequence([grassFullMove, resetGrass]))
            
            grass.run(SKAction.sequence([firstMoveLeft, resetGrass, grassMovingForever]) )
        }
    }
    
    // ********** create the explosion ***********
    func explosionAfterBomb() {
        
        // pause the background music
        if playerLoaded {
            player.pause()
        }
        
        // ******* set up the explosion ******
        // set the position where the bomb contacts the coinMan
        bombExplosion.position = CGPoint(x: explosionX + bombExplosion.size.width / 2, y: explosionY)
        
        // adds the picture and the sound
        run(explosionSound)
        addChild(bombExplosion)
        
        _ = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false) { (timer) in
            
            self.bombExplosion.removeFromParent()
            self.gameOver()
        }
    }
    
    // *************** timer method ****************
    func beginTimers() {
        
        // function to create coins every 1 second and keep repeating
        coinTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true, block: { (timer) in
            // call the coin method
            self.createCoin()
        })
        
        // function to create bombs every 1 second and keep repeating
        bombTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true, block: { (timer) in
            // call the coin method
            self.createBomb()
        })
        
        bombTypeTimer = Timer.scheduledTimer(withTimeInterval: TimeInterval(randomNumber(inRange: 2...3)), repeats: true, block: { (timer) in
            
            self.changeBombType()
        })
    }
    
    // ************* method to detect the contact *****************
    func didBegin(_ contact: SKPhysicsContact) {
        
        // detect which body the bomb is
        if contact.bodyA.categoryBitMask == bombCategory {
            
            // find the contact position
            explosionX = contact.contactPoint.x
            explosionY = contact.contactPoint.y
            
            // get rid of the node
            contact.bodyA.node?.removeFromParent()
            
            if contact.bodyA.node?.name == "dynamiteBomb" {
                playerHitDynamite()
            } else {
                // end the game
                explosionAfterBomb()
            }
        }
        
        if contact.bodyB.categoryBitMask == bombCategory {
            
            // find the contact position
            explosionX = contact.contactPoint.x
            explosionY = contact.contactPoint.y
            
            // get rid of the node
            contact.bodyB.node?.removeFromParent()
            
            if contact.bodyB.node?.name == "dynamiteBomb" {
                playerHitDynamite()
            } else {
                // end the game
                explosionAfterBomb()
            }
        }
        
        // ***** detect which body the coin is *****
        if contact.bodyA.categoryBitMask == coinCategory {
            // increase the score & update the label
            ScoreControl.score += 1
            scoreLabel?.text = "Score: \(ScoreControl.score)"
            //play the sound
            run(wooshSound)
            // get rid of the node
            contact.bodyA.node?.removeFromParent()
        }
        if contact.bodyB.categoryBitMask == coinCategory {
            // increase the score & update the label
            ScoreControl.score += 1
            scoreLabel?.text = "Score: \(ScoreControl.score)"
            run(wooshSound)
            // get rid of the node
            contact.bodyB.node?.removeFromParent()
        }
    }
    
    func playerHitDynamite() {
        
        // get random num between 1 & 3 for the image
        let ranImageNumber = randomNumber(inRange: 1...3)
        
        minusNumImage = SKSpriteNode(imageNamed: "minus-\(ranImageNumber)")
        
        // set the position for the image where the dynamite contacts the coinMan
        minusNumImage?.position = CGPoint(x: explosionX + (minusNumImage?.size.width)! / 2, y: explosionY)
        
        // adds the picture and the sound
        run(dohSound)
        addChild(minusNumImage!)
        
        // reduce the score by 1 if its greater the 0
        if ScoreControl.score >= ranImageNumber {
            ScoreControl.score -= ranImageNumber
            scoreLabel?.text = "Score: \(ScoreControl.score)"
        } else {
            ScoreControl.score = 0
            scoreLabel?.text = "Score: \(ScoreControl.score)"
        }
        
        // remove the image
        _ = Timer.scheduledTimer(withTimeInterval: 0.8, repeats: false) { (timer) in
            
            self.minusNumImage?.removeFromParent()
        }
    }
    
    
    func updateHiScore() {
        
        // test the high score
        if ScoreControl.score > ScoreControl.highScore {
            
            let newHiScore = ScoreControl.score
            
            // update the hi score variable
            ScoreControl.highScore = newHiScore
            
            // update the label
            highScoreLabel?.text = "\(ScoreControl.highScore)"
            
            // ***** updates the default storage ******
            let defaults = UserDefaults.standard
            defaults.set(ScoreControl.highScore, forKey: DefaultsKeys.playerHighScore)
        }
    }
    
    // **************** Game Over method ***********************
    func gameOver() {
        
        // remove the remaining bomb by Removing Specific Children
        for child in self.children {
            
            //Determine Details
            if child.name == "gameBomb" {
                child.removeFromParent()
            }
            if child.name == "dynamiteBomb" {
                child.removeFromParent()
            }
        }
        
        // pause the game
        scene?.isPaused = true
        
        // set the gameOvertest
        gamOverTest = true
        
        // stop the timers
        coinTimer?.invalidate()
        bombTimer?.invalidate()
        bombTypeTimer?.invalidate()
        
        // *** create a final score labels ***
        yourScoreLabel = SKLabelNode(text: "Your Score:")
        yourScoreLabel?.position = CGPoint(x: 0, y: 200)
        yourScoreLabel?.fontName = "HelveticaNeue-Bold"
        yourScoreLabel?.fontColor = UIColor.black
        yourScoreLabel?.fontSize  = 150
        yourScoreLabel?.zPosition = 1
        if yourScoreLabel != nil {
            addChild(yourScoreLabel!)
        }
        
        finalScoreLabel = SKLabelNode(text: "\(ScoreControl.score)")
        finalScoreLabel?.position = CGPoint(x: 0, y: 0)
        finalScoreLabel?.fontName = "Helvetica"
        finalScoreLabel?.fontColor = UIColor.black
        finalScoreLabel?.fontSize  = 200
        finalScoreLabel?.zPosition = 1
        if finalScoreLabel != nil {
            addChild(finalScoreLabel!)
        }
        
        // *** create and add the play button ***
        let playButton = SKSpriteNode(imageNamed: "play")
        playButton.name = "playBut"
        playButton.position = CGPoint(x: 0, y: -200)
        playButton.zPosition = 1
        addChild(playButton)
        
        // *** Add the back button ***
        let backButton = SKSpriteNode(imageNamed: "back")
        backButton.name = "backBtn"
        backButton.position = CGPoint(x: 0, y: -250 - playButton.size.height)
        backButton.zPosition = 1
        addChild(backButton)
        
        // update the high score
        updateHiScore()
    }
    
    // **************** Create the coins ***********************
    func createCoin()  {
        
        // create the coin from the saved image
        let coin = SKSpriteNode(imageNamed: "coin")
        coin.name = "gameCoin"
        
        // create the physicsBody for the coin
        coin.physicsBody = SKPhysicsBody(rectangleOf: coin.size)
        // create the bitmask fo the coin via the category
        coin.physicsBody?.categoryBitMask = coinCategory
        // set who the coin is going to make contact with
        coin.physicsBody?.contactTestBitMask = coinManCategory
        // stop the coins being affected by gravity
        coin.physicsBody?.affectedByGravity = false
        // stop the coin colliding with anything
        coin.physicsBody?.collisionBitMask = 0
        
        // add it to the screen
        addChild(coin)
        
        // set the max & min y positions
        let maxY = (size.height / 2) - (coin.size.height / 2)
        let minY = (-size.height / 2) + (coin.size.height / 2) + (sizingGrass.size.height)
        
        // get the difference between maxY & minY
        let range = maxY - minY
        
        // get a random value from these values
        let coinY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        
        // set the starting position of the coin
        coin.position = CGPoint(x: (size.width / 2) + (coin.size.width / 2), y: coinY)
        
        // ceate an action for the coin
        let moveLeft = SKAction.moveBy(x: -size.width - coin.size.width, y: 0, duration: 4)
        
        // run the action
        coin.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    
    func changeBombType() {
        
        _ = Timer.scheduledTimer(withTimeInterval: TimeInterval(randomNumber(inRange: 0...1)), repeats: false, block: { (timer) in
            
            // change the bomb image
            self.bombType = "dynamite"
            
            // change the bomb back after a second
            // after one second the bomb image returns to normal
            _ = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false, block: { (timer) in
                
                self.bombType = "bomb"
            })
        })
    }
    
    // **************** Create the bombs ***********************
    func createBomb() {
        /* for explanations of the method lines see the createCoin
         because its the same code with the initial name changed */
        
        // create the bomb from the saved images
        let bomb = SKSpriteNode(imageNamed: bombType)
        
        // change the name of the bomb for detection
        if bombType == "dynamite" {
            bomb.name = "dynamiteBomb"
        } else {
            bomb.name = "gameBomb"
        }
        
        bomb.physicsBody = SKPhysicsBody(rectangleOf: bomb.size)
        bomb.physicsBody?.categoryBitMask = self.bombCategory
        bomb.physicsBody?.contactTestBitMask = self.coinManCategory
        bomb.physicsBody?.affectedByGravity = false
        bomb.physicsBody?.collisionBitMask = 0
        
        // add it to the screen
        addChild(bomb)
        
        // set the max & min y positions
        let maxY = (size.height / 2) - (bomb.size.height / 2)
        let minY = (-size.height / 2) + (bomb.size.height / 2) + (sizingGrass.size.height)
        let range = maxY - minY
        let bombY = maxY - CGFloat(arc4random_uniform(UInt32(range)))
        bomb.position = CGPoint(x: (size.width / 2) + (bomb.size.width / 2), y: bombY)
        let moveLeft = SKAction.moveBy(x: -size.width - bomb.size.width, y: 0, duration: 3.2)
        bomb.run(SKAction.sequence([moveLeft, SKAction.removeFromParent()]))
    }
    
    // ***************** Detect touches on the screen ******************
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        // apply physics to the coin man and test if the game is paused
        if scene?.isPaused == false {
            coinMan?.physicsBody?.applyForce(CGVector(dx: 0, dy: 100_000))
            
        }
        // detect the touch on the play button
        let touch = touches.first
        if let location = touch?.location(in: self) {
            // get the node where the touch occured
            let theNode = nodes(at: location)
            // loop through the touches
            for node in theNode {
                
                if node.name == "playBut" {
                    // restart the game
                    node.removeFromParent() // removes the play button
                    finalScoreLabel?.removeFromParent()
                    yourScoreLabel?.removeFromParent()
                    scene?.isPaused = false // unpause the game
                    gamOverTest = false  // change the state back
                    
                    // reset the score variable to 0
                    ScoreControl.score = 0
                    // update the score label from the variable
                    scoreLabel?.text = "Score: \(ScoreControl.score)"
                    
                    // remove the backButton testing for Specific Children
                    for child in self.children {
                        //Determine Details
                        if child.name == "backBtn" {
                            child.removeFromParent()
                        }
                    }
                    
                    // test if the sound has been turned off
                    if !SoundControl.soundPaused {
                        // sound is on
                        if playerLoaded {
                            player.play()
                            player.volume = 0.5
                            player.numberOfLoops = -1
                        } else {
                            // if sound is on an player not loaded
                            loadMusic()
                        }
                    }
                    // start the timers
                    beginTimers()
                }
                if node.name == "backBtn" {
                    
                    goToInitialView()
                }
            }
        }
    }
    
    func goToInitialView() {
        // calls the function to action the segue
        GameSceneDismissControl.gamescene_delegate?.gameOverDelegateFunc()
    }
    
    // ***** runs when app moves to backgrond ****
    @objc func appMovedToBackground() {
        
        // pause the game
        scene?.isPaused = true
        // stop the timers
        coinTimer?.invalidate()
        bombTimer?.invalidate()
        bombTypeTimer?.invalidate()
        
    }
    
    @objc func appMovedToForeground() {
        // app re-appeared
        
        if gamOverTest {
            // game is over
            scene?.isPaused = true
            if SoundControl.soundPaused {
                player.pause()
            }
        } else {
            // game is not over
            scene?.isPaused = false // restart game
            // start the timers
            beginTimers()
            if SoundControl.soundPaused {
                player.pause()
            }
        }
    }
    
    
    override func update(_ currentTime: TimeInterval) {
        // Called before each frame is rendered
    }
}
