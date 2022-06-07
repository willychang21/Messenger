import Foundation
import UIKit
import AVFoundation
import SwiftUI

class AudioVC: UIViewController {
    // define lazy views
    lazy var titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Record Audio"
        label.font = .boldSystemFont(ofSize: 20)
        return label
    }()
    
    lazy var notesLabel: UILabel = {
        let label = UILabel()
        label.text = "Press the button to record audio."
        label.font = .systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.numberOfLines = 0
        return label
    }()
    
    lazy var timeLabel: UILabel = {
        let label = UILabel()
        label.text = "00:00"
        label.font = .systemFont(ofSize: 30)
        label.textColor = .systemGray
        return label
    }()
    
    lazy var stopButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Stop"), for: .normal)
        button.isEnabled = true
        return button
    }()
    
    lazy var playButton: UIButton = {
        let button = UIButton()
        button.setImage(UIImage(named: "Play"), for: .normal)
        button.isEnabled = true
        return button
    }()
    
    lazy var recordButton: UIButton = {
        let button = UIButton()
        let image = UIImage(named: "Record")?.resizedImage(Size: CGSize(width: 50, height: 50))
        button.setImage(image, for: .normal)
        button.isEnabled = true
       return button
    }()
    
    lazy var sendAudioButton: UIButton = {
        let button = UIButton()
        button.setTitle("Send", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .black
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20,
                                              weight: .bold)
        button.isEnabled = true
        return button
    }()
    
    lazy var buttonStackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [stopButton, playButton, recordButton])
        stackView.axis = .horizontal
        stackView.alignment = .center
        stackView.distribution = .equalCentering
        stackView.spacing = 15
        return stackView
    }()
    
    lazy var contentStackView: UIStackView = {
        let spacer = UIView()
        let stackView = UIStackView(arrangedSubviews: [titleLabel, notesLabel, timeLabel, buttonStackView, sendAudioButton, spacer])
        stackView.alignment = .center
        stackView.axis = .vertical
        stackView.spacing = 12.0
        return stackView
    }()
    
    lazy var containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = 16
        view.clipsToBounds = true
        return view
    }()
    
    let maxDimmedAlpha: CGFloat = 0.6
    lazy var dimmedView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.alpha = maxDimmedAlpha
        return view
    }()
    
    // Constants
    let defaultHeight: CGFloat = 250
    let dismissibleHeight: CGFloat = 200
    let maximumContainerHeight: CGFloat = UIScreen.main.bounds.height - 64
    // keep current new height, initial is default height
    var currentContainerHeight: CGFloat = 250
    
    // Dynamic container constraint
    var containerViewHeightConstraint: NSLayoutConstraint?
    var containerViewBottomConstraint: NSLayoutConstraint?
    
    // Use for Audio
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    
    private var timer: Timer?
    private var elapsedTimeInSecond: Int = 0
    
    public var completion: ((URL,Float) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupView()
        setupConstraints()
        // tap gesture on dimmed view to dismiss
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(self.handleCloseAction))
        dimmedView.addGestureRecognizer(tapGesture)
        
        setupPanGesture()
        
        stopButton.addTarget(self, action: #selector(stop), for: .touchUpInside)
        playButton.addTarget(self, action: #selector(play), for: .touchUpInside)
        recordButton.addTarget(self, action: #selector(record), for: .touchUpInside)
        sendAudioButton.addTarget(self, action: #selector(sendAudio), for: .touchUpInside)
        
        
        // setup recorder
        configure()
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @objc func handleCloseAction() {
        animateDismissView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateShowDimmedView()
        animatePresentContainer()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        NotificationCenter.default.post(name: .audioVCDisappear,
                                        object: nil)
    }
    
    func setupView() {
        view.backgroundColor = .clear
    }
    
    func setupConstraints() {
        // Add subviews
        view.addSubview(dimmedView)
        view.addSubview(containerView)
        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        containerView.addSubview(contentStackView)
        contentStackView.translatesAutoresizingMaskIntoConstraints = false
        
        // Set static constraints
        NSLayoutConstraint.activate([
            // set dimmedView edges to superview
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // set container static constraint (trailing & leading)
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            // content stackView
            contentStackView.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 32),
            contentStackView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -20),
            contentStackView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 20),
            contentStackView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -20),
        ])
        
        // Set dynamic constraints
        // First, set container to default height
        // after panning, the height can expand
        containerViewHeightConstraint = containerView.heightAnchor.constraint(equalToConstant: defaultHeight)
        
        // By setting the height to default height, the container will be hide below the bottom anchor view
        // Later, will bring it up by set it to 0
        // set the constant to default height to bring it down again
        containerViewBottomConstraint = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: defaultHeight)
        // Activate constraints
        containerViewHeightConstraint?.isActive = true
        containerViewBottomConstraint?.isActive = true
    }
    
    func setupPanGesture() {
        // add pan gesture recognizer to the view controller's view (the whole screen)
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(self.handlePanGesture(gesture:)))
        // change to false to immediately listen on gesture movement
        panGesture.delaysTouchesBegan = false
        panGesture.delaysTouchesEnded = false
        view.addGestureRecognizer(panGesture)
    }
    
    // MARK: Pan gesture handler
    @objc func handlePanGesture(gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        // Drag to top will be minus value and vice versa
        print("Pan gesture y offset: \(translation.y)")
        
        // Get drag direction
        let isDraggingDown = translation.y > 0
        print("Dragging direction: \(isDraggingDown ? "going down" : "going up")")
        
        // New height is based on value of dragging plus current container height
        let newHeight = currentContainerHeight - translation.y
        
        // Handle based on gesture state
        switch gesture.state {
        case .changed:
            // This state will occur when user is dragging
            if newHeight < maximumContainerHeight {
                // Keep updating the height constraint
                containerViewHeightConstraint?.constant = newHeight
                // refresh layout
                view.layoutIfNeeded()
            }
        case .ended:
            // This happens when user stop drag,
            // so we will get the last height of container
            
            // Condition 1: If new height is below min, dismiss controller
            if newHeight < dismissibleHeight {
                self.animateDismissView()
            }
            else if newHeight < defaultHeight {
                // Condition 2: If new height is below default, animate back to default
                animateContainerHeight(defaultHeight)
            }
            else if newHeight < maximumContainerHeight && isDraggingDown {
                // Condition 3: If new height is below max and going down, set to default height
                animateContainerHeight(defaultHeight)
            }
            else if newHeight > defaultHeight && !isDraggingDown {
                // Condition 4: If new height is below max and going up, set to max height at top
                animateContainerHeight(maximumContainerHeight)
            }
        default:
            break
        }
    }
    
    func animateContainerHeight(_ height: CGFloat) {
        UIView.animate(withDuration: 0.4) {
            // Update container height
            self.containerViewHeightConstraint?.constant = height
            // Call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
        // Save current height
        currentContainerHeight = height
    }
    
    // MARK: Present and dismiss animation
    func animatePresentContainer() {
        // update bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = 0
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
    }
    
    func animateShowDimmedView() {
        dimmedView.alpha = 0
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = self.maxDimmedAlpha
        }
    }
    
    func animateDismissView() {
        // hide blur view
        dimmedView.alpha = maxDimmedAlpha
        UIView.animate(withDuration: 0.4) {
            self.dimmedView.alpha = 0
        } completion: { _ in
            // once done, dismiss without animation
            self.dismiss(animated: false)
        }
        // hide main view by updating bottom constraint in animation block
        UIView.animate(withDuration: 0.3) {
            self.containerViewBottomConstraint?.constant = self.defaultHeight
            // call this to trigger refresh constraint
            self.view.layoutIfNeeded()
        }
        
    }
    
    // MARK: Audio Function
    func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true, block: { (timer) in
            self.elapsedTimeInSecond += 1
            self.updateTimeLabel()
        })
        
    }

    func pauseTimer() {
        timer?.invalidate()
    }

    func resetTimer() {
        timer?.invalidate()
        elapsedTimeInSecond = 0
        updateTimeLabel()
    }

    func updateTimeLabel() {
        
        let seconds = elapsedTimeInSecond % 60
        let minutes = (elapsedTimeInSecond / 60) % 60
        
        timeLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    // MARK: - Audio Action Method
    
    @objc func play(sender: UIButton) {
        if !audioRecorder.isRecording {
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else {
                print("Failed to initialize AVAudioPlayer")
                return
            }
            audioPlayer = player
            audioPlayer?.delegate = self
            audioPlayer?.play()
            startTimer()
        }
    }
    
    @objc func stop(sender: UIButton) {
        recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
        recordButton.isEnabled = true
        stopButton.isEnabled = false
        playButton.isEnabled = true
        
        // Stop the audio recorder
        audioRecorder?.stop()
        resetTimer()
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setActive(false)
        } catch {
            print(error)
        }
    }
    
    @objc func record(sender: UIButton) {
        // Stop the audio player before recording
        if let player = audioPlayer, player.isPlaying {
            player.stop()
        }
        
        if !audioRecorder.isRecording {
            let audioSession = AVAudioSession.sharedInstance()
            
            do {
                try audioSession.setActive(true)
                
                // Start recording
                audioRecorder.record()
                startTimer()
                
                // Change to the Pause image
                recordButton.setImage(UIImage(named: "Pause"), for: UIControl.State.normal)
            } catch {
                print(error)
            }
            
        } else {
            // Pause recording
            audioRecorder.pause()
            pauseTimer()
            
            // Change to the Record image
            recordButton.setImage(UIImage(named: "Record"), for: UIControl.State.normal)
        }
        
        stopButton.isEnabled = true
        playButton.isEnabled = false
    }
    
    @objc func sendAudio(sender: UIButton) {
        print("Send the audio.")
        if !audioRecorder.isRecording {
            let url = audioRecorder.url
            guard let player = try? AVAudioPlayer(contentsOf: audioRecorder.url) else {
                print("Failed to initialize AVAudioPlayer")
                return
            }
            let duration = Float(player.duration)
            self.dismiss(animated: true)
            completion?(url, duration)
        }
    }
    
    private func configure() {
        // Disable Stop/Play button when application launches
        stopButton.isEnabled = false
        playButton.isEnabled = false
        
        // Get the document directory. If fails, just skip the rest of the code
        guard let directoryURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: FileManager.SearchPathDomainMask.userDomainMask).first else {
            
            let alertMessage = UIAlertController(title: "Error", message: "Failed to get the document directory for recording the audio. Please try again later.", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
            
            return
        }
        
        // Set the default audio file
        let audioFileURL = directoryURL.appendingPathComponent("MyAudioMemo.m4a")
        
        // Setup audio session
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [ .defaultToSpeaker ])
            
            // Define the recorder setting
            let recorderSetting: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 2,
                AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
            ]
            
            // Initiate and prepare the recorder
            audioRecorder = try AVAudioRecorder(url: audioFileURL, settings: recorderSetting)
            audioRecorder.delegate = self
            audioRecorder.isMeteringEnabled = true
            audioRecorder.prepareToRecord()
            
        } catch {
            print(error)
        }
    }
}

extension AudioVC: AVAudioRecorderDelegate {
    func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if flag {
            let alertMessage = UIAlertController(title: "Finish Recording", message: "Successfully recorded the audio!", preferredStyle: .alert)
            alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            present(alertMessage, animated: true, completion: nil)
        }
    }
}

extension AudioVC: AVAudioPlayerDelegate {
    func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        playButton.isSelected = false
        
        let alertMessage = UIAlertController(title: "Finish Playing", message: "Finish playing the recording!", preferredStyle: .alert)
        alertMessage.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        present(alertMessage, animated: true, completion: nil)
        
        resetTimer()
    }
}
