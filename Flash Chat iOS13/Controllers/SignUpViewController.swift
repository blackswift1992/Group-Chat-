import UIKit
import FirebaseAuth
import FirebaseFirestore

class SignUpViewController: UIViewController {
    @IBOutlet private weak var errorLabel: UILabel!

    @IBOutlet private weak var emailTextfield: UITextField!
    @IBOutlet private weak var passwordTextfield: UITextField!
    
    @IBOutlet private weak var progressIndicator: UIActivityIndicatorView!
    @IBOutlet private weak var signUpButton: UIButton!

    
    override func viewDidLoad() {
        super.viewDidLoad()
        customizeViewElements()
    }
    
    
    private func customizeViewElements() {
        progressIndicator.hidesWhenStopped = true
    }
    
    
    //замінить рядки на commonView і після цього видалити аутлети які не юзаються
    private func setViewElementsInteraction(_ state: Bool) {
        emailTextfield.isUserInteractionEnabled = state
        passwordTextfield.isUserInteractionEnabled = state
        signUpButton.isUserInteractionEnabled = state
    }
    
    
    private func failedToSignUp(with errorDescription: String) {
        errorLabel.text = errorDescription
        setViewElementsInteraction(true)
        progressIndicator.stopAnimating()
    }
    
    
    private func activateScreenWaitingMode() {
        errorLabel.text = ""
        setViewElementsInteraction(false)
        progressIndicator.startAnimating()
    }
    
    
    //MARK: - SIGN UP BUTTON
    
    
    
    @IBAction private func signUpButtonPressed(_ sender: UIButton) {
        guard let safeUserEmail = emailTextfield.text,
              let safeUserPassword = passwordTextfield.text else { return }
        
        activateScreenWaitingMode()
        
        Auth.auth().createUser(withEmail: safeUserEmail, password: safeUserPassword) { [weak self] authResult, error in
            if let safeError = error {
                print(safeError)
                
                DispatchQueue.main.async {
                    self?.failedToSignUp(with: safeError.localizedDescription)
                }
            } else {
                self?.navigateToNewUserData()
            }
        }
    }
    
    
    private func navigateToNewUserData() {
        performSegue(withIdentifier: K.Segue.signUpToNewUserData, sender: self)
    }
}


