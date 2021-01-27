//
//  AutenticatedViewController.swift
//  typingdna_demo
//
//  Created by Antonio Hung on 1/21/21.
//

import UIKit

class AutenticatedViewController: UIViewController {

	@IBOutlet weak var ConfidenceText: UITextView!
	@IBOutlet weak var resultText: UITextView!
	@IBOutlet weak var numEnrollmentsText: UITextView!
	@IBOutlet weak var deviceText: UITextView!
	
	var networkManager = NetworkManager()
	var pattern_json:[String: Any]?
	var results:[String: Any]?
	
	override func viewDidLoad() {
        super.viewDidLoad()
		
		print("results",results!)
		
		resultText.text = "TypingDNA result: \(String(describing: results!["result"]!))"
		ConfidenceText.text = "Confidence: \(String(describing: results!["high_confidence"]!))"
		numEnrollmentsText.text = "Total Number of Enrolments: \(String(describing: results!["mobilecount"]!))"
		
//		networkManager.ch
        // Do any additional setup after loading the view.
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
