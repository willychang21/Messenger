import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn
import SDWebImage
import MessageUI

final class ProfileVC: UITableViewController {
        
    
    @IBOutlet weak var imagebackground: UIView!
    @IBOutlet weak var imageView: UIImageView!
    
    private var loginObserver: NSObjectProtocol?
    
    var sectionTitles = ["User Name", "Support", " "]
    var sectionContent = [["User Name"], ["Info", "Privacy", "Contact Developer"], ["Log Out"]]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        setupImage()
        setupUserName()
        
        tableView.delegate = self
        tableView.dataSource = self
        
        // remove bottom blank cells in the table view
        tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification,
                                                               object: nil,
                                                               queue: .main) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            strongSelf.setupImage()
            strongSelf.updateUserInfo()
        }
        
    }
    
    func setupImage() {
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/"+fileName
        let size = view.width/2
        
        imagebackground.frame.size = CGSize(width: view.width, height: size)
        imageView.frame.size = CGSize(width: size, height: size)
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .white
        imageView.layer.borderColor = UIColor.white.cgColor
        imageView.layer.borderWidth = 3
        imageView.layer.masksToBounds = true
        imageView.layer.cornerRadius = imageView.width/2
        imageView.isUserInteractionEnabled = true
        
        StorageManager.shared.downloadURL(for: path) { result in
            // this imageView is already above, do not need to be strongSelf
            switch result {
            case .success(let url):
                self.imageView.sd_setImage(with: url, completed: nil) // store in cache, faster than URLSession
                // self?.downloadImage(imageView: imageView, url: url)
            case .failure(let error):
                print("Failed to get download url: \(error)")
                self.imageView.image = UIImage(systemName: "person.circle")
            }
        }
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
    }
    
    /// deleted because using SDWebImage stored the image in cache can reduce the data fetch
    //    func downloadImage(imageView: UIImageView, url: URL) {
    //        URLSession.shared.dataTask(with: url) { data, _, error in
    //            guard let data = data, error == nil else {
    //                return
    //            }
    //
    //            DispatchQueue.main.async {
    //                let image = UIImage(data: data)
    //                imageView.image = image
    //            }
    //        }.resume()
    //    }
    
    func setupUserName() {
        
        guard let name = UserDefaults.standard.value(forKey: "name") as? String else {
            print("Do not have user's information")
            return
        }
        sectionContent[0][0] = name
    }
    
    @objc func didTapChangeProfilePic() {
        presentPhotoActionSheet()
    }
    
    func logOut() {
        
        let actionSheet = UIAlertController(title: "Are you sure you want to log out?",
                                            message: "I will miss you.",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log out",
                                            style: .destructive,
                                            handler: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            // reset the cache in UserDefaults
            UserDefaults.standard.setValue(nil, forKey: "name")
            UserDefaults.standard.setValue(nil, forKey: "email")
            print("Logout name: \(UserDefaults.standard.value(forKey: "name") as? String ?? "No Value")")
            // Facebook - Log Out
            FacebookLogin.LoginManager().logOut()
            
            // Google - Log out
            GIDSignIn.sharedInstance.signOut()
            
            do {
                // Firebase - Log out
                try FirebaseAuth.Auth.auth().signOut()
                let vc = LoginVC()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: false)
            } catch let signOutError as NSError {
                print("Error signing out: %@", signOutError)
            }
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        
        present(actionSheet, animated: true)
        
    }
    
    func updateUserInfo() {
        guard let name = UserDefaults.standard.value(forKey: "name") as? String else {
            print("update user info failed")
            return
        }
        print("Successfully update user info.")
        sectionContent[0][0] = name
        //tableView.reloadData()
        tableView.reloadSections(IndexSet(integer: 0), with: .none)
    }
    
    func appInfo() {
        let vc = AppInfoVC()
        present(UINavigationController(rootViewController: vc), animated: true)
    }
    
    func urlLink() {
        let urlString = "https://www.privacypolicies.com/live/4028fe04-b4d1-4a3f-9fa0-305748b3df60"
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url)
        }
    }
}

extension ProfileVC {
    
