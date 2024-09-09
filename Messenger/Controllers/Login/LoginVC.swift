import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn
import JGProgressHUD
import AuthenticationServices
import CryptoKit
import SwiftUI
//import RealmSwift

final class LoginVC: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    // Unhashed nonce.
    fileprivate var currentNonce: String?
    
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
        field.backgroundColor = .secondarySystemBackground
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
        field.backgroundColor = .secondarySystemBackground
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
    
    private let donNotHaveaAccountLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 20, weight: .medium)
        label.textAlignment = .center
        label.textColor = UIColor.label
        label.text = "Don't have an account?"
        return label
    }()
    
    private let signupButton: UIButton = {
        let button = UIButton()
        button.setTitle("Sign Up", for: .normal)
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
        button.style = GIDSignInButtonStyle.wide
        button.colorScheme = GIDSignInButtonColorScheme.dark
        return button
    }()
    
    private let appleLoginButton: ASAuthorizationAppleIDButton = {
        let button = ASAuthorizationAppleIDButton(authorizationButtonType: .signUp,
                                                  authorizationButtonStyle: .whiteOutline)
        return button
    }()
    
//    @available(iOS 13, *)
//    func startSignInWithAppleFlow() {
//        let nonce = randomNonceString()
//        currentNonce = nonce
//        let appleIDProvider = ASAuthorizationAppleIDProvider()
//        let request = appleIDProvider.createRequest()
//        request.requestedScopes = [.fullName, .email]
//        request.nonce = sha256(nonce)
//        
//        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
//        authorizationController.delegate = self
//        authorizationController.presentationContextProvider = self
//        authorizationController.performRequests()
//    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Chaaat"
        view.backgroundColor = .systemBackground // introduce in iOS 13 (semantic color palette)
        
        emailField.delegate = self
        passwordField.delegate = self
        facebookLoginButton.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(emailField)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(loginButton)
        scrollView.addSubview(donNotHaveaAccountLabel)
        scrollView.addSubview(signupButton)
        scrollView.addSubview(facebookLoginButton)
        scrollView.addSubview(googleLoginButton)
        scrollView.addSubview(appleLoginButton)
        
        loginButton.addTarget(self,
                              action: #selector(loginButtonTapped),
                              for: .touchUpInside)
        
        signupButton.addTarget(self,
                               action: #selector(didTapRegister),
                               for: .touchUpInside)
        
        googleLoginButton.addTarget(self,
                                    action: #selector(googleButtonTapped),
                                    for: .touchUpInside)
        
        appleLoginButton.addTarget(self,
                                   action: #selector(appleButtonTapped),
                                   for: .touchUpInside)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        let width = scrollView.width-100
        let height = CGFloat(35)
        let positionX = view.center.x-(width/2)
        
        imageView.frame = CGRect(x: (scrollView.width-size*1.5)/2,
                                 y: 0,
                                 width: size*1.5,
                                 height: size*1.5)
        emailField.frame = CGRect(x: positionX,
                                  y: imageView.bottom,
                                  width: width,
                                  height: height)
        passwordField.frame = CGRect(x: positionX,
                                     y: emailField.bottom+15,
                                     width: width,
                                     height: height)
        loginButton.frame = CGRect(x: positionX,
                                   y: passwordField.bottom+15,
                                   width: width,
                                   height: height)
        
        
        donNotHaveaAccountLabel.translatesAutoresizingMaskIntoConstraints = false
        var noALabelConstraints = [NSLayoutConstraint]()
        noALabelConstraints.append(NSLayoutConstraint(item: donNotHaveaAccountLabel, attribute: .centerX, relatedBy: .equal,
                                                      toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0))
        noALabelConstraints.append(NSLayoutConstraint(item: donNotHaveaAccountLabel, attribute: .bottom, relatedBy: .equal,
                                                      toItem: signupButton, attribute: .top, multiplier: 1.0, constant: -15))
        noALabelConstraints.append(NSLayoutConstraint(item: donNotHaveaAccountLabel, attribute: .width, relatedBy: .equal,
                                                      toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width))
        noALabelConstraints.append(NSLayoutConstraint(item: donNotHaveaAccountLabel, attribute: .height, relatedBy: .equal,
                                                      toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height))
        NSLayoutConstraint.activate(noALabelConstraints)    // these constraints must activate than will work
        
        signupButton.translatesAutoresizingMaskIntoConstraints = false
        var signupBtnConstraints = [NSLayoutConstraint]()
        signupBtnConstraints.append(NSLayoutConstraint(item: signupButton, attribute: .centerX, relatedBy: .equal,
                                                       toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0))
        signupBtnConstraints.append(NSLayoutConstraint(item: signupButton, attribute: .bottom, relatedBy: .equal,
                                                       toItem: facebookLoginButton, attribute: .top, multiplier: 1.0, constant: -15))
        signupBtnConstraints.append(NSLayoutConstraint(item: signupButton, attribute: .width, relatedBy: .equal,
                                                       toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width))
        signupBtnConstraints.append(NSLayoutConstraint(item: signupButton, attribute: .height, relatedBy: .equal,
                                                       toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height))
        NSLayoutConstraint.activate(signupBtnConstraints)    // these constraints must activate than will work
        
        facebookLoginButton.translatesAutoresizingMaskIntoConstraints = false
        var facebookBtnConstraints = [NSLayoutConstraint]()
        facebookBtnConstraints.append(NSLayoutConstraint(item: facebookLoginButton, attribute: .centerX, relatedBy: .equal,
                                                         toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0))
        facebookBtnConstraints.append(NSLayoutConstraint(item: facebookLoginButton, attribute: .bottom, relatedBy: .equal,
                                                         toItem: googleLoginButton, attribute: .top, multiplier: 1.0, constant: -15))
        facebookBtnConstraints.append(NSLayoutConstraint(item: facebookLoginButton, attribute: .width, relatedBy: .equal,
                                                         toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width))
        facebookBtnConstraints.append(NSLayoutConstraint(item: facebookLoginButton, attribute: .height, relatedBy: .equal,
                                                         toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height))
        NSLayoutConstraint.activate(facebookBtnConstraints)    // these constraints must activate than will work
        
        googleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        var googleBtnConstraints = [NSLayoutConstraint]()
        googleBtnConstraints.append(NSLayoutConstraint(item: googleLoginButton, attribute: .centerX, relatedBy: .equal,
                                                       toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0))
        googleBtnConstraints.append(NSLayoutConstraint(item: googleLoginButton, attribute: .bottom, relatedBy: .equal,
                                                       toItem: appleLoginButton, attribute: .top, multiplier: 1.0, constant: -15))
        googleBtnConstraints.append(NSLayoutConstraint(item: googleLoginButton, attribute: .width, relatedBy: .equal,
                                                       toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width+5))
        googleBtnConstraints.append(NSLayoutConstraint(item: googleLoginButton, attribute: .height, relatedBy: .equal,
                                                       toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height+15))
        NSLayoutConstraint.activate(googleBtnConstraints)    // these constraints must activate than will work
        
        appleLoginButton.translatesAutoresizingMaskIntoConstraints = false
        var appleBtnConstraints = [NSLayoutConstraint]()
        appleBtnConstraints.append(NSLayoutConstraint(item: appleLoginButton, attribute: .centerX, relatedBy: .equal,
                                                      toItem: view, attribute: .centerX, multiplier: 1.0, constant: 0))
        appleBtnConstraints.append(NSLayoutConstraint(item: appleLoginButton, attribute: .bottom, relatedBy: .equal,
                                                      toItem: view, attribute: .bottom, multiplier: 1.0, constant: -30))
        appleBtnConstraints.append(NSLayoutConstraint(item: appleLoginButton, attribute: .width, relatedBy: .equal,
                                                      toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: width))
        appleBtnConstraints.append(NSLayoutConstraint(item: appleLoginButton, attribute: .height, relatedBy: .equal,
                                                      toItem: nil, attribute: .notAnAttribute, multiplier: 0, constant: height))
        NSLayoutConstraint.activate(appleBtnConstraints)    // these constraints must activate than will work
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        
        if UserDefaults.standard.bool(forKey: "hasViewedWalkthrough") {
            return
        }
        
        let storyboard = UIStoryboard(name: "Onboarding", bundle: nil)
        if let walkingthroughVC = storyboard.instantiateViewController(withIdentifier: "WalkthroughVC") as? WalkthroughVC {
            
            present(walkingthroughVC, animated: true, completion: nil)
        }
        
    }
    
    // MARK: Firebase Log in
    @objc private func loginButtonTapped() {
        
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        
        guard let email = emailField.text, let password = passwordField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
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
            
            let safeEmail = DatabaseManager.safeEmail(emailAddress: email)
            DatabaseManager.shared.getDataFor(path: safeEmail) { result in
                switch result {
                case .success(let data):
                    guard let userData = data as? [String: Any],
                          let firstName = userData["first_name"] as? String,
                          let lastName = userData["last_name"] as? String else {
                        return
                    }
                    UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                case .failure(let error):
                    print("Failed to read data with error: \(error)")
                }
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            print("Successfully Logged In Firebase User: \(user)")
            NotificationCenter.default.post(name: .didLogInNotification, object: nil)
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
                  let firstName = user?.profile?.givenName,
                  let lastName = user?.profile?.familyName else {
                return
            }
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
            guard let user = user else {
                return
            }
            
            print("Did sign in with Google: \(user)")
            DatabaseManager.shared.userExists(with: email) { exists in
                if !exists {
                    // insert to database
                    let chatUser = ChatAppUser(firstName: firstName,
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
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            }
        }
    }
    
    // MARK: Apple Login in
    @objc func appleButtonTapped() {
        let request = creatAppleIdRequest()
        let authorizationController = ASAuthorizationController(authorizationRequests: [request])
        authorizationController.delegate = self
        authorizationController.presentationContextProvider = self
        authorizationController.performRequests()
    }
    
    func creatAppleIdRequest() -> ASAuthorizationAppleIDRequest {
        let appleIDProvider = ASAuthorizationAppleIDProvider()
        let request = appleIDProvider.createRequest()
        request.requestedScopes = [.fullName, .email]
        let nonce = randomNonceString()
        request.nonce = sha256(nonce)
        currentNonce = nonce
        return request
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
            
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
            
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
                print("Succedssfully logged Facebook user in")
                NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                
            }
        }
        
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

// MARK: Apple Authorization Delegate
extension LoginVC: ASAuthorizationControllerDelegate{
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
            
            // ask apple server for token
            
            guard let nonce = currentNonce else {
                fatalError("Invalid state: A login callback was received, but no login")
            }
            guard let appleIDToken = appleIDCredential.identityToken else {
                print("Unalbe to fetch identity token  ")
                return
            }
            guard let idTokenString = String(data: appleIDToken, encoding: .utf8) else {
                print("Unable to seriaiez tokeb string from data: \(appleIDToken.debugDescription)")
                return
            }
            
            if let newEmail = appleIDCredential.email { // first time login
                // check user exist
                DatabaseManager.shared.userExists(with: newEmail) { exists in
                    if !exists {
                        // Create an account in your system.
                        guard let fullName = appleIDCredential.fullName else {
                            print("can not get user fullName")
                            return
                        }
                        
                        guard var firstName = fullName.givenName else {
                            return
                        }
                        
                        if fullName.middleName != nil {
                            firstName = firstName + (fullName.middleName ?? "")
                        }
                        guard let lastName = fullName.familyName else {
                            return
                        }
                        UserDefaults.standard.set(newEmail, forKey: "email")
                        UserDefaults.standard.set("\(firstName) \(lastName)", forKey: "name")
                        
                        let chatUser = ChatAppUser(firstName: firstName,
                                                   lastName: lastName,
                                                   emailAddress: newEmail)
                        DatabaseManager.shared.insertUser(with: chatUser) { success in
                            
                        }
                    }
                }
            }
            
            
            
            // Initialize a Firebase credential.
            let credential = OAuthProvider.credential(withProviderID: "apple.com",
                                                      idToken: idTokenString,
                                                      rawNonce: nonce)
            
            FirebaseAuth.Auth.auth().signIn(with: credential) { [weak self] authResult, error in
                guard let strongSelf = self else {
                    return
                }
                
                guard authResult != nil, error == nil else {
                    if let error = error {
                        print("Apple credential login failed, MFA may needed - \(error)")
                    }
                    return
                }
                guard let email = authResult?.user.email as? String else {
                    return
                }
                DatabaseManager.shared.userExists(with: email) { exists in
                    print("user exist")
                }
                UserDefaults.standard.set(email, forKey: "email")
                print("Succedssfully logged Apple user in: \(email)")
                DatabaseManager.shared.getUserName { result in
                    switch result {
                    case .failure(let error):
                        print("fetch user name failed: \(error)")
                    case .success(let name):
                        print("user's name: \(name)")
                        UserDefaults.standard.set(name, forKey: "name")
                        NotificationCenter.default.post(name: .didLogInNotification, object: nil)
                        strongSelf.navigationController?.dismiss(animated: true, completion: nil)
                    }
                }
                
            }
            
        }
    }
}

extension LoginVC: ASAuthorizationControllerPresentationContextProviding{
    func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        return self.view.window!
    }
    
    // Adapted from https://auth0.com/docs/api-auth/tutorials/nonce#generate-a-cryptographically-random-nonce
    private func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] =
        Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length
        
        while remainingLength > 0 {
            let randoms: [UInt8] = (0 ..< 16).map { _ in
                var random: UInt8 = 0
                let errorCode = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if errorCode != errSecSuccess {
                    fatalError(
                        "Unable to generate nonce. SecRandomCopyBytes failed with OSStatus \(errorCode)"
                    )
                }
                return random
            }
            
            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }
                
                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }
        
        return result
    }
    
    private func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashedData = SHA256.hash(data: inputData)
        let hashString = hashedData.compactMap {
            String(format: "%02x", $0)
        }.joined()
        
        return hashString
    }
}


