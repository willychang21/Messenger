import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn
import SDWebImage

final class ProfileVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    private var loginObserver: NSObjectProtocol?
    
    var data = [ProfileViewModel]()
    
    var imageView = UIImageView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(ProfileTableViewCell.self,
                           forCellReuseIdentifier: ProfileTableViewCell.identifier)

        userInfo()
        logOut()
        
        tableView.delegate = self
        tableView.dataSource = self
        tableView.tableHeaderView = createTableHeader()
        
        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification,
                                                               object: nil,
                                                               queue: .main) { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            self?.tableView.tableHeaderView = strongSelf.createTableHeader()
            strongSelf.updateUserInfo()
        }
        
    }
    
    func createTableHeader() -> UIView? {
        
        guard let email = UserDefaults.standard.value(forKey: "email") as? String else {
            return nil
        }
        
//        if let observer = loginObserver {
//            NotificationCenter.default.removeObserver(observer)
//        }
        
        let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
        let fileName = safeEmail + "_profile_picture.png"
        
        let path = "images/"+fileName
        let headerView = UIView(frame: CGRect(x: 0,
                                              y: 0,
                                              width: self.view.width,
                                              height: 300))
        headerView.backgroundColor = .link
        
        imageView = UIImageView(frame: CGRect(x: (view.width-150) / 2,
                                                  y: 75,
                                                  width: 150,
                                                  height: 150))
        
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
        headerView.addSubview(imageView)
        return headerView
    }
    
    @objc func didTapChangeProfilePic() {
        presentPhotoActionSheet()
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
    
    func userInfo() {
        
        guard let name = UserDefaults.standard.value(forKey: "name"),
              let email = UserDefaults.standard.value(forKey: "email") else {
            print("Do not have user's information")
            return
        }
        
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Name : \(name)",
                                     handler: nil))
        data.append(ProfileViewModel(viewModelType: .info,
                                     title: "Email : \(email)",
                                     handler: nil))
    }
    
    func logOut() {
        
        data.append(ProfileViewModel(viewModelType: .logout,
                                     title: "Log Out",
                                     handler: { [weak self] in
            guard let strongSelf = self else {
                return
            }
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
            
            strongSelf.present(actionSheet, animated: true)
        }))
    }
    
    func updateUserInfo() {
        guard let name = UserDefaults.standard.value(forKey: "name"),
              let email = UserDefaults.standard.value(forKey: "email") else {
            print("update user info failed")
            return
        }
        print("Successfully update user info.")
        data[0].title = "Name : \(name)"
        data[1].title = "Email : \(email)"
        tableView.reloadData()
    }
    
}

extension ProfileVC: UITableViewDelegate,UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let viewModel = data[indexPath.row]
        let cell = tableView.dequeueReusableCell(withIdentifier: ProfileTableViewCell.identifier, for: indexPath) as! ProfileTableViewCell
        cell.setUp(with: viewModel)
//        cell.textLabel?.text = data[indexPath.row]
//        cell.textLabel?.textAlignment = .center
//        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        data[indexPath.row].handler?()
    }
    
}

class ProfileTableViewCell: UITableViewCell {
    
    static let identifier = "ProfileTableViewCell"
    
    public func setUp(with viewModel: ProfileViewModel) {
        self.textLabel?.text = viewModel.title
        
        switch viewModel.viewModelType {
        case .info:
            textLabel?.textColor = .label
            textLabel?.textAlignment = .left
            selectionStyle = .none
        case .logout:
            textLabel?.textColor = .red
            textLabel?.textAlignment = .center
        }
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
