import Foundation
import UIKit

class AppInfoVC: UIViewController {
    
    private let about: UILabel = {
        let label = UILabel()
        label.text = "About App"
        label.textColor = .label
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 30, weight: .bold)
        return label
    }()
    
    private let version: UILabel = {
        let label = UILabel()
        label.text = "version v1.0.0"
        label.textColor = .label
        label.textAlignment = .left
        label.font = .systemFont(ofSize: 20, weight: .medium)
        return label
    }()
    
    private let content: UITextView = {
        let textView = UITextView()
        textView.text = "Chaaat offers the fastest way to chat, providing not only text messages, image messages, video messages, audio messages and location messages. What's more, the chat content never disappears because we backed up all your messages in the cloud."
        textView.textColor = .label
        textView.textAlignment = .left
        textView.font = .systemFont(ofSize: 15, weight: .light)
        return textView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        view.addSubview(about)
        view.addSubview(version)
        view.addSubview(content)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let distance = view.width/10
        about.frame = CGRect(x: 0,
                             y: 10,
                             width: view.width,
                             height: 30)
        version.frame = CGRect(x: distance,
                               y: about.bottom+20,
                               width: view.width/2,
                               height: 20)
        content.frame = CGRect(x: distance,
                               y: version.bottom+5,
                               width: view.width-(distance*2),
                               height: 150)
        
    }
}
