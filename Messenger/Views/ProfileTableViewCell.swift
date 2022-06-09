import Foundation
import UIKit

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
        case .sendMail:
            textLabel?.textColor = .label
            textLabel?.textAlignment = .center
            selectionStyle = .none
        case .AboutApp:
            textLabel?.textColor = .label
            textLabel?.textAlignment = .left
            selectionStyle = .none
        }
    }
}
