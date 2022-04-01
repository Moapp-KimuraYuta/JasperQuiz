//
//  QuizViewController.swift
//  JasperQuiz
//
//  Created by 木村祐太 on 2022/02/17.
//

import UIKit

class QuizViewController: UIViewController {
    @IBOutlet weak var quizNumberLabel: UILabel!
    @IBOutlet weak var quizTextView: UITextView!
    @IBOutlet weak var answerButton1: UIButton!
    @IBOutlet weak var answerButton2: UIButton!
    @IBOutlet weak var answerButton3: UIButton!
    @IBOutlet weak var answerButton4: UIButton!
    
    var csvArray: [String] = []
    var quizArray: [String] = []
    var quizCount = 0
    var correctCount = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        
        csvArray = loadCSV(filename: "JasperQuiz")

        quizArray = csvArray[quizCount].components(separatedBy: ",")
        
        quizNumberLabel.text = "第\(quizCount + 1)問"
        quizTextView.text = quizArray[0]
        answerButton1.setTitle(quizArray[2], for: .normal)
        answerButton2.setTitle(quizArray[3], for: .normal)
        answerButton3.setTitle(quizArray[4], for: .normal)
        answerButton4.setTitle(quizArray[5], for: .normal)
        
        // Do any additional setup after loading the view.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let scoreVC = segue.destination as! ScoreViewController
        scoreVC.correct = correctCount
        if csvArray.count == correctCount{
            scoreVC.allCorrecrTF = true
        }
    }
    
    @IBAction func btnAction(sender: UIButton){
        if sender.tag == Int(quizArray[1]){
            correctCount += 1
        }else{
        }
        nextQuiz()
    }
    
    func nextQuiz(){
        quizCount += 1
        
        if quizCount < csvArray.count {
            quizArray = csvArray[quizCount].components(separatedBy: ",")
            quizNumberLabel.text = "第\(quizCount + 1)問"
            quizTextView.text = quizArray[0]
            answerButton1.setTitle(quizArray[2], for: .normal)
            answerButton2.setTitle(quizArray[3], for: .normal)
            answerButton3.setTitle(quizArray[4], for: .normal)
            answerButton4.setTitle(quizArray[5], for: .normal)
        }else{
            performSegue(withIdentifier: "toScoreVC", sender: nil)
        }
    }
    
    func loadCSV(filename: String) -> [String] {
        let csvBundle = Bundle.main.path(forResource: filename, ofType: "csv")!
        do{
            let csvData = try String(contentsOfFile: csvBundle,encoding: String.Encoding.utf8)
            let lineChange = csvData.replacingOccurrences(of: "\r", with: "\n")
            csvArray = lineChange.components(separatedBy: "\n")
            csvArray.removeLast()
        } catch {
            print("エラー")
        }
        return csvArray
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
