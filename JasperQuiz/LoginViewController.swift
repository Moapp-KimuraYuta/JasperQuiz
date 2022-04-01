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
import PKHUD

class LoginViewController: UIViewController {
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var dontHaveAccountButton: UIButton!
    @IBAction func tappedDontHaveAccountButton(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
    @IBAction func tappedLoginButton(_ sender: Any) {
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
                        self.presentToMyPageViewController(user: user)
                    }
                }
            }
        }
    }
    private func presentToMyPageViewController(user: User) {
        let storyBoard = UIStoryboard(name: "MyPage", bundle: nil)
        let myPageViewController = storyBoard.instantiateViewController(identifier: "MyPageViewController") as! MyPageViewController
        myPageViewController.user = user
        navigationController?.pushViewController(myPageViewController, animated: true)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.hidesBackButton = true
        loginButton.layer.cornerRadius = 10
        loginButton.isEnabled = false
        loginButton.backgroundColor = UIColor.rgb(red: 150, green: 150, blue: 150)
        
        emailTextField.delegate = self
        passwordTextField.delegate = self
        
        
        NotificationCenter.default.addObserver(self, selector: #selector(showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
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
