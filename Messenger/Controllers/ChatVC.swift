import UIKit
import MessageKit
import InputBarAccessoryView
import SDWebImage
import AVFoundation
import AVKit
import CoreLocation

final class ChatVC: MessagesViewController {
    
    private var senderPhotoURL: URL?
    private var otherUserPhotoURL: URL?
    
    public static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .long
        formatter.locale = .current
        return formatter
    }()
    
    public let otherUserEmail: String
    private var conversationId: String?
    public var isNewConversation = false
    
    private var messages = [Message]()
    
    var audioRecorder: AVAudioRecorder!
    var audioPlayer: AVAudioPlayer?
    private var audioVCObserver: NSObjectProtocol?
    lazy var audioController = BasicAudioController(messageCollectionView: messagesCollectionView)
    
    private var selfSender: Sender?  {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        return Sender(photoURL: "",
                      senderId: safeEmail,
                      displayName: "Me")
    }
    
    init(with email: String, id: String?) {
        // initializer
        // we could get rid of some of self.
        // because of name collide, but it's just better pratice to leave them,
        // just signal it's a constructor.
        self.otherUserEmail = email
        self.conversationId = id
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //view.backgroundColor = .blue
        let navBarHeight = navigationController?.navigationBar.frame.height ?? 0.0
        messagesCollectionView.frame.origin.y = navBarHeight + 50.0
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        messagesCollectionView.messageCellDelegate = self
        messageInputBar.delegate = self
        
        setupInputButton()
        
        audioVCObserver = NotificationCenter.default.addObserver(forName: .audioVCDisappear,
                                                                 object: nil,
                                                                 queue: .main, using: { [weak self] _ in
            self?.tabBarController?.tabBar.isHidden = false
        })
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if let conversationId = conversationId {
            listenForMessages(id: conversationId, shouldScrollToBottom: true)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioController.stopAnyOngoingPlaying()
    }
    
    // add attach file botton
    private func setupInputButton() {
        let button = InputBarButtonItem()
        button.setSize(CGSize(width: 35, height: 35), animated: false)
        button.setImage(UIImage(systemName: "paperclip"), for: .normal)
        button.onTouchUpInside { [weak self] _ in
            self?.presentInputActionSheet()
        }
        messageInputBar.setLeftStackViewWidthConstant(to: 36, animated: false)
        messageInputBar.setStackViewItems([button], forStack: .left, animated: false)
    }
    
    private func presentInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Media",
                                            message: "What would you like to attach?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentPhotoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Video",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentVideoInputActionSheet()
        }))
        actionSheet.addAction(UIAlertAction(title: "Audio",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentAudioInputView()
        }))
        actionSheet.addAction(UIAlertAction(title: "Location",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentLocationPicker()
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentPhotoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Photo",
                                            message: "Where would you like to attach a photo from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera",
                                            style: .default,
                                            handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Photo Library",
                                            style: .default,
                                            handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    private func presentVideoInputActionSheet() {
        let actionSheet = UIAlertController(title: "Attach Video",
                                            message: "Where would you like to attach a video from?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Camera",
                                            style: .default,
                                            handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .camera
            picker.delegate = self
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            picker.allowsEditing = true
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Library",
                                            style: .default,
                                            handler: { [weak self] _ in
            let picker = UIImagePickerController()
            picker.sourceType = .photoLibrary
            picker.delegate = self
            picker.allowsEditing = true
            picker.mediaTypes = ["public.movie"]
            picker.videoQuality = .typeMedium
            self?.present(picker, animated: true)
        }))
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .default, handler: nil))
        
        present(actionSheet, animated: true)
    }
    
    // Update all message from firebase
    private func listenForMessages(id: String, shouldScrollToBottom: Bool) {
        
        DatabaseManager.shared.getAllMessagesForConversation(with: id) { [weak self] result in
            switch result {
            case .success(let messages):
                print("success in getting message: \(messages)")
                guard !messages.isEmpty else {
                    print("message is empty")
                    return
                }
                self?.messages = messages
                
                
                DispatchQueue.main.async {
                    // user scroll to the top reading old message and the new messages come in, don't let the view auto scroll down, because is a bad experience
                    
                    self?.messagesCollectionView.reloadDataAndKeepOffset()
                    
                    if shouldScrollToBottom {
                        self?.messagesCollectionView.scrollToLastItem(at: .bottom, animated: false)
                    }
                }
                
            case .failure(let error):
                print("failed to get messages: \(error)")
            }
        }
    }
    
    // MARK: Location Input
    private func presentLocationPicker() {
        let vc = LocationPickerVC(coordinates: nil)
        vc.title = "Pick Location"
        vc.navigationItem.largeTitleDisplayMode = .never
        vc.completion = { [weak self] selectedCoorindates in
            
            guard let strongSelf = self else {
                return
            }
            
            let longitude: Double = selectedCoorindates.longitude
            let latitude: Double = selectedCoorindates.latitude
            print("long=\(longitude), lat=\(latitude)")
            
            let location = Location(location: CLLocation(latitude: latitude,
                                                         longitude: longitude),
                                    size: .zero)
            
            guard let messageId = strongSelf.createMessageId(),
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            let message = Message(sender: selfSender,
                                  messageId: messageId,
                                  sentDate: Date(),
                                  kind: .location(location))
            // Send Message
            if strongSelf.isNewConversation {
                // create conversation in database
                print("is a new conversation")
                DatabaseManager.shared.createNewConversation(with: strongSelf.otherUserEmail,
                                                             name: name,
                                                             firstMessage: message) { [weak self] success in
                    if success {
                        print("message sent")
                        self?.isNewConversation = false
                        let newConversationId = "conversation_\(message.messageId)"
                        self?.conversationId = newConversationId
                        self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                        self?.messageInputBar.inputTextView.text = nil
                    }
                    else {
                        print("failed to send")
                    }
                }
            }
            else {
                print("conversation already existed")
                guard let conversationId = self?.conversationId,
                      let name = self?.title else {
                    return
                }
                // append to existing conversation data
                DatabaseManager.shared.sendMessage(to: conversationId,
                                                   otherUserEmail: strongSelf.otherUserEmail,
                                                   name: name,
                                                   newMessage: message) { [weak self] success in
                    if success {
                        self?.messageInputBar.inputTextView.text = nil
                        print("message sent")
                    }
                    else {
                        print("failed to send")
                    }
                }
            }
        }
        
        
        navigationController?.pushViewController(vc, animated: true)
        
        
    }
    
    // MARK: Audio Input
    private func presentAudioInputView() {
        let vc = AudioVC()
        vc.modalPresentationStyle = .overCurrentContext
        vc.completion = { [weak self] url, audioDuration in
            guard let strongSelf = self else {
                return
            }
            guard let messageId = strongSelf.createMessageId(),
                  let name = strongSelf.title,
                  let selfSender = strongSelf.selfSender else {
                return
            }
            
            // Send Message
            if strongSelf.isNewConversation {
                // create conversation in database
                //let audio = try? Data(contentsOf: url)
                let fileName = "audio_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".m4a"
                // Upload Audio
                StorageManager.shared.uploadMessageAudio(with: url, fileName: fileName) { [weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        // Ready to send message
                        print("Upload Message Audio: \(urlString)")
                        guard let audioUrl = URL(string: urlString) else {
                            return
                        }
                        let audio = Audio(url: audioUrl,
                                          duration: audioDuration,
                                          size: CGSize(width: 200,
                                                       height: 15))
                        let message = Message(sender: selfSender,
                                              messageId: messageId,
                                              sentDate: Date(),
                                              kind: .audio(audio))
                        DatabaseManager.shared.createNewConversation(with: strongSelf.otherUserEmail,
                                                                     name: name,
                                                                     firstMessage: message) { [weak self] success in
                            if success {
                                print("message sent")
                                self?.isNewConversation = false
                                let newConversationId = "conversation_\(message.messageId)"
                                self?.conversationId = newConversationId
                                self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                                self?.messageInputBar.inputTextView.text = nil
                            }
                            else {
                                print("failed to send")
                            }
                        }
                    case .failure(let error):
                        print("message audio upload error: \(error)")
                    }
                }
                
            }
            else {
                // conversation already exists
                guard let conversationId = strongSelf.conversationId else {
                    return
                }
                let fileName = "audio_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".m4a"
                // Upload Audio
                StorageManager.shared.uploadMessageAudio(with: url, fileName: fileName) { [weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        // Ready to send message
                        print("Upload Message Audio: \(urlString)")
                        guard let audioUrl = URL(string: urlString) else {
                            return
                        }
                        let audio = Audio(url: audioUrl,
                                          duration: audioDuration,
                                          size: CGSize(width: 200,
                                                       height: 15))
                        let message = Message(sender: selfSender,
                                              messageId: messageId,
                                              sentDate: Date(),
                                              kind: .audio(audio))
                        DatabaseManager.shared.sendMessage(to: conversationId,
                                                           otherUserEmail: strongSelf.otherUserEmail,
                                                           name: name,
                                                           newMessage: message) { success in
                            if success {
                                print("sent audio message")
                            }
                            else {
                                print("failed to send audio message")
                            }
                        }
                    case .failure(let error):
                        print("message audio upload error: \(error)")
                    }
                }
            }
            
            
        }
        
        // keep false
        // modal animation will be handled in VC itself
        self.tabBarController?.tabBar.isHidden = true
        self.present(vc, animated: false)
    }
    
    // MARK: - Helpers
    
    func isTimeLabelVisible(at indexPath: IndexPath) -> Bool {
        return indexPath.section % 3 == 0 && !isPreviousMessageSameSender(at: indexPath)
    }
    
    func isPreviousMessageSameSender(at indexPath: IndexPath) -> Bool {
        guard indexPath.section - 1 >= 0 else { return false }
        return messages[indexPath.section].sender.senderId == messages[indexPath.section - 1].sender.senderId
    }

}
// MARK: Image & Video Input
extension ChatVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        
        guard let messageId = createMessageId(),
              let name = self.title,
              let selfSender = selfSender else {
            return
        }
        
        // Send Message
        if isNewConversation {
            // create conversation in database
            print("is a new conversation")
            if let image = info[.editedImage] as? UIImage,
               let imageData = image.pngData() {
                let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
                
                // Upload Image
                StorageManager.shared.uploadMessagePhoto(with: imageData,
                                                         fileName: fileName) { [weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        // Ready to send message
                        print("Upload Message Photo: \(urlString)")
                        
                        guard let url = URL(string: urlString),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                        
                        let media = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: .zero)
                        let message = Message(sender: selfSender,
                                              messageId: messageId,
                                              sentDate: Date(),
                                              kind: .photo(media))
                        DatabaseManager.shared.createNewConversation(with: strongSelf.otherUserEmail,
                                                                     name: name,
                                                                     firstMessage: message) { [weak self] success in
                            if success {
                                print("message sent")
                                self?.isNewConversation = false
                                let newConversationId = "conversation_\(message.messageId)"
                                self?.conversationId = newConversationId
                                self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                                self?.messageInputBar.inputTextView.text = nil
                            }
                            else {
                                print("failed to send")
                            }
                        }
                        
                    case .failure(let error):
                        print("message photo upload error: \(error)")
                    }
                }
            }
            else if let videoUrl = info[.mediaURL] as? URL {
                
                let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
                
                // Upload Video
                StorageManager.shared.uploadMessageVideo(with: videoUrl,
                                                         fileName: fileName) { [weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        // Ready to send message
                        print("Upload Message Video: \(urlString)")
                        
                        guard let url = URL(string: urlString),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                        
                        let media = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: .zero)
                        let message = Message(sender: selfSender,
                                              messageId: messageId,
                                              sentDate: Date(),
                                              kind: .video(media))
                        DatabaseManager.shared.createNewConversation(with: strongSelf.otherUserEmail,
                                                                     name: name,
                                                                     firstMessage: message) { [weak self] success in
                            if success {
                                print("message sent")
                                self?.isNewConversation = false
                                let newConversationId = "conversation_\(message.messageId)"
                                self?.conversationId = newConversationId
                                self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                                self?.messageInputBar.inputTextView.text = nil
                            }
                            else {
                                print("failed to send")
                            }
                        }

                    case .failure(let error):
                        print("message photo upload error: \(error)")
                    }
                }
                
            }
           
        }
        else {
            print("conversation already existed")
            guard let conversationId = conversationId else {
                return
            }
            // append to existing conversation data
            if let image = info[.editedImage] as? UIImage,
               let imageData = image.pngData() {
                let fileName = "photo_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".png"
                
                // Upload Image
                StorageManager.shared.uploadMessagePhoto(with: imageData,
                                                         fileName: fileName) { [weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        // Ready to send message
                        print("Upload Message Photo: \(urlString)")
                        
                        guard let url = URL(string: urlString),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                        
                        let media = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: .zero)
                        let message = Message(sender: selfSender,
                                              messageId: messageId,
                                              sentDate: Date(),
                                              kind: .photo(media))
                        
                        DatabaseManager.shared.sendMessage(to: conversationId,
                                                           otherUserEmail: strongSelf.otherUserEmail,
                                                           name: name,
                                                           newMessage: message) { success in
                            if success {
                                print("sent photo message")
                            }
                            else {
                                print("failed to send photo message")
                            }
                        }
                    case .failure(let error):
                        print("message photo upload error: \(error)")
                    }
                }
            }
            else if let videoUrl = info[.mediaURL] as? URL {
                
                let fileName = "video_message_" + messageId.replacingOccurrences(of: " ", with: "-") + ".mov"
                
                // Upload Video
                StorageManager.shared.uploadMessageVideo(with: videoUrl,
                                                         fileName: fileName) { [weak self] result in
                    guard let strongSelf = self else {
                        return
                    }
                    switch result {
                    case .success(let urlString):
                        // Ready to send message
                        print("Upload Message Video: \(urlString)")
                        
                        guard let url = URL(string: urlString),
                              let placeholder = UIImage(systemName: "plus") else {
                            return
                        }
                        
                        let media = Media(url: url,
                                          image: nil,
                                          placeholderImage: placeholder,
                                          size: .zero)
                        let message = Message(sender: selfSender,
                                              messageId: messageId,
                                              sentDate: Date(),
                                              kind: .video(media))
                        
                        DatabaseManager.shared.sendMessage(to: conversationId,
                                                           otherUserEmail: strongSelf.otherUserEmail,
                                                           name: name,
                                                           newMessage: message) { success in
                            if success {
                                print("sent video message")
                            }
                            else {
                                print("failed to send photo message")
                            }
                        }
                    case .failure(let error):
                        print("message photo upload error: \(error)")
                    }
                }
                
            }

        }
    }
}
// MARK: Text Input
extension ChatVC: InputBarAccessoryViewDelegate {
    
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        guard !text.replacingOccurrences(of: " ", with: "").isEmpty,
              let selfSender = self.selfSender,
              let messageId = createMessageId() else {
            return
        }
        
