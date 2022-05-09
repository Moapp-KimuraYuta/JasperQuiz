//
//  TabBarController.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/03/18.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore
import PKHUD

class TabBarController: UITabBarController {
    
    var user: User?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedIndex = 0
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        confirmLoggedInUser()
    }
    
    private func confirmLoggedInUser(){
        if Auth.auth().currentUser == nil{
            presentToLoginViewController()
        } else{
            guard let email = UserDefaults.standard.string(forKey: "email")  else { return }
            guard let password = UserDefaults.standard.string(forKey: "password") else { return }
            Auth.auth().signIn(withEmail: email, password: password) { (res, err) in
                if let err = err {
                    print("ログイン情報の取得に失敗しました。\(err)",err)
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
                    }
                    guard let data = snapshot?.data() else { return }
                    let user = User.init(dic: data)
                    print("ユーザー情報の取得ができました。\(user.name)")
                }
            }
        }
    }
    private func presentToLoginViewController() {
        let storyBoard = UIStoryboard(name: "Login", bundle: nil)
        let loginViewController = storyBoard.instantiateViewController(identifier: "LoginViewController") as! LoginViewController
        let navController = UINavigationController(rootViewController: loginViewController)
        navController.modalPresentationStyle = .fullScreen
        self.present(navController, animated:true, completion:nil)
    }
    
    /*
     // MARK: - Navigation
     
     // In a storyboard-based application, you will often want to do a little preparation before navigation
     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
     // Get the new view controller using segue.destination.
     // Pass the selected object to the new view controller.
     }
     */
    
}
