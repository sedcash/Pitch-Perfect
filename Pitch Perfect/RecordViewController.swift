//
//  RecordViewController.swift
//  Pitch Perfect
//
//  Created by Sedrick Cashaw Jr on 7/12/20.
//  Copyright © 2020 Sedrick Cashaw Jr. All rights reserved.
//

import UIKit
import AVFoundation

class RecordViewController: UIViewController, AVAudioRecorderDelegate {
    
    var recordButton: UIButton = {
        let button = UIButton()
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Record"), for: .normal)
        return button
    }()
    
    var stopRecordingButton: UIButton = {
        let button = UIButton()
        button.backgroundColor = UIColor.white
        button.setTitleColor(.black, for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        button.setImage(UIImage(named: "Stop"), for: .normal)
        button.isHidden = true
        return button
    }()
    
    var recordLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap to Record"
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    var audioRecorder: AVAudioRecorder!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        setupViews()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = true
    }
    
    func setupViews() {
        recordButton.addTarget(self, action: #selector(recordButtonPressed(_:)), for: .touchUpInside)
        stopRecordingButton.addTarget(self, action: #selector(stopRecordingButtonPressed(_:)), for: .touchUpInside)
        
        view.backgroundColor = .white
        view.addSubview(recordButton)
        view.addSubview(recordLabel)
        view.addSubview(stopRecordingButton)
        
        NSLayoutConstraint.activate([
            recordButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordButton.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            recordLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            recordLabel.topAnchor.constraint(equalTo: recordButton.bottomAnchor, constant: 10),
            
            stopRecordingButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            stopRecordingButton.topAnchor.constraint(equalTo: recordLabel.bottomAnchor, constant: 10),
            stopRecordingButton.heightAnchor.constraint(equalToConstant: 60),
            stopRecordingButton.widthAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    @objc func recordButtonPressed(_ sender: UIButton) {
        sender.isEnabled = false
        recordLabel.text = "Recording"
        stopRecordingButton.isHidden = false
        
        let dirPath = NSSearchPathForDirectoriesInDomains(.documentDirectory,.userDomainMask, true)[0] as String
        let recordingName = "recordedVoice.wav"
        let pathArray = [dirPath, recordingName]
        let filePath = URL(string: pathArray.joined(separator: "/"))

        let session = AVAudioSession.sharedInstance()
        try! session.setCategory(AVAudioSession.Category.playAndRecord, mode: AVAudioSession.Mode.default, options: AVAudioSession.CategoryOptions.defaultToSpeaker)

        try! audioRecorder = AVAudioRecorder(url: filePath!, settings: [:])
        audioRecorder.delegate = self
        audioRecorder.isMeteringEnabled = true
        audioRecorder.prepareToRecord()
        audioRecorder.record()
    }
    
    @objc func stopRecordingButtonPressed(_ sender: UIButton) {
        recordLabel.text = "Tap to Record"
        recordButton.isEnabled = true
        sender.isHidden = true
        audioRecorder.stop()
        let audioSession = AVAudioSession.sharedInstance()
        try! audioSession.setActive(false)
    }
    
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            navigateToChangerViewController()
        } else {
            print("Recording Failed")
        }
    }
    
    func navigateToChangerViewController() {
        let voiceChangerVC = VoiceChangerViewControlleer()
        voiceChangerVC.recordedAudioURL = audioRecorder.url
        navigationController?.pushViewController(voiceChangerVC, animated: true)
    }
}
