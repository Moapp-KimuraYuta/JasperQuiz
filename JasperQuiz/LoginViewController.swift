//
//  LoginViewController.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/03/18.
//
import UIKit
import Firebase
import FirebaseFirestore
import FirebaseAuth
import GoogleSignIn
import PKHUD

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    private var provider : OAuthProvider?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        loginButtnLayout()
        textFieldDelgateSetting()
        keyboardSetting()
        self.provider = OAuthProvider(providerID:"twitter.com");
    }
    
    func loginButtnLayout() {
        loginButton.layer.cornerRadius = 10
        loginButton.backgroundColor = UIColor.rgb(red: 150, green: 150, blue: 150)
    }
    func textFieldDelgateSetting(){
        emailTextField.delegate = self
        passwordTextField.delegate = self
    }
    func keyboardSetting(){
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @IBAction func didTapLoginButton(_ sender: Any) {
        auth()
    }
    @IBAction func tappedLoginButton(_ sender: Any) {
        self.view.endEditing(true)
        HUD.show(.progress, onView: self.view)
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
            if let err = err {
                print("ログイン情報の取得に失敗しました。\(err)",err)
                HUD.hide { (_) in
                    HUD.flash(.error, delay: 1)
                }
                return
            }
            print("ログインに成功しました。")
            UserDefaults.standard.set(email, forKey: "email")
            UserDefaults.standard.set(password, forKey: "password")
            guard let uid = Auth.auth().currentUser?.uid else { return }
            let userRef = Firestore.firestore().collection("users").document(uid)
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
                        self.presentToTabBarController()
                    }
                }
            }
        }
    }
    
    @IBAction func twitterSignInButton (_ sender: Any) {
        self.provider?.getCredentialWith(_: nil){ (credential, error) in
            if error != nil {
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                print("Twitter error1")
            }
            if let credential = credential {
                HUD.show(.progress, onView: self.view)
                Auth.auth().signIn(with: credential) { (authResult, error) in
                    if error != nil {
                        HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                        print("Twitter error2")
                        print(error!)
                    }else{
                        print("Twitterログインに成功しました。")
                        HUD.hide{ (_) in
                            HUD.flash(.success,onView: self.view,delay: 1) { (_) in
                                self.presentToTabBarController()
                            }
                        }
                    }
                }
            }
        }
    }
    
    private func presentToTabBarController() {
        let tab = self.presentingViewController as? UITabBarController
        tab?.selectedIndex = 0
        dismiss(animated: true)
    }
    
    private func auth() {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        let config = GIDConfiguration(clientID: clientID)
        
        GIDSignIn.sharedInstance.signIn(with: config, presenting: self) { [unowned self] user, error in
            if let error = error {
                print("GIDSignInError: \(error.localizedDescription)")
                return
            }
            
            guard let authentication = user?.authentication,
                  let idToken = authentication.idToken else { return }
            
            let credential = GoogleAuthProvider.credential(withIDToken: idToken, accessToken: authentication.accessToken)
            self.login(credential: credential)
        }
    }
    
    private func login(credential: AuthCredential) {
        HUD.show(.progress, onView: self.view)
        Auth.auth().signIn(with: credential) { authResult, error in
            if let error = error {
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                print(error.localizedDescription)
            } else {
                print("ログイン完了")
                guard let uid = Auth.auth().currentUser?.uid else { return }
                guard let email = Auth.auth().currentUser?.email else { return }
                guard var name = Auth.auth().currentUser?.email else { return }
                name.removeLast(10)
                let bio = "よろしくおねがいします。"
                let iconUrl = ""
                let docData = ["email": email,"name": name,"createdAt": Timestamp(),"bio": bio,"iconUrl": iconUrl] as [String : Any]
                let userRef = Firestore.firestore().collection("users").document(uid)
                userRef.setData(docData) { (err) in
                    if let err = err {
                        print("ユーザー情報の保存に失敗しました。\(err)")
                        HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                        return
                    }
                    print("ユーザー情報の保存に成功しました。")
                    
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
                                self.presentToTabBarController()
                            }
                        }
                    }
                }
            }
        }
    }
    
    @objc func showKeyboard(notification: Notification){
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        let loginButtonMaxY = loginButton.frame.maxY
        let distance = loginButtonMaxY - keyboardMinY + 20
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
    
    private func dateFormatterForCreatedAt(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.timeZone = TimeZone(identifier:  "Asia/Tokyo")
        formatter.dateFormat = "yyyy年MM月dd日 HH時mm分ss秒SSS"
        return formatter.string(from: date)
    }
}

extension LoginViewController: UITextFieldDelegate{
    func textFieldDidChangeSelection(_ textField: UITextField) {
        let emailIsEmpty = emailTextField.text?.isEmpty ?? true
        let passwordIsEmpty = passwordTextField.text?.isEmpty ?? true
        if emailIsEmpty || passwordIsEmpty {
            loginButton.isEnabled = false
            loginButton.backgroundColor = UIColor.rgb(red: 150, green: 150, blue: 150)
        } else {
            loginButton.isEnabled = true
            loginButton.backgroundColor = UIColor.rgb(red: 0, green: 117, blue: 227)
        }
    }
}

