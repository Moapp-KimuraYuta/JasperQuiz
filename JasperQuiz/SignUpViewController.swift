//
//  MyPageViewController.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/03/11.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import PKHUD

struct User{
    let name: String
    let createdAt: Timestamp
    let email: String
    let lastScore: Int
    let bio: String
    let iconUrl: String
    
    init(dic: [String:Any]) {
        self.name = dic["name"] as! String
        self.createdAt = dic["createdAt"] as! Timestamp
        self.email = dic["email"] as! String
        self.lastScore = dic["lastScore"] as! Int
        self.bio = dic["bio"] as! String
        self.iconUrl = dic["iconUrl"] as! String
    }
}

class SignUpViewController: UIViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var registerButton: UIButton!
    @IBAction func tappedRegisterButton(_ sender: Any) {
        handleAuthToFirebase()
    }
    @IBAction func tappedHaveAccount(_ sender: Any) {
        let storyBoard = UIStoryboard(name: "MyPage", bundle: nil)
        let loginViewController = storyBoard.instantiateViewController(identifier: "LoginViewController") as! LoginViewController
        navigationController?.pushViewController(loginViewController, animated: true)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        registerButton.layer.cornerRadius = 10
        registerButton.backgroundColor = UIColor.rgb(red: 150, green: 150, blue: 150)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        usernameTextField.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    private func handleAuthToFirebase() {
        HUD.show(.progress, onView: view)
        guard let email = emailTextField.text else { return }
        guard let pass = passwordTextField.text else { return }
        Auth.auth().createUser(withEmail: email, password: pass) { ( res, err) in
            if let err = err {
                print("認証情報の保存に失敗しました。\(err)")
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                return
            }
            self.addUserInfoToFirestore(email: email,pass: pass)
        }
    }
    
    private func addUserInfoToFirestore(email:String,pass:String){
        guard let uid = Auth.auth().currentUser?.uid else { return }
        guard let name = self.usernameTextField.text else { return }
        let bio = "よろしくおねがいします。"
        let iconUrl = ""
        let lastScore = 0
        let docData = ["email": email,"name": name,"createdAt": Timestamp(),"lastScore":lastScore,"bio": bio,"iconUrl": iconUrl] as [String : Any]
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.setData(docData) { (err) in
            if let err = err {
                print("ユーザー情報の保存に失敗しました。\(err)")
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                return
            }
            print("ユーザー情報の保存に成功しました。")
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set(pass, forKey: "password")
            userRef.getDocument{ ( snapshot, err ) in
                if let err = err {
                    print("ユーザー情報の取得に失敗しました。\(err)")
                    HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                }
                guard let data = snapshot?.data() else { return }
                let user = User.init(dic: data)
                print("ユーザー情報の取得ができました。\(user.name)")
                HUD.hide{ (_) in
                    HUD.flash(.success,onView: self.view,delay: 1) { (_) in
                        let tab = self.presentingViewController as? UITabBarController
                        tab?.selectedIndex = 0
                        self.presentToTabBarController()
                    }
                }
            }
        }
    }
    
    private func presentToTabBarController() {
        dismiss(animated: true)
    }
    @objc func showKeyboard(notification: Notification){
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        let regiserButtonMaxY = registerButton.frame.maxY
        let distance = regiserButtonMaxY - keyboardMinY + 20
        let transform = CGAffineTransform(translationX: 0, y: -distance)
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = transform
        })
    }
    @objc func hideKeyboard(){
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: [], animations: {
            self.view.transform = .identity
        })
    }
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
}
extension SignUpViewController: UITextFieldDelegate {
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        let usernameIsEmpty = usernameTextField.text?.isEmpty ?? true
        if emailIsEmpty || passwordIsEmpty || usernameIsEmpty {
            registerButton.isEnabled = false
            registerButton.backgroundColor = UIColor.rgb(red: 150, green: 150, blue: 150)
        } else {
            registerButton.isEnabled = true
            registerButton.backgroundColor = UIColor.rgb(red: 0, green: 117, blue: 227)
        }
    }
}
