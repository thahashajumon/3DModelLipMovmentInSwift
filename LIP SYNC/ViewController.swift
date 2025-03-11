//
//  ViewController.swift
//  LIP SYNC
//
//  Created by actionfi on 04/02/25.
//

import UIKit
import SceneKit
import AVFoundation

class ViewController: UIViewController {
    @IBOutlet weak var sceneView: SCNView!
    var scene: SCNScene!
    var audioRecorder: AVAudioRecorder?
    var audioSession = AVAudioSession.sharedInstance()
    var timer: Timer?
    override func viewDidLoad() {
        super.viewDidLoad()
        load3dModel()
        checkAudioPermission()
        audioRecorder?.record()
        timer = Timer.scheduledTimer(timeInterval: 0.1,
                                     target: self,
                                     selector: #selector(updateLipSync),
                                     userInfo: nil,
                                     repeats: true)
    }
    
    func printAllNodes(node: SCNNode, level: Int = 0) {
        let indent = String(repeating: "  ", count: level) // Indentation for hierarchy
        print("\(indent)- \(node.name ?? "Unnamed Node")")

        for child in node.childNodes {
            printAllNodes(node: child, level: level + 1) // Recursive call for child nodes
        }
    }
    
    func load3dModel(){
        
        // 1: load file
        scene = SCNScene(named: "LAADFY.usdz")
        print("Printing all nodes in the scene:")
        printAllNodes(node: scene.rootNode)
//        scene.rootNode.scale = SCNVector3(1.0, 1.0, 1.0)
        //2: Add camera node
        let cameraNode = SCNNode()
        cameraNode.camera = SCNCamera()
        // 3: Place camera
        cameraNode.position = SCNVector3(x: 0, y: 300, z: 60)  //SCNVector3(x: 0, y: 10, z: 35)
        // 4: Set camera on scene
        scene.rootNode.addChildNode(cameraNode)
        
        // 5: Adding light to scene
        let lightNode = SCNNode()
        lightNode.light = SCNLight()
        lightNode.light?.type = .ambient
        lightNode.position = SCNVector3(x: 0, y: 0, z: 0)
        scene.rootNode.addChildNode(lightNode)
        
        // 6: Creating and adding ambien light to scene
        let ambientLightNode = SCNNode()
        ambientLightNode.light = SCNLight()
        ambientLightNode.light?.type = .ambient
        ambientLightNode.light?.color = UIColor.darkGray
        scene.rootNode.addChildNode(ambientLightNode)
        sceneView.allowsCameraControl = true
        sceneView.backgroundColor = UIColor.white
        sceneView.cameraControlConfiguration.allowsTranslation = false
        sceneView.scene = scene
        scene.rootNode.enumerateChildNodes { (node, _) in
            node.removeAllAnimations() // Stop all animations in the scene
        }
//        animateMuscle(muscleName: "n75", scene: scene)
//        animateMuscle(muscleName: "n77", scene: scene)
        if let mouthNode = scene.rootNode.childNode(withName: "n75", recursively: true) {
            print("Children :")
            for child in mouthNode.childNodes {
                print("- \(child.name ?? "Unnamed Child")")
            }
        }
        
    }
    func animateMuscle(muscleName: String,scene: SCNScene){
        if let mouthNode = scene.rootNode.childNode(withName: muscleName, recursively: true) {
            let moveDown = SCNAction.moveBy(x: -0.3, y: 0, z: 0, duration: 0.1)
            let moveUp = SCNAction.moveBy(x: 0.3, y: 0, z: 0, duration: 0.1)
            let sequence = SCNAction.sequence([moveDown,moveUp])
            let repeatAction = SCNAction.repeat(sequence, count: 2)
            mouthNode.runAction(repeatAction)
            print("Animating: \(mouthNode.name ?? "Unknown")")
        }else{
            print("Mouth bone not found!")
        }
    }
    
    func checkAudioPermission(){
        switch audioSession.recordPermission {
        case .undetermined:
            setUpAudio()
        case .denied:
            print("denied")
        case .granted:
            setUpAudio()
        @unknown default:
            print("default")
        }
    }
    func setUpAudio(){
        do{
            try audioSession.setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
            try audioSession.setActive(true)
            let settings: [String: Any] = [
                AVFormatIDKey: kAudioFormatAppleLossless,
                AVSampleRateKey: 16000,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            let audioUrl = getAudioURL()
            audioRecorder = try AVAudioRecorder(url: audioUrl, settings: settings)
            audioRecorder?.isMeteringEnabled = true
        }catch{
            print("Error Occured\(error.localizedDescription)")
        }
    }
    func getAudioURL() -> URL{
        let documentPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        return documentPath.appendingPathComponent("audio.m4a")
    }
    @objc
    func updateLipSync(){
        audioRecorder?.updateMeters()
        
        let averagePower = audioRecorder?.averagePower(forChannel: 0) ?? -160
        let normalizedPower = max(0, CGFloat(averagePower + 160 ) / 160)
        print(normalizedPower)
        
        print("average power: \(averagePower), Normalized Power: \(normalizedPower)")
        
        if normalizedPower > 0.80 {
            animateMuscle(muscleName: "n75", scene: scene)
            //            print("started")
        }else{
            print("nottalking")
            //            print("stoped")
        }
    }
}

