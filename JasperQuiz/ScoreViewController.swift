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
    @IBAction func scoreSaveButton(_ sender: Any) {
        saveScore()
        self.presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
    
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

        // Do any additional setup after loading the view.
    }
    
    @IBAction func toTopButtonAction(_ sender: Any) {
        self.presentingViewController?.presentingViewController?.dismiss(animated: true)
    }
    
    private func saveScore() {
            HUD.show(.progress, onView: self.view)
            guard let userId = Auth.auth().currentUser?.uid else { fatalError() }
            let ref = Firestore.firestore().collection("users").document(userId)
            
            ref.updateData([
                "lastScore": self.correct
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
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
