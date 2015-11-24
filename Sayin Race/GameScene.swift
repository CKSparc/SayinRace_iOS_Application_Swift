//
//  GameScene.swift
//  Sayin Race
//
//  Created by Corinne Dunston on 10/28/15.
//  Copyright (c) 2015 CK Sparc. All rights reserved.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var broly = SKSpriteNode()
    var pipeUpTexture = SKTexture()
    var pipeDownTexture = SKTexture()
    var sceneryMoveAndRemove = SKAction()
    
    // Game Over
    var gameOver: Bool = false
    
    var scoreLabelNode = SKLabelNode()
    var score: Int = 0
    
    var gameOverLabelNode = SKLabelNode()
    var gameOverStatusNode = SKLabelNode()
    
    
    // Background
    var background: SKNode!
    var background_speed = 100.0
    
    // Time Values
    var delta = NSTimeInterval(0)
    var last_update_time = NSTimeInterval(0)
    
    // MASK
    let brolyGroup: UInt32 = 0x1 << 0
    let enemyOnjectGroup: UInt32 = 0x1 << 1
    let gap: UInt32 = 0x1 << 2
    
    enum objectsZPositions: CGFloat {
        case background = 0
        case ground = 1
        case pipes = 2
        case broly = 3
        case score = 4
        case gameOver = 5
    }
    
    
    override func didMoveToView(view: SKView) {
        /* Setup your scene here */
        
        // physics
        self.physicsWorld.contactDelegate = self
        self.physicsWorld.gravity = CGVectorMake(0.0, -5.0);
        
        // Broly
        let brolyTexture = SKTexture(imageNamed: "broly")
        brolyTexture.filteringMode = SKTextureFilteringMode.Nearest
        
        broly = SKSpriteNode(texture: brolyTexture)
        broly.setScale(0.5)
        broly.position = CGPointMake(self.frame.size.width * 0.35, self.frame.size.height * 1.0)
        broly.zPosition = objectsZPositions.broly.rawValue
        broly.physicsBody = SKPhysicsBody(circleOfRadius: broly.size.height/2.0)
        broly.physicsBody?.categoryBitMask = brolyGroup
        broly.physicsBody?.contactTestBitMask = gap | enemyOnjectGroup
        broly.physicsBody?.collisionBitMask = enemyOnjectGroup
        broly.physicsBody?.dynamic = true
        broly.physicsBody?.allowsRotation = false
        
        
        
        self.addChild(broly)
        
        // Ground
        
        let groundTexture = SKTexture(imageNamed: "ground")
        let sprite = SKSpriteNode(texture: groundTexture)
        
        sprite.setScale(2.0)
        sprite.position = CGPointMake(self.size.width / 2, sprite.size.height/2.0)
        
        self.addChild(sprite)
        
        let ground = SKNode()
        
        ground.position = CGPointMake(0, groundTexture.size().height)
        ground.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(self.frame.size.width, groundTexture.size().height * 2.0))
        ground.zPosition = objectsZPositions.ground.rawValue
        ground.physicsBody?.categoryBitMask = enemyOnjectGroup
        ground.physicsBody?.collisionBitMask = brolyGroup
        ground.physicsBody?.contactTestBitMask = brolyGroup
        ground.physicsBody?.dynamic = false
        self.addChild(ground)
        
        // Score Label Node
        
        scoreLabelNode = SKLabelNode(fontNamed: "ChalkboardSE-Bold")
        scoreLabelNode.fontSize = 50
        scoreLabelNode.fontColor = SKColor.whiteColor()
        scoreLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.height - 50)
        scoreLabelNode.text = "0"
        scoreLabelNode.zPosition = -5
        self.addChild(scoreLabelNode)
        
        
        // Scenery 
        
        // create scenery
        pipeUpTexture = SKTexture(imageNamed: "pipeUp")
        pipeDownTexture = SKTexture(imageNamed: "pipeDown")
        
        // Actions of movement of scenery 
        
        let distanceToMove = CGFloat(self.frame.size.width + 2.0 * pipeUpTexture.size().width)
        let moveScene = SKAction.moveByX(-distanceToMove, y: 0.0, duration: NSTimeInterval(0.01 * distanceToMove))
        let removeScene = SKAction.removeFromParent()
        
        sceneryMoveAndRemove = SKAction.sequence([moveScene,removeScene])
        
        // Spawn scenery
        
        let spawn = SKAction.runBlock({() in self.spawnScene()})
        let delay = SKAction.waitForDuration(NSTimeInterval(2.0))
        let spawnThenDelay = SKAction.sequence([spawn,delay])
        let spawnThenDelayForever = SKAction.repeatActionForever(spawnThenDelay)
        
        self.runAction(spawnThenDelayForever)
        
        
        initBackground()
    }
    

    
    // MARK: - Background Functions
    func initBackground() {
        
        // 1
        background = SKNode()
        addChild(background)
        
        // 2
        for i in 0...2 {
            let tile = SKSpriteNode(imageNamed: "background")
            tile.anchorPoint = CGPointZero
            tile.position = CGPoint(x: CGFloat(i) * 640.0, y: 0.0)
            tile.name = "background"
            tile.zPosition = -15
            background.addChild(tile)
        }
    }
    
    func moveBackground() {
        // 3
        let posX = -background_speed * delta
        background.position = CGPoint(x: background.position.x + CGFloat(posX), y: 0.0)
        
        // 4
        background.enumerateChildNodesWithName("background") { (node, stop) in
            let background_screen_position = self.background.convertPoint(node.position, toNode: self)
            
            if background_screen_position.x <= -node.frame.size.width {
                node.position = CGPoint(x: node.position.x + (node.frame.size.width * 2), y: node.position.y)
            }
            
        }
    }
    
    // MARK: - Frames Per Second
    override func update(currentTime: CFTimeInterval) {
        
        // 6
        delta = (last_update_time == 0.0) ? 0.0 : currentTime - last_update_time
        last_update_time = currentTime
        
        // 7
        moveBackground()
    }
    
    
    
    
    func spawnScene() {
        
        let opening = 140.0
        
        let scenePair = SKNode()
        scenePair.position = CGPointMake(self.frame.size.width + pipeUpTexture.size().width * 2, 0)
        scenePair.zPosition = -10
        
        let height = UInt32(self.frame.size.height / 4)
        let y = arc4random() % height + height
        
        let pipeDown = SKSpriteNode(texture: pipeDownTexture)
        pipeDown.setScale(2.0)
        pipeDown.position = CGPointMake(0.0, CGFloat(y) + pipeDown.size.height + CGFloat(opening))
        pipeDown.physicsBody = SKPhysicsBody(rectangleOfSize: pipeDown.size)
        pipeDown.physicsBody?.dynamic = false
        pipeDown.physicsBody?.categoryBitMask = enemyOnjectGroup
        pipeDown.physicsBody?.collisionBitMask = brolyGroup
        pipeDown.physicsBody?.contactTestBitMask = brolyGroup
        pipeDown.zPosition = objectsZPositions.pipes.rawValue
        
        scenePair.addChild(pipeDown)
        
        let pipeUp = SKSpriteNode(texture: pipeUpTexture)
        pipeUp.setScale(2.0)
        pipeUp.position = CGPointMake(0.0, CGFloat(y))
        pipeUp.physicsBody = SKPhysicsBody(rectangleOfSize: pipeUp.size)
        pipeUp.physicsBody?.dynamic = false
        pipeUp.physicsBody?.categoryBitMask = enemyOnjectGroup
        pipeUp.physicsBody?.collisionBitMask = brolyGroup
        pipeUp.physicsBody?.contactTestBitMask = brolyGroup
        pipeUp.zPosition = objectsZPositions.pipes.rawValue
        scenePair.addChild(pipeUp)
        
        
        let crossing = SKNode()
        crossing.position = CGPointMake(pipeDown.position.x + pipeDown.size.width/2, CGRectGetMidY(self.frame))
        crossing.physicsBody = SKPhysicsBody(rectangleOfSize: CGSizeMake(1, self.frame.height))
        crossing.physicsBody?.dynamic = false
        crossing.physicsBody?.categoryBitMask = gap
        crossing.physicsBody?.contactTestBitMask = brolyGroup
        scenePair.addChild(crossing)
        scenePair.runAction(sceneryMoveAndRemove)
        
        self.addChild(scenePair)
    }
    
    // MARK: - Made contact method
    
    func didBeginContact(contact: SKPhysicsContact) {
        
        if contact.bodyA.categoryBitMask == gap || contact.bodyB.categoryBitMask == gap {
            score += 1
            scoreLabelNode.text = "\(score)"
        } else if contact.bodyA.categoryBitMask == enemyOnjectGroup || contact.bodyB.categoryBitMask == enemyOnjectGroup {
            
            self.physicsWorld.contactDelegate = nil
            self.speed = 0
            self.background_speed = 0.0
            gameOver = true
            broly.removeAllActions()
            
            gameOverLabelNode = SKLabelNode(fontNamed: "Copperplate-Bold")
            gameOverLabelNode.fontSize = 45
            gameOverLabelNode.fontColor = SKColor.whiteColor()
            gameOverLabelNode.zPosition = objectsZPositions.gameOver.rawValue
            gameOverLabelNode.text = "Mazi->Game Over"
            gameOverLabelNode.position = CGPointMake(CGRectGetMidX(self.frame), CGRectGetMidY(self.frame))
            self.addChild(gameOverLabelNode)
            
            let scaleUp = SKAction.scaleTo(1.5, duration: 2)
            let scale = SKAction.scaleTo(1, duration: 0.25)
            let scaleSequence = SKAction.sequence([scaleUp,scale])
            gameOverLabelNode.runAction(scaleSequence, completion: { () -> Void in
                
//                self.gameOverStatusNode = SKLabelNode(fontNamed: "Copperplate")
//                self.gameOverStatusNode.fontSize = 30
//                self.gameOverStatusNode.fontColor = SKColor.whiteColor()
//                self.gameOverStatusNode.zPosition = objectsZPositions.score.rawValue
//                self.gameOverStatusNode.text = "Tap to restart"
//                self.gameOverStatusNode.position = CGPointMake(CGRectGetMidX(self.frame), self.frame.height - 50)
//                self.addChild(self.gameOverStatusNode)
//                
//                let scaleUp = SKAction.scaleTo(1.25, duration: 0.5)
//                let scaleBack = SKAction.scaleTo(1, duration: 0.25)
//                let wait = SKAction.waitForDuration(1.0)
//                let sequence = SKAction.sequence([wait, scaleUp, scaleBack, wait])
//                let repeats = SKAction.repeatActionForever(sequence)
//                self.gameOverStatusNode.runAction(repeats)
                
                
                
            })
            
            self.gameOverStatusNode = SKLabelNode(fontNamed: "Copperplate")
            self.gameOverStatusNode.fontSize = 30
            self.gameOverStatusNode.fontColor = SKColor.whiteColor()
            self.gameOverStatusNode.zPosition = objectsZPositions.gameOver.rawValue
            self.gameOverStatusNode.text = "Tap to restart"
            self.gameOverStatusNode.position = CGPointMake(CGRectGetMidX(self.frame),  CGRectGetMidY(self.frame) - self.gameOverStatusNode.frame.height - 30)
            self.addChild(self.gameOverStatusNode)
            
            let scaleUp2 = SKAction.scaleTo(1.25, duration: 0.5)
            let scaleBack = SKAction.scaleTo(1, duration: 0.25)
            let wait = SKAction.waitForDuration(1.0)
            let sequence = SKAction.sequence([wait, scaleUp2, scaleBack, wait])
            let repeats = SKAction.repeatActionForever(sequence)
            self.gameOverStatusNode.runAction(repeats)
        }
        
    }
    
    
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
       /* Called when a touch begins */
        
        if gameOver == false {
            
            for touch: AnyObject in touches {
                _ = touch.locationInNode(self)
                
                broly.physicsBody?.velocity = CGVectorMake(0, 0)
                broly.physicsBody?.applyImpulse(CGVectorMake(0, 25))
                
                let rotateUp = SKAction.rotateByAngle(0.2, duration: 0)
                broly.runAction(rotateUp)
            }
        }else {
                
                if let scene = GameScene(fileNamed:"GameScene") {
                    // Configure the view.
                    let skView = self.view as SKView!
                    skView.showsFPS = true
                    skView.showsNodeCount = true
                    
                    /* Sprite Kit applies additional optimizations to improve rendering performance */
                    skView.ignoresSiblingOrder = true
                    
                    /* Set the scale mode to scale to fit the window */
                    scene.scaleMode = .AspectFill
                    
                    skView.presentScene(scene)
                }
                
            }
            
        }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        if gameOver == false {
            
            for touch: AnyObject in touches {
                _ = touch.locationInNode(self)
                let rotateDown = SKAction.rotateByAngle(-0.2, duration: 0)
                broly.runAction(rotateDown)
            }
        }
    }
        
    }
    

//   
//    override func update(currentTime: CFTimeInterval) {
//        /* Called before each frame is rendered */
//    }