    // MARK: Cell Configuration
    override func numberOfSections(in tableView: UITableView) -> Int {
        return sectionTitles.count
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        switch section {
        case 0:
            return sectionContent[0].count      // section 0 is the 1st/Top section 'Setup'
        case 1:
            return sectionContent[1].count      // section 1 is the 2nd section 'Support'
        case 2:
            return sectionContent[2].count
        default:
            return sectionContent[0].count
        }
    }
    
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        return sectionTitles[section]  // section 0 is the 1st section
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)
        
        // Configure the cell...array of content within array of headers
        cell.textLabel?.text = sectionContent[(indexPath as NSIndexPath).section][(indexPath as NSIndexPath).row]
        
        var imageName:String!
        
        switch (indexPath as NSIndexPath).section {
            
        case 0:  // Section 0 Setup
            switch (indexPath as NSIndexPath).row {
            case 0: imageName = "person.text.rectangle"
            default: imageName = "questionmark"
            }
            
        case 1: // section 1 Support
            switch (indexPath as NSIndexPath).row {
            case 0: imageName = "info.circle"
            case 1: imageName = "person.2"
            case 2: imageName = "envelope"
            default: imageName = "questionmark"
            }
        case 2:
            switch (indexPath as NSIndexPath).row {
            case 0:
                imageName = ""
                cell.textLabel?.textColor = .red
                cell.textLabel?.textAlignment = .center
            default:
                imageName = ""
            }
        default:
            break
        }
        
        cell.imageView?.image = UIImage(systemName: imageName)
        return cell
    }
    
    // MARK: Navigation Segues
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch (indexPath as NSIndexPath).section {
            
        case 0: // Section 0 Setup
            switch (indexPath as NSIndexPath).row {
            case 0:
                print("Touch User Name")
            default:
                print(#function, "Error in Switch")
            }
            
        case 1: // section 1 Support
            switch (indexPath as NSIndexPath).row {
            case 0:
                appInfo()
            case 1:
                urlLink()
            case 2:
                sendMail()
            default:
                appInfo()
            }
        case 2:
            switch (indexPath as NSIndexPath).row {
            case 0:
                logOut()
            default:
                print(#function, "Error in Switch")
            }
            
        default: break
            
        } //end switch
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

extension ProfileVC: UIImagePickerControllerDelegate,  UINavigationControllerDelegate {
    func presentPhotoActionSheet() {
        print("Click Image")
        let actionSheet = UIAlertController(title: "Profile Picture",
                                            message: "How would you like to select a picture?",
                                            preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                            handler: nil))
        actionSheet.addAction(UIAlertAction(title: "Take Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            // [weak self] -> self need to add question mark
            self?.presentCamera()
            
        }))
        actionSheet.addAction(UIAlertAction(title: "Choose Photo",
                                            style: .default,
                                            handler: { [weak self] _ in
            self?.presentPhotoPicker()
        }))
        
        present(actionSheet, animated: true)
    }
    
    func presentCamera() {
        let vc = UIImagePickerController()
        vc.sourceType = .camera
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func presentPhotoPicker() {
        let vc = UIImagePickerController()
        vc.sourceType = .photoLibrary
        vc.delegate = self
        vc.allowsEditing = true
        present(vc, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true, completion: nil)
        print(info)
        guard let selectedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else {
            return
        }
        self.imageView.image = selectedImage
        // upload image
      
        guard let data = selectedImage.pngData(),
              let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return
        }
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = "\(safeEmail)_profile_picture.png"
        StorageManager.shared.uploadProfilePicture(with: data,
                                                   fileName: fileName) { result in
            switch result {
            case .success(let downloadUrl):
                UserDefaults.standard.set(downloadUrl, forKey: "profile_picture_url")
                print(downloadUrl)
            case .failure(let error):
                print("Storage manager error: \(error)")
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}

extension ProfileVC: MFMailComposeViewControllerDelegate {
    func sendMail() {
        if MFMailComposeViewController.canSendMail() {
            let vc = MFMailComposeViewController()
            vc.delegate = self
            vc.setSubject("Contact Us / Feedback")
            vc.setToRecipients(["willychang17@gmail.com"])
            vc.setMessageBody("<h1>Hello Willy!</h1>", isHTML: true)
            present(vc, animated: true)
        }
        else {
            print("Mail services are not available")
            
        }
        
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
}
