import Foundation

extension String {
    /// Email Validation
    func emailValidation() -> Bool {
        // One or more characters followed by an "@",
        // then one or more characters followed by a ".",
        // and finishing with one or more characters
        let emailRegularExpression = #"^\S+@\S+\.\S+$"#
        
        // so result is a Range<String.Index>
        let result = self.range(
            of: emailRegularExpression,
            options: .regularExpression
        )

        return result != nil
    }
    
    /// Password Validation
    func passwordValidation() -> Bool {
        let passwordRegularExpression =
        // At least 8 characters
        #"(?=.{8,})"# +
        
        // At least one digit
        #"(?=.*\d)"#
        
        // so result is a Range<String.Index>
        let result = self.range(
            of: passwordRegularExpression,
            options: .regularExpression
        )
        
        return result != nil
    }
}