        print("Sending: \(text)")
        
        let message = Message(sender: selfSender,
                              messageId: messageId,
                              sentDate: Date(),
                              kind: .text(text))
        
        // Send Message
        if isNewConversation {
            // create conversation in database
            print("is a new conversation")
            DatabaseManager.shared.createNewConversation(with: otherUserEmail,
                                                         name: self.title ?? "User",
                                                         firstMessage: message) { [weak self] success in
                if success {
                    print("message sent")
                    self?.isNewConversation = false
                    let newConversationId = "conversation_\(message.messageId)"
                    self?.conversationId = newConversationId
                    self?.listenForMessages(id: newConversationId, shouldScrollToBottom: true)
                    self?.messageInputBar.inputTextView.text = nil
                }
                else {
                    print("failed to send")
                }
            }
        }
        else {
            guard let conversationId = conversationId,
                  let name = self.title else {
                return
            }
            // append to existing conversation data
            DatabaseManager.shared.sendMessage(to: conversationId,
                                               otherUserEmail: otherUserEmail,
                                               name: name,
                                               newMessage: message) { [weak self] success in
                if success {
                    self?.messageInputBar.inputTextView.text = nil
                    print("message sent")
                }
                else {
                    print("failed to send")
                }
            }
        }
    }
    
    private func createMessageId() -> String? {
        // date, otherUserEmail, senderEmail, randomInt
        guard let currentUserEmail = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
        let safeCurrentEmail = DatabaseManager.safeEmail(emailAddress: currentUserEmail)
        
        let dateString = Self.dateFormatter.string(from: Date())
        let newIdentifier = "\(otherUserEmail)_\(safeCurrentEmail)_\(dateString)"
        
        print("created message id: \(newIdentifier)")
        
        return newIdentifier
    }
}

