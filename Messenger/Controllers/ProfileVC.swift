import UIKit
import FirebaseAuth
import FacebookLogin
import GoogleSignIn

class ProfileVC: UIViewController {
    
    @IBOutlet var tableView: UITableView!
    
    let data = ["Log out"]

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.delegate = self
        tableView.dataSource = self
    }
    


}

extension ProfileVC: UITableViewDelegate,UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)
        cell.textLabel?.text = data[indexPath.row]
        cell.textLabel?.textAlignment = .center
        cell.textLabel?.textColor = .red
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let actionSheet = UIAlertController(title: "Are you sure you want to log out?",
                                      message: "",
                                      preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Log out",
                                      style: .destructive,
                                      handler: { [weak self] _ in
            guard let strongSelf = self else {
                return
            }
            
            // Facebook - Log Out
            FacebookLogin.LoginManager().logOut()
            
            // Google - Log out
            GIDSignIn.sharedInstance.signOut()
            
            do {
                try FirebaseAuth.Auth.auth().signOut()
                
                let vc = LoginVC()
                let nav = UINavigationController(rootViewController: vc)
                nav.modalPresentationStyle = .fullScreen
                strongSelf.present(nav, animated: false)
            } catch {
                print("Failed to log out: \(error)")
            }
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel",
                                            style: .cancel,
                                             handler: nil))
        
        present(actionSheet, animated: true)
     
    }
    
}
