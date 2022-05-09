//
//  ScoreViewController.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/02/18.
//

import UIKit
import Firebase
import FirebaseAuth
import FirebaseFirestore
import FirebaseStorage
import FirebaseCore
import PKHUD

class ScoreViewController: UIViewController {
    
    @IBOutlet weak var scoreLabel: UILabel!
    @IBOutlet weak var fanLevelLabel: UILabel!
    @IBOutlet weak var goodScoreImage: UIImageView!
    var correct = 0
    var allCorrecrTF = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        goodScoreImage.isHidden = true
        scoreLabel.text = "\(correct)問正解！"
        if allCorrecrTF == true {
            scoreLabel.text = "全問正解！！！"
            fanLevelLabel.text = "あなたは立派なアンチです！"
            goodScoreImage.isHidden = false
        }else{
            fanLevelLabel.text = ""
        }
    }
    
    @IBAction func scoreSaveButton(_ sender: Any) {
        saveScore()
    }

    @IBAction func toTopButtonAction(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
    
    private func saveScore() {
        HUD.show(.progress, onView: self.view)
        guard let uid = Auth.auth().currentUser?.uid else { return }
        let score = self.correct
        let time = Timestamp()
        let docData = ["uid": uid,"createdAt": time,"score":score] as [String : Any]
        let userRef = Firestore.firestore().collection("scores").document()
        userRef.setData(docData) { (err) in
            if let err = err {
                print("スコア情報の保存に失敗しました。\(err)")
                HUD.hide{ (_) in HUD.flash(.error, delay: 1)}
                return
            }
            print("スコア情報の保存に成功しました。")
            HUD.hide{ (_) in
                HUD.flash(.success,onView: self.view,delay: 1) { (_) in
                    self.presentingViewController?.presentingViewController?.dismiss(animated: true)
                }
            }
        }
    }
}
/*
 // MARK: - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
 // Get the new view controller using segue.destination.
 // Pass the selected object to the new view controller.
 }
 */


