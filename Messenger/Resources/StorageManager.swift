import Foundation
import FirebaseStorage

final class StorageManager {
    
    static let shared = StorageManager()
    
    private let storage = Storage.storage().reference()
    
    /* URL string
     /images/afraz0-email-com_profile_picture.png
     */
    
    public typealias UploadPictureCompletion = (Result<String, Error>)-> Void
    
    // Uploads picture to firebase storage and returns completion with url string to download
    public func uploadProfilePicture(with data: Data, fileName: String, completion: @escaping UploadPictureCompletion) {
        storage.child("images/\(fileName)").putData(data, metadata: nil) { metadata, error in
            guard error == nil else {
                // failed
                print("failed to upload data to firebase for picture")
                completion(.failure(StorageErrors.failToUpload))
                return
            }
            
            self.storage.child("images/\(fileName)").downloadURL { url, error in
                guard let url = url else {
                    print("Failed to get download url")
                    completion(.failure(StorageErrors.failToGetDownloadUrl))
                    return
                }
                
                let urlString = url.absoluteString
                print("download url returneddownload url returned: \(urlString)")
                completion(.success(urlString))

            }
        }
    }
    
    public enum StorageErrors: Error {
        case failToUpload
        case failToGetDownloadUrl
    }
}