// MARK: Chat Cell Data
extension ChatVC: MessagesDataSource, MessagesLayoutDelegate, MessagesDisplayDelegate {
    
    func currentSender() -> SenderType {
        if let sender = selfSender {
            return sender
        }
        fatalError("Self Sender is nil, email should be cached")
    }
    
    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messages[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessagesCollectionView) -> Int {
        return messages.count
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            imageView.sd_setImage(with: imageUrl, completed: nil)
        default:
            break
        }
        
    }
    
    func configureAudioCell(_ cell: AudioMessageCell, message: MessageType) {
        guard let message = message as? Message else {
            return
        }
        
        switch message.kind {
        case .audio(let audio):
            let audioUrl = audio.url
            guard let player = try? AVAudioPlayer(contentsOf: audioUrl) else {
                print("Failed to initialize AVAudioPlayer")
                return
            }
            player.delegate = self
        default:
            break
        }
    }
    
    // Change Message Color
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        let sender = message.sender
        if sender.senderId == selfSender?.senderId {
            // our message that we've sent
            return .link
        }
        
        return .secondarySystemBackground
    }
    
    // AvatarView in ChatView
    func configureAvatarView(_ avatarView: AvatarView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
        let sender = message.sender
        
        if sender.senderId == selfSender?.senderId {
            // show our image
            if let currentUserImage = self.senderPhotoURL {
                avatarView.sd_setImage(with: currentUserImage, completed: nil)
            }
            else {
                // fetch url : images/safeemail_profile_picture.png
                guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
                    return
                }
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.senderPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                }
            }
        }
        else {
            // other user image
            if let otherUserImage = self.otherUserPhotoURL {
                avatarView.sd_setImage(with: otherUserImage, completed: nil)
            }
            else {
                // fetch url
                let email = self.otherUserEmail
                let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
                let path = "images/\(safeEmail)_profile_picture.png"
                
                StorageManager.shared.downloadURL(for: path) { [weak self] result in
                    switch result {
                    case .success(let url):
                        self?.otherUserPhotoURL = url
                        DispatchQueue.main.async {
                            avatarView.sd_setImage(with: url, completed: nil)
                        }
                    case .failure(let error):
                        print("\(error)")
                    }
                }
            }
        }
    }
    
    // Cell Top Label
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 10
    }
    func didTapCellTopLabel(in cell: MessageCollectionViewCell) {
        print("Top cell label tapped")
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        if isTimeLabelVisible(at: indexPath) {
            return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
        }
        return nil
    }
}
// MARK: Tap Chat Cell
extension ChatVC: MessageCellDelegate, AVAudioPlayerDelegate {
    
