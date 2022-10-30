import UIKit
import FirebaseStorage
import FirebaseAuth
import FirebaseFirestore

class LogInViewController: UIViewController {
    @IBOutlet private weak var errorLabel: UILabel!
    
    @IBOutlet private weak var emailTextfield: UITextField!
    @IBOutlet private weak var passwordTextfield: UITextField!
    
    @IBOutlet private weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var logInButton: UIButton!
    
    private var chatSender: ChatUser?
    private var errorMessage: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        customizeViewElements()
    }
    
    //MARK: -- preparing for segue
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == K.Segue.logInToChat {
            if let destinationVC = segue.destination as? ChatViewController {
                destinationVC.setChatSender(chatSender)
            }
        } else if segue.identifier == K.Segue.logInToNewUserData {
            if let destinationVC = segue.destination as? NewUserDataViewController {
                destinationVC.setChatSender(chatSender, errorMessage: errorMessage)
            }
        }
    }
}


//MARK: - @IBActions


private extension LogInViewController {
    @IBAction func logInButtonPressed(_ sender: UIButton) {
        guard let safeUserEmail = emailTextfield.text,
              let safeUserPassword = passwordTextfield.text else { return }
        
        activateScreenWaitingMode()
        
        Auth.auth().signIn(withEmail: safeUserEmail, password: safeUserPassword) {
            [weak self] authResult, error in
            DispatchQueue.main.async {
                if let safeError = error {
                    print(safeError)
                    self?.failedToLogIn(withMessage: safeError.localizedDescription)
                } else {
                    self?.checkIsUserDataExists()
                }
            }
        }
    }
}


//MARK: - Private methods


private extension LogInViewController {
    //MARK: -- user data checking
    func checkIsUserDataExists() {
        guard let safeCurrentUserId = Auth.auth().currentUser?.uid else {
            self.failedToLogIn(withMessage: "Try again")
            return
        }
        
        Firestore.firestore().collection(K.FStore.usersCollection).document(safeCurrentUserId).getDocument { [weak self] document, error in
            if let document = document, document.exists {
                do {
                    let chatUserData = try document.data(as: ChatUserData.self)
                    
                    self?.chatSender = ChatUser(data: chatUserData, avatar: UIImage.defaultSingleAvatar)
                    self?.downloadAvatar(with: chatUserData.avatarURL)
                }
                catch {
                    self?.failedToLogIn(withMessage: "Try again")
                    return
                }
            } else {
                self?.errorMessage = "Your user data doesn't exist. Set it please."
                self?.navigateToNewUserData()
            }
        }
    }
    
    func downloadAvatar(with url: String) {
        let ref = Storage.storage().reference(forURL: url)
        
        let megaByte = Int64(1 * 1024 * 1024)
        
        ref.getData(maxSize: megaByte) { [weak self] data, error in
            if let safeError = error {
                print(safeError)
                
                self?.errorMessage = "Your avatar does not exist. Set it or click \"Continue\" to leave the default one."
                self?.navigateToNewUserData()
            } else {
                guard let safeAvatarData = data,
                      let safeAvatar = UIImage(data: safeAvatarData)
                else {
                    self?.failedToLogIn(withMessage: "Try again")
                    return
                }
                
                self?.chatSender?.avatar = safeAvatar
                self?.navigateToChat()
            }
        }
    }
    
    //MARK: -- others
    func activateScreenWaitingMode() {
        errorLabel.text = K.Case.emptyString
        view.isUserInteractionEnabled = false
        progressIndicator.startAnimating()
    }
    
    func failedToLogIn(withMessage message: String) {
        errorLabel.text = message
        view.isUserInteractionEnabled = true
        progressIndicator.stopAnimating()
    }
    
    func navigateToChat() {
        performSegue(withIdentifier: K.Segue.logInToChat, sender: self)
    }
    
    
    func navigateToNewUserData() {
        performSegue(withIdentifier: K.Segue.logInToNewUserData, sender: self)
    }
}


//MARK: - Set up methods


private extension LogInViewController {
    func customizeViewElements() {
        progressIndicator.hidesWhenStopped = true
    }
}

