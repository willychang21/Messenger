import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn
import JGProgressHUD
import RealmSwift

class LoginVC: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    // Google - Sign in Config
    private let clientID = "22490778398-pquuuplolqq5jml953p1gheiv9hupkj1.apps.googleusercontent.com"
    // Create Google Sign In configuration object.
    private lazy var googleConfig: GIDConfiguration = {
        return GIDConfiguration(clientID: clientID)
    }()
    
    // MARK: View
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "logo")
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emailField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Email Address..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        return field
    }()
    
    private let passwordField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .white
        field.isSecureTextEntry = true
        return field
    }()
    
    private let loginButton: UIButton = {
        let button = UIButton()
        button.setTitle("Log in", for: .normal)
        button.backgroundColor = .link
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private let facebookLoginButton: FBLoginButton = {
        let button = FBLoginButton()
        button.permissions = ["email", "public_profile"]
        return button
    }()
    
    private let googleLoginButton: GIDSignInButton = {
        let button = GIDSignInButton()
        return button
    }()
    
    //    private var loginObserver: NSObjectProtocol?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        loginObserver = NotificationCenter.default.addObserver(forName: Notification.Name.didLogInNotification,
        //                                                               object: nil,
        //                                                               queue: .main) { [weak self] _ in
        //            guard let strongSelf = self else { return }
        //            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
        //        }
        
        title = "Login"
        view.backgroundColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Register",
                                                            style: .done,
                                                            target: self,
                                                            action: #selector(didTapRegister))
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        googleLoginButton.addTarget(self,
                                    action: #selector(googleButtonTapped),
                                    for: .touchUpInside)
        
        emailField.delegate = self
        passwordField.delegate = self
        
        facebookLoginButton.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
    }
    
    //    deinit {
    //        if let observer = loginObserver {
    //            NotificationCenter.default.removeObserver(observer)
    //        }
    //    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        emailField.frame = CGRect(x: 30,
                                  y: imageView.bottom+10,
                                  width: scrollView.width-60,
                                  height: 52)
        passwordField.frame = CGRect(x: 30,
                                     y: emailField.bottom+10,
                                     width: scrollView.width-60,
                                     height: 52)
        loginButton.frame = CGRect(x: 30,
                                   y: passwordField.bottom+10,
                                   width: scrollView.width-60,
                                   height: 52)
        facebookLoginButton.frame = CGRect(x: 30,
                                           y: loginButton.bottom+10,
                                           width: scrollView.width-60,
                                           height: 52)
        googleLoginButton.frame = CGRect(x: 30,
                                         y: facebookLoginButton.bottom+10,
                                         width: scrollView.width-60,
                                         height: 52)
        
        
    }
    
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // MARK: Firebase Log in
        FirebaseAuth.Auth.auth().signIn(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard let result = authResult, error == nil else {
                print("Failed to log in user with email: \(email)")
                return
            }
            
            let user = result.user
            print("Logged In User: \(user)")
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)
            
        }
        
    }
    
    // MARK: Google Login in
    @objc func googleButtonTapped() {
        GIDSignIn.sharedInstance.signIn(with: googleConfig, presenting: self) { [unowned self] user, error in
            
            if let error = error {
                print("Fail to sign in with Google: \(error)")
                return
            }
            
            guard let email = user?.profile?.email,
                  let firtName = user?.profile?.givenName,
                  let lastName = user?.profile?.familyName
            else {
                return
            }
            
            guard let user = user else {
                return
            }
            
            print("Did sign in with Google: \(user)")
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    // insert to database
                    let chatUser = ChatAppUser(firstName: firtName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            // upload image
                            guard let userProfile = user.profile else {
                                return
                            }
                            if userProfile.hasImage {
                                guard let url = userProfile.imageURL(withDimension: 200) else {
                                    return
                                }
                                
                                URLSession.shared.dataTask(with: url) { data, _, error in
                                    guard let data = data else {
                                        return
                                    }

                                    let fileName = chatUser.profilePictureFileName
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
                                }.resume()
                            }
                        }
                    }
                }
            }
            
            
            let authentication = user.authentication
            guard let idToken = authentication.idToken else { return }
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: authentication.accessToken)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self]authResult, error in
                guard let strongSelf = self else {
                    return
                }
                guard authResult != nil, error == nil else {
                    print("failed to log in google credential")
                    return
                }
                
                print("Successfully signed in google credential.")
                
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                //                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
            }
        }
    }
    
    func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops",
                                      message: "Please enter all information to log in",
                                      preferredStyle: .alert)
        
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler:  nil))
        
        present(alert, animated: true)
    }
    
    @objc private func didTapRegister() {
        let vc = RegisterVC()
        vc.title = "Create Account"
        navigationController?.pushViewController(vc, animated: true)
    }
    
    
}

extension LoginVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == passwordField {
            loginButtonTapped()
        }
        
        return true
    }
}

// MARK: Facebook Login
extension LoginVC: LoginButtonDelegate {
    
    func loginButtonDidLogOut(_ loginButton: FBLoginButton) {
        // no operation
    }
    
    func loginButton(_ loginButton: FBLoginButton, didCompleteWith result: LoginManagerLoginResult?, error: Error?) {
        guard let token = result?.token?.tokenString else {
            print("User failed ot log in with facebook")
            return
            
        }
        
        let facebookRequeset = FacebookLogin.GraphRequest(graphPath: "me",
                                                          parameters: ["fields": "email, first_name, last_name, picture.type(large)"],
                                                          tokenString: token,
                                                          version: nil,
                                                          httpMethod: .get)
        
        facebookRequeset.start { _, result, error in
            guard let result = result as? [String: Any],
                  error == nil else {
                print("Failed to make facebook graph request")
                return
            }
            
            print("\(result)")
            
            guard let firstName = result["first_name"] as? String,
                  let lastName = result["last_name"] as? String,
                  let email = result["email"] as? String,
                  let picture = result["picture"] as? [String: Any],
                  let data = picture["data"] as? [String: Any],
                  let pictureUrl = data["url"] as? String
            else {
                print("Failed to get email and name from fb result")
                return
            }
            
            
            
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    let chatUser = ChatAppUser(firstName: firstName,
                                               lastName: lastName,
                                               emailAddress: email)
                    DatabaseManager.shared.insertUser(with: chatUser) { success in
                        if success {
                            
                            guard let url = URL(string: pictureUrl) else {
                                return
                            }
                            
                            print("Downloading data from facebook image")
                            
                            URLSession.shared.dataTask(with: url) { data, _, error in
                                guard let data = data else {
                                    print("Failed to get data from facebook")
                                    return
                                }
                                print("got data from FB, uploading...")
                                // upload image
                                let fileName = chatUser.profilePictureFileName
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
                            }.resume()
                            
                        }
                    }
                }
            }
            
            let credential = FacebookAuthProvider.credential(withAccessToken: token)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Facebook credential login failed, MFA may needed - \(error)")
                    }
                    return
                }
                
                print("Succedssfully logged user in")
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            }
        }
        
        
    }
    
}
