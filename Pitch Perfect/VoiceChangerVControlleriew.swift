//
//  VoiceChangerViewControlleer.swift
//  Pitch Perfect
//
//  Created by Sedrick Cashaw Jr on 7/13/20.
//  Copyright © 2020 Sedrick Cashaw Jr. All rights reserved.
//

import UIKit
import AVFoundation

class VoiceChangerViewControlleer: UIViewController {
    
    var recordedAudioURL:URL!
    var audioFile:AVAudioFile!
    var audioEngine:AVAudioEngine!
    var audioPlayerNode: AVAudioPlayerNode!
    var stopTimer: Timer!

    enum ButtonType: Int {
        case slow = 0, fast, chipmunk, vader, echo, reverb
    }
    
    var stopButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.white
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Stop"), for: .normal)
        button.isHidden = true
        return button
    }()
    
    var voiceButtons: [UIButton] = {
        let buttons: [UIButton] = ["Slow", "Fast", "LowPitch", "HighPitch", "Echo", "Reverb"].enumerated().map { (index, element) in
            let button = UIButton()
            button.tag = index
            button.setImage(UIImage(named: element), for: .normal)
            button.addTarget(self, action: #selector(playAudio(_:)), for: .touchUpInside)
            button.contentMode = .center
            button.imageView?.contentMode = .scaleAspectFit
            return button
        }
        return buttons
    }()
    
    override func viewDidLoad() {
        setupViews()
        setupAudio()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        navigationController?.navigationBar.isHidden = false
    }
    
    func setupViews() {
        stopButton.addTarget(self, action: #selector(stopAudio), for: .touchUpInside)
        
        let voiceChangerContainers = getVoiceChangerContainers()
        let maincontainer = UIStackView(arrangedSubviews: voiceChangerContainers)
        maincontainer.alignment = .fill
        maincontainer.distribution = .fillEqually
        maincontainer.axis = .vertical
        maincontainer.translatesAutoresizingMaskIntoConstraints = false
        
        view.backgroundColor = .white
        let margins: CGFloat = 20
        view.layoutMargins = UIEdgeInsets(top: 10, left: margins, bottom: -margins, right: -margins)
        view.addSubview(maincontainer)
        view.addSubview(stopButton)
        
        let layoutMargins = view.layoutMarginsGuide
        
        NSLayoutConstraint.activate([
            maincontainer.topAnchor.constraint(equalTo: layoutMargins.topAnchor),
            maincontainer.leadingAnchor.constraint(equalTo: layoutMargins.leadingAnchor),
            maincontainer.trailingAnchor.constraint(equalTo: layoutMargins.trailingAnchor),
            
            stopButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopButton.topAnchor.constraint(equalTo: maincontainer.bottomAnchor, constant: 10),
            stopButton.heightAnchor.constraint(equalToConstant: 80),
            stopButton.widthAnchor.constraint(equalToConstant: 80),
            stopButton.bottomAnchor.constraint(equalTo: layoutMargins.bottomAnchor)
        ])
    }
    
    func getVoiceChangerContainers() -> [UIStackView] {
        var result = [UIStackView]()
        
        var i = 0;
        while i < voiceButtons.count {
            let a = voiceButtons[i];
            var b: UIButton?;
            if i + 1 < voiceButtons.count {
                b = voiceButtons[i+1]
            }
            
            let stackView = UIStackView(arrangedSubviews: [a,b!])
            stackView.alignment = .fill
            stackView.distribution = .fillEqually
            result.append(stackView)
            i += 2;
        }
        
        return result
    }
    
    @objc func playAudio(_ sender: UIButton) {
        let button = ButtonType(rawValue: sender.tag)!
        switch button {
        case .slow:
            playSound(rate: 0.5)
        case .fast:
            playSound(rate: 1.5)
        case .chipmunk:
            playSound(pitch: 1000)
        case .vader:
            playSound(pitch: -1000)
        case .echo:
            playSound(echo: true)
        case .reverb:
            playSound(reverb: true)
        }
        configureUI(.playing)
    }
}

// MARK: - PlaySoundsViewController: AVAudioPlayerDelegate

extension VoiceChangerViewControlleer: AVAudioPlayerDelegate {
    
    // MARK: Alerts
    
    struct Alerts {
        static let DismissAlert = "Dismiss"
        static let RecordingDisabledTitle = "Recording Disabled"
        static let RecordingDisabledMessage = "You've disabled this app from recording your microphone. Check Settings."
        static let RecordingFailedTitle = "Recording Failed"
        static let RecordingFailedMessage = "Something went wrong with your recording."
        static let AudioRecorderError = "Audio Recorder Error"
        static let AudioSessionError = "Audio Session Error"
        static let AudioRecordingError = "Audio Recording Error"
        static let AudioFileError = "Audio File Error"
        static let AudioEngineError = "Audio Engine Error"
    }
    
    // MARK: PlayingState (raw values correspond to sender tags)
    
    enum PlayingState { case playing, notPlaying }
    
    // MARK: Audio Functions
    
    func setupAudio() {
        // initialize (recording) audio file
        do {
            audioFile = try AVAudioFile(forReading: recordedAudioURL as URL)
        } catch {
            showAlert(Alerts.AudioFileError, message: String(describing: error))
        }
    }
    
    func playSound(rate: Float? = nil, pitch: Float? = nil, echo: Bool = false, reverb: Bool = false) {
        
        // initialize audio engine components
        audioEngine = AVAudioEngine()
        
        // node for playing audio
        audioPlayerNode = AVAudioPlayerNode()
        audioEngine.attach(audioPlayerNode)
        
        // node for adjusting rate/pitch
        let changeRatePitchNode = AVAudioUnitTimePitch()
        if let pitch = pitch {
            changeRatePitchNode.pitch = pitch
        }
        if let rate = rate {
            changeRatePitchNode.rate = rate
        }
        audioEngine.attach(changeRatePitchNode)
        
        // node for echo
        let echoNode = AVAudioUnitDistortion()
        echoNode.loadFactoryPreset(.multiEcho1)
        audioEngine.attach(echoNode)
        
        // node for reverb
        let reverbNode = AVAudioUnitReverb()
        reverbNode.loadFactoryPreset(.cathedral)
        reverbNode.wetDryMix = 50
        audioEngine.attach(reverbNode)
        
        // connect nodes
        if echo == true && reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, reverbNode, audioEngine.outputNode)
        } else if echo == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, echoNode, audioEngine.outputNode)
        } else if reverb == true {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, reverbNode, audioEngine.outputNode)
        } else {
            connectAudioNodes(audioPlayerNode, changeRatePitchNode, audioEngine.outputNode)
        }
        
        // schedule to play and start the engine!
        audioPlayerNode.stop()
        audioPlayerNode.scheduleFile(audioFile, at: nil) {
            
            var delayInSeconds: Double = 0
            
            if let lastRenderTime = self.audioPlayerNode.lastRenderTime, let playerTime = self.audioPlayerNode.playerTime(forNodeTime: lastRenderTime) {
                
                if let rate = rate {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate) / Double(rate)
                } else {
                    delayInSeconds = Double(self.audioFile.length - playerTime.sampleTime) / Double(self.audioFile.processingFormat.sampleRate)
                }
            }
            
            // schedule a stop timer for when audio finishes playing
            self.stopTimer = Timer(timeInterval: delayInSeconds, target: self, selector: #selector(VoiceChangerViewControlleer.stopAudio), userInfo: nil, repeats: false)
            RunLoop.main.add(self.stopTimer!, forMode: RunLoop.Mode.default)
        }
        
        do {
            try audioEngine.start()
        } catch {
            showAlert(Alerts.AudioEngineError, message: String(describing: error))
            return
        }
        
        // play the recording!
        audioPlayerNode.play()
    }
    
    @objc func stopAudio(_ sender: UIButton) {
        if let audioPlayerNode = audioPlayerNode {
            audioPlayerNode.stop()
        }
        
        if let stopTimer = stopTimer {
            stopTimer.invalidate()
        }
        
        configureUI(.notPlaying)

        if let audioEngine = audioEngine {
            audioEngine.stop()
            audioEngine.reset()
        }
    }
    
    // MARK: Connect List of Audio Nodes
    
    func connectAudioNodes(_ nodes: AVAudioNode...) {
        for x in 0..<nodes.count-1 {
            audioEngine.connect(nodes[x], to: nodes[x+1], format: audioFile.processingFormat)
        }
    }
    
    // MARK: UI Functions

    func configureUI(_ playState: PlayingState) {
        switch(playState) {
        case .playing:
            setPlayButtonsEnabled(false)
            stopButton.isHidden = false
        case .notPlaying:
            setPlayButtonsEnabled(true)
            stopButton.isHidden = true
        }
    }
    
    func setPlayButtonsEnabled(_ enabled: Bool) {
        voiceButtons.forEach { button in
            button.isEnabled = enabled
        }
    }

    func showAlert(_ title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Alerts.DismissAlert, style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}
