import UIKit
import FirebaseAuth
import JGProgressHUD

class RegisterVC: UIViewController {
    
    private let spinner = JGProgressHUD(style: .dark)
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.clipsToBounds = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "person.circle")
        imageView.tintColor = .gray
        imageView.contentMode = .scaleAspectFit
        imageView.layer.masksToBounds = true
        imageView.layer.borderWidth = 2
        imageView.layer.borderColor = UIColor.lightGray.cgColor
        return imageView
    }()
    
    private let firstNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "First Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let lastNameField: UITextField = {
        let field = UITextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .continue
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Last Name..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        return field
    }()
    
    private let emailField: BindingTextField = {
        let field = BindingTextField()
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
    
    private let emailValidationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .red
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let passwordField: BindingTextField = {
        let field = BindingTextField()
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
    
    private let passwordValidationLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .red
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let checkPasswordField: BindingTextField = {
        let field = BindingTextField()
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
        field.returnKeyType = .done
        field.layer.cornerRadius = 12
        field.layer.borderWidth = 1
        field.layer.borderColor = UIColor.lightGray.cgColor
        field.placeholder = "Password Again..."
        field.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 5, height: 0))
        field.leftViewMode = .always
        field.backgroundColor = .secondarySystemBackground
        field.isSecureTextEntry = true
        return field
    }()
    
    private let checkPasswordLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .left
        label.textColor = .red
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.isHidden = true
        return label
    }()
    
    private let registerButton: UIButton = {
        let button = UIButton()
        button.setTitle("Register", for: .normal)
        button.backgroundColor = .systemGreen
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.layer.masksToBounds = true
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        return button
    }()
    
    private var correctEmail = false
    private var correctPassword = false
    private var samePassword = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Create an account"
        view.backgroundColor = .systemBackground
        
        firstNameField.delegate = self
        lastNameField.delegate = self
        emailField.delegate = self
        passwordField.delegate = self
        checkPasswordField.delegate = self
        
        // Add subviews
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        scrollView.addSubview(firstNameField)
        scrollView.addSubview(lastNameField)
        scrollView.addSubview(emailField)
        scrollView.addSubview(emailValidationLabel)
        scrollView.addSubview(passwordField)
        scrollView.addSubview(passwordValidationLabel)
        scrollView.addSubview(checkPasswordField)
        scrollView.addSubview(checkPasswordLabel)
        scrollView.addSubview(registerButton)
        
        imageView.isUserInteractionEnabled = true
        scrollView.isUserInteractionEnabled = true
        
        let gesture = UITapGestureRecognizer(target: self,
                                             action: #selector(didTapChangeProfilePic))
        imageView.addGestureRecognizer(gesture)
        
        registerButton.addTarget(self,
                              action: #selector(registerButtonTapped),
                              for: .touchUpInside)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
        view.addGestureRecognizer(tap) // Add gesture recognizer to background view
        
        setupTextField()
    }
    
    @objc func didTapChangeProfilePic() {
        print("Change pic called")
        presentPhotoActionSheet()
    }
    
    // Dismiss Keyboard When Clicking On Background
    @objc func handleTap() {
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        checkPasswordField.resignFirstResponder()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        scrollView.frame = view.bounds
        let size = scrollView.width/3
        imageView.frame = CGRect(x: (scrollView.width-size)/2,
                                 y: 20,
                                 width: size,
                                 height: size)
        imageView.layer.cornerRadius = imageView.width/2.0
        
        firstNameField.frame = CGRect(x: 30,
                                  y: imageView.bottom+20,
                                  width: scrollView.width-60,
                                  height: 35)
        lastNameField.frame = CGRect(x: 30,
                                  y: firstNameField.bottom+20,
                                  width: scrollView.width-60,
                                  height: 35)
        emailField.frame = CGRect(x: 30,
                                  y: lastNameField.bottom+20,
                                  width: scrollView.width-60,
                                  height: 35)
        emailValidationLabel.frame = CGRect(x: 35,
                                            y: emailField.bottom+3,
                                            width: scrollView.width-60,
                                            height: 14)
        passwordField.frame = CGRect(x: 30,
                                     y: emailValidationLabel.bottom+3,
                                     width: scrollView.width-60,
                                     height: 35)
        passwordValidationLabel.frame = CGRect(x: 35,
                                               y: passwordField.bottom+3,
                                               width: scrollView.width-60,
                                               height: 14)
        checkPasswordField.frame = CGRect(x: 30,
                                          y: passwordValidationLabel.bottom+3,
                                          width: scrollView.width-60,
                                          height: 35)
        checkPasswordLabel.frame = CGRect(x: 35,
                                          y: checkPasswordField.bottom+3,
                                          width: scrollView.width-60,
                                          height: 14)
        registerButton.frame = CGRect(x: 30,
                                   y: checkPasswordLabel.bottom+15,
                                   width: scrollView.width-60,
                                   height: 52)
    }
    
    @objc private func registerButtonTapped() {
        
        firstNameField.resignFirstResponder()
        lastNameField.resignFirstResponder()
        emailField.resignFirstResponder()
        passwordField.resignFirstResponder()
        checkPasswordField.resignFirstResponder()
        
        guard correctEmail == true,
              correctPassword == true,
              samePassword == true else {
            print("can not register")
            return
        }
        
        guard let firstName = firstNameField.text,
              let lastName = lastNameField.text,
              let email = emailField.text,
              let password = passwordField.text,
              !email.isEmpty,
              !password.isEmpty,
              !firstName.isEmpty,
              !lastName.isEmpty,
              password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        spinner.show(in: view)
        
        // MARK: Firebase Register
        DatabaseManager.shared.userExists(with: email) {  [weak self] exists in
            guard let strongSelf = self else {
                return
            }
            
            DispatchQueue.main.async {
                strongSelf.spinner.dismiss()
            }
            
            guard !exists else {
                // user already exists
                strongSelf.alertUserLoginError(message: "Looks like a user account for that email address already exists.")
                return
            }
        }
        
        FirebaseAuth.Auth.auth().createUser(withEmail: email, password: password) { [weak self] authResult, error in
            guard let strongSelf = self else {
                return
            }
            
            // set UserDefaults
            UserDefaults.standard.setValue(email, forKey: "email")
            UserDefaults.standard.setValue("\(firstName) \(lastName)", forKey: "name")
            
            guard authResult != nil, error == nil else {
                print("Error creating user")
                return
            }
            let chatUser = ChatAppUser(firstName: firstName,
                                       lastName: lastName,
                                       emailAddress: email)
            DatabaseManager.shared.insertUser(with: chatUser) { success in
                if success {
                    // upload image
                    guard let image = strongSelf.imageView.image,
                          let data = image.pngData() else {
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
                }
            }
            strongSelf.navigationController?.dismiss(animated: true, completion: nil)

        }
        
    }
    
    func alertUserLoginError(message: String = "Please enter all information to create a new account.") {
        let alert = UIAlertController(title: "Woops",
                                      message: message,
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dismiss",
                                      style: .cancel,
                                      handler:  nil))
        present(alert, animated: true)
    }
    
    // MARK: Format Check
    private func setupTextField() {
        emailField.bind { [weak self] text in
            guard let strongSelf = self else {
                return
            }
            let isValidEmail = text.emailValidation()
            self?.emailValidationLabel.isHidden = false
            if isValidEmail {
                self?.emailValidationLabel.text = ""
                strongSelf.correctEmail = true
            }
            else {
                self?.emailValidationLabel.text = "Email is not valid!"
                strongSelf.correctEmail = false
            }
            
        }
        passwordField.bind { [weak self] text in
            guard let strongSelf = self else {
                return
            }
            let isValidPassword = text.passwordValidation()
            self?.passwordValidationLabel.isHidden = false
            if isValidPassword {
                self?.passwordValidationLabel.text = ""
                strongSelf.correctPassword = true
            }
            else {
                self?.passwordValidationLabel.text = "At least 8 characters and 1 digit!"
                strongSelf.correctPassword = false
            }
            
        }
        checkPasswordField.bind { [weak self] text in
            guard let strongSelf = self else {
                return
            }
            self?.checkPasswordLabel.isHidden = false
            if(self?.passwordField.text != self?.checkPasswordField.text) {
                self?.checkPasswordLabel.text =  "Password is not the same!"
                strongSelf.samePassword = false
            }
            else {
                self?.checkPasswordLabel.text =  ""
                strongSelf.samePassword = true
            }
        }
    }
    
    
}

extension RegisterVC: UITextFieldDelegate {
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        
        if textField == emailField {
            passwordField.becomeFirstResponder()
        }
        else if textField == checkPasswordField {
            view.endEditing(true)
        }
        
        return true
    }
}

extension RegisterVC: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func presentPhotoActionSheet() {
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
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
}