    func didTapMessage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .location(let locationData):
            let coordinates = locationData.location.coordinate
            let vc = LocationPickerVC(coordinates: coordinates)
            vc.title = "Location"
            navigationController?.pushViewController(vc, animated: true )
        default:
            break
        }
    }
    
    func didTapImage(in cell: MessageCollectionViewCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell) else {
            return
        }
        let message = messages[indexPath.section]
        
        switch message.kind {
        case .photo(let media):
            guard let imageUrl = media.url else {
                return
            }
            let vc = PhotoViewerVC(with: imageUrl)
            navigationController?.pushViewController(vc, animated: true)
        case .video(let media):
            guard let videoUrl = media.url else {
                return
            }
            
            let vc = AVPlayerViewController()
            vc.player = AVPlayer(url: videoUrl)
            present(vc, animated: true)
        default:
            break
        }
    }
    
    func didTapPlayButton(in cell: AudioMessageCell) {
        guard let indexPath = messagesCollectionView.indexPath(for: cell),
        let message = messagesCollectionView.messagesDataSource?.messageForItem(at: indexPath, in: messagesCollectionView) else {
            print("Failed to identify message when audio cell receive tap gesture")
            return
        }
        guard audioController.state != .stopped else {
            // There is no audio sound playing - prepare to start playing for given audio message
            audioController.playSound(for: message, in: cell)
            return
        }
        if audioController.playingMessage?.messageId == message.messageId {
            // tap occur in the current cell that is playing audio sound
            if audioController.state == .playing {
                audioController.pauseSound(for: message, in: cell)
            } else {
                audioController.resumeSound()
            }
        } else {
            // tap occur in a difference cell that the one is currently playing sound. First stop currently playing and start the sound for given message
            audioController.stopAnyOngoingPlaying()
            audioController.playSound(for: message, in: cell)
        }
    }

}


