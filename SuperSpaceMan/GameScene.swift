//
//  GameScene.swift
//  SuperSpaceMan
//
//  Created by Mitsushige Komiya on 2015/04/12.
//  Copyright (c) 2015年 Apress. All rights reserved.
//

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    var foregroundNode : SKSpriteNode?
    var backgroundNode : SKSpriteNode?
    var backgroundStarNode : SKSpriteNode?
    var playerNode : SKSpriteNode?
    
    let coreMosionManager = CMMotionManager()
    var xAxisAcceleration : CGFloat = 0.0
    
    var impulseCount = 4
    let CollisionCategoryPlayer : UInt32     = 0x1 << 1
    let CollisionCategoryPowerUpOrb : UInt32 = 0x1 << 2
    let CollisionCategoryBlackHoles : UInt32 = 0x1 << 3
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(size: CGSize) {
        super.init(size: size)
        
        physicsWorld.contactDelegate = self
        physicsWorld.gravity = CGVectorMake(0.0, -5.0)
        
        backgroundColor = SKColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        
        // adding the background
        backgroundNode = SKSpriteNode(imageNamed: "Background")
        backgroundNode!.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundNode!.position    = CGPoint(x: size.width / 2.0, y: 0.0)
        addChild(backgroundNode!)
        
        backgroundStarNode = SKSpriteNode(imageNamed: "Star")
        backgroundStarNode!.anchorPoint = CGPoint(x: 0.5, y: 0.0)
        backgroundStarNode!.position    = CGPoint(x: 160.0, y: 0.0)
        addChild(backgroundStarNode!)
        
        // adding the foreground
        foregroundNode = SKSpriteNode()
        addChild(foregroundNode!)
        
        // add the player
        playerNode = SKSpriteNode(imageNamed: "Player")
        playerNode!.physicsBody = SKPhysicsBody(circleOfRadius: playerNode!.size.width / 2)
        playerNode!.position = CGPoint(x: size.width / 2.0, y: 80.0)
        playerNode!.physicsBody!.dynamic = false
        playerNode!.physicsBody!.linearDamping = 1.0
        playerNode!.physicsBody!.allowsRotation = false
        playerNode!.physicsBody!.categoryBitMask = CollisionCategoryPlayer
        playerNode!.physicsBody!.contactTestBitMask = CollisionCategoryPowerUpOrb
        playerNode!.physicsBody!.collisionBitMask = 0
        foregroundNode!.addChild(playerNode!)
        
        // add power up orbs
        addOrbsToForeground()
        addBlackHolesToForeground()
    }
    
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        if !playerNode!.physicsBody!.dynamic {
            playerNode!.physicsBody!.dynamic = true
            
            coreMosionManager.accelerometerUpdateInterval = 0.3
            coreMosionManager.startAccelerometerUpdatesToQueue(NSOperationQueue(),
                withHandler: {
                    (data: CMAccelerometerData!, error: NSError!) in
                    if let constVar = error {
                        println("Invalid accelermoter error.")
                    } else {
                        self.xAxisAcceleration = CGFloat(data!.acceleration.x)
                    }
            })
        }
        
        if impulseCount > 0 {
            playerNode!.physicsBody!.applyImpulse(CGVectorMake(0.0, 40.0))
            impulseCount--
        }
    }
    
    func didBeginContact(contact: SKPhysicsContact) {
        var nodeB = contact.bodyB!.node!
        
        if nodeB.name == "POWER_UP_ORB" {
            impulseCount++
            nodeB.removeFromParent()
        }
        else if nodeB.name == "BLACK_HOLE" {
            playerNode!.physicsBody!.contactTestBitMask = 0
            impulseCount = 0
        }
    }
    
    override func update(currentTime: NSTimeInterval) {
        if playerNode!.position.y >= 180.0 {
            backgroundNode!.position =
                CGPointMake(self.backgroundNode!.position.x, -((self.playerNode!.position.y - 180.0)/8))
            foregroundNode!.position =
                CGPointMake(self.foregroundNode!.position.x, -(self.playerNode!.position.y - 180.0))
        }
    }
    
    override func didSimulatePhysics() {
        playerNode!.physicsBody!.velocity = CGVectorMake(xAxisAcceleration * 380.0, playerNode!.physicsBody!.velocity.dy)
        
        if playerNode!.position.x < -(playerNode!.size.width / 2) {
            playerNode!.position = CGPointMake(size.width - playerNode!.size.width / 2, playerNode!.position.y)
        }
        else if playerNode!.position.x > size.width {
            playerNode!.position = CGPointMake(playerNode!.size.width / 2, playerNode!.position.y)
        }
    }
    
    func addOrbsToForeground() {
        var orbNodePosition = CGPointMake(playerNode!.position.x, playerNode!.position.y + 100)
        var orbXShift : CGFloat = -1.0
        
        for i in 0...50 {
            var orbNode = SKSpriteNode(imageNamed: "PowerUp")
            
            if orbNodePosition.x - (orbNode.size.width * 2) <= 0 {
                orbXShift = 1.0
            }
            
            if orbNodePosition.x + orbNode.size.width >= self.size.width {
                orbXShift = -1.0
            }
            
            orbNodePosition.x += 40.0 * orbXShift
            orbNodePosition.y += 140
            orbNode.position = orbNodePosition
            orbNode.physicsBody = SKPhysicsBody(circleOfRadius: orbNode.size.width / 2)
            orbNode.physicsBody!.dynamic = false
            orbNode.physicsBody!.categoryBitMask = CollisionCategoryPowerUpOrb
            orbNode.physicsBody!.collisionBitMask = 0
            orbNode.name = "POWER_UP_ORB"
            
            foregroundNode!.addChild(orbNode)
        }
    }
    
    func addBlackHolesToForeground() {
        let textureAtlas = SKTextureAtlas(named: "sprites.atlas")
        
        let frame0 = textureAtlas.textureNamed("BlackHole0")
        let frame1 = textureAtlas.textureNamed("BlackHole1")
        let frame2 = textureAtlas.textureNamed("BlackHole2")
        let frame3 = textureAtlas.textureNamed("BlackHole3")
        let frame4 = textureAtlas.textureNamed("BlackHole4")

        let blackHoleTextures = [frame0, frame1, frame2, frame3, frame4]
        let animateAction     = SKAction.animateWithTextures(blackHoleTextures, timePerFrame: 0.2)
        let rotateAction      = SKAction.repeatActionForever(animateAction)
        
        let moveLeftAction  = SKAction.moveToX(0.0, duration: 2.0)
        let moveRightAction = SKAction.moveToX(size.width, duration: 2.0)
        let actionSequence  = SKAction.sequence([moveLeftAction, moveRightAction])
        let moveAction      = SKAction.repeatActionForever(actionSequence)
        
        for i in 1...10 {
            var blackHoleNode = SKSpriteNode(imageNamed: "BlackHole0")
            blackHoleNode.position = CGPointMake(size.width - 80.0, 600.0 * CGFloat(i))
            blackHoleNode.physicsBody =
                SKPhysicsBody(circleOfRadius: blackHoleNode.size.width / 2)
            blackHoleNode.physicsBody!.dynamic = false
            blackHoleNode.name = "BLACK_HOLE"
            blackHoleNode.physicsBody!.categoryBitMask = CollisionCategoryBlackHoles
            blackHoleNode.physicsBody!.collisionBitMask = 0
            blackHoleNode.runAction(moveAction)
            blackHoleNode.runAction(rotateAction)
            
            foregroundNode!.addChild(blackHoleNode)
        }
    }
    
    deinit {
        coreMosionManager.stopAccelerometerUpdates()
    }
}
