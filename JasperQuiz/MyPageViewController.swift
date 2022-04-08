//
//  MyPageViewController.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/03/18.
//

import Foundation
import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore
import PKHUD

class MyPageViewController: UIViewController, UIImagePickerControllerDelegate & UINavigationControllerDelegate{
    
    var user: User?
    
    private let maxBioLength = 20
    private let storage = Storage.storage().reference()
    @IBOutlet weak var iconImage: UIImageView!
    @IBOutlet weak var changeImageButton: UIButton!
    @IBOutlet weak var bioTextField: UITextField!
    @IBOutlet weak var bioChangeButton: UIButton!
    @IBAction func tappedBioChangeButton(_ sender: Any) {
        updateProfile()
    }
    @IBAction func tappedChangeImageButton(_ sender: Any) {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        picker.allowsEditing = true
        present(picker, animated: true)
    }
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        picker.dismiss(animated: true,completion: nil)
        HUD.show(.progress, onView: self.view)
        guard let img = info[UIImagePickerController.InfoKey.editedImage] as? UIImage else { return }
        guard let imgData = img.pngData() else { return }
        
        guard let userId = Auth.auth().currentUser?.uid else { fatalError() }
        storage.child("images/\(userId).png").putData(imgData,
                                                      metadata: nil,
                                                      completion: { _, error in
            guard error == nil else {
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                return
            }
            self.storage.child("images/\(userId).png").downloadURL(completion: {url, error in
                guard let url = url, error == nil else{
                    return
                }
                let urlString = url.absoluteString
                DispatchQueue.main.async {
                    self.iconImage.image = img
                }
                guard let userId = Auth.auth().currentUser?.uid else { fatalError() }
                let ref = Firestore.firestore().collection("users").document(userId)
                ref.updateData([
                    "iconUrl": urlString
                ]) { err in
                    if let err = err {
                        print("情報の更新に失敗しました: \(err)")
                        HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                    } else {
                        print("情報の更新ができました！")
                        HUD.hide{ (_) in HUD.flash(.success, delay: 1)}
                    }
                }
            })
        })
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController){
        picker.dismiss(animated: true,completion: nil)
    }
    
    
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var emailLabel: UILabel!
    @IBOutlet weak var createdAtLabel: UILabel!
    @IBOutlet weak var lastScoreLabel: UILabel!
    @IBOutlet weak var logoutButton: UIButton!
    @IBAction func tappedLogoutButton(_ sender: Any) {
        handleLogout()
    }
    
    private func handleLogout() {
        do{
            try Auth.auth().signOut()
            UserDefaults.standard.removeObject(forKey: "email")
            UserDefaults.standard.removeObject(forKey: "password")
            presentToLoginViewController()
        } catch (let err) {
            print("ログアウトに失敗しました。:\(err)")
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        bioTextField.delegate = self
        logoutButton.layer.cornerRadius = 10
        bioChangeButton.layer.cornerRadius = 10
        iconImage.contentMode = .scaleAspectFit
        
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let userRef = Firestore.firestore().collection("users").document(uid)
        userRef.getDocument{ ( snapshot, err ) in
            if let err = err {
                print("ユーザー情報の取得に失敗しました。\(err)")
            }
            guard let data = snapshot?.data() else { return }
            
            let user = User.init(dic: data)
            
            self.nameLabel.text = "name: " + user.name
            self.emailLabel.text = "email: " + user.email
            self.lastScoreLabel.text = "lastScore: " + String(user.lastScore) + "点"
            
            let dateString = self.dateFormatterForCreatedAt(date: user.createdAt.dateValue())
            self.createdAtLabel.text = "createdAt: " + dateString
            
            self.bioTextField.text = user.bio
            let urlString = user.iconUrl
            guard let url = URL(string: urlString) else { return }
            
            let task = URLSession.shared.dataTask(with: url, completionHandler: {data, _, error in
                guard let data = data , error == nil else {
                    return
                }
                DispatchQueue.main.async {
                    let image = UIImage(data: data)
                    self.iconImage.image = image
                }
            })
            task.resume()
            NotificationCenter.default.addObserver(self, selector: #selector(self.showKeyboard), name: UIResponder.keyboardWillShowNotification, object: nil)
            NotificationCenter.default.addObserver(self, selector: #selector(self.hideKeyboard), name: UIResponder.keyboardWillHideNotification, object: nil)
            
        }
    }
    
    private func updateProfile() {
        HUD.show(.progress, onView: self.view)
        guard let userId = Auth.auth().currentUser?.uid else { fatalError() }
        let ref = Firestore.firestore().collection("users").document(userId)
        
        ref.updateData([
            "bio": bioTextField.text ?? ""
        ]) { err in
            if let err = err {
                print("情報の更新に失敗しました: \(err)")
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
            } else {
                print("情報の更新ができました！")
                HUD.hide{ (_) in HUD.flash(.success, delay: 1)}
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
    
    private func dateFormatterForCreatedAt(date:Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        formatter.timeStyle = .none
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
    @objc func showKeyboard(notification: Notification){
        let keyboardFrame = (notification.userInfo![UIResponder.keyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        guard let keyboardMinY = keyboardFrame?.minY else { return }
        let regiserButtonMaxY = bioChangeButton.frame.maxY
        
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
    func textFieldDidChangeSelection(_ textField: UITextField) {
        guard let bio = bioTextField.text else { return }
        
        if bio.count > maxBioLength {
            bioChangeButton.isEnabled = false
            bioChangeButton.backgroundColor = UIColor.rgb(red: 150, green: 150, blue: 150)
        } else {
            bioChangeButton.isEnabled = true
            bioChangeButton.backgroundColor = UIColor.rgb(red: 0, green: 117, blue: 227)
        }
    }
}
extension MyPageViewController: UITextFieldDelegate {
}
