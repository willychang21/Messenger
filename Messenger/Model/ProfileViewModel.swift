import Foundation

enum ProfileViewModelType {
    case info, logout, sendMail, AboutApp
}

struct ProfileViewModel {
    let viewModelType: ProfileViewModelType
    var title: String
    let handler: (() -> Void)?
}

