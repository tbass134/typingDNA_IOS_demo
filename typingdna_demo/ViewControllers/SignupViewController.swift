//
//  SignupViewController.swift
//  typingdna_demo
//
//  Created by Antonio Hung on 1/20/21.
//

import UIKit

struct User {
	var pattern_response:[String: Any]?
	var check_response:[String: Any]?
}


class SignupViewController: UIViewController {

	@IBOutlet weak var user_id: UITextField!
	@IBOutlet weak var submit_btn: UIButton!
	@IBOutlet weak var typing_pattern: UITextField!
	@IBOutlet weak var pattern_label: UILabel!
	
	var networkManager = NetworkManager();
	var pattern_string = "This is the typing pattern"

    override func viewDidLoad() {
        super.viewDidLoad()
		self.submit_btn.setTitle("Signup", for: .normal)
		self.pattern_label.text = pattern_string

		TypingDNARecorderMobile.addTarget(typing_pattern)
    }
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.submit_btn.setTitle("Signup", for: .normal)
	}
    
	@IBAction func deleteUser(_ sender: Any) {
		//Remove the username / pattern from service
		//This useful if you need to reset the typing pattern for a given user
		//If textfield is empty, allow the user to enter a username to delete
		if user_id.text!.count == 0 {
			self.presentAlertTextField(title: "delete", message: "")
		} else {
			networkManager.remove_user(user_id: user_id.text!) { (json) in
				print("remove user",json)
				self.presentAlert(title: "User Deleted", message: "")
			}
		}
	}
	
	@IBAction func signupButtonTapped(_ sender: Any) {
	
		guard let userId = user_id.text, userId.count > 6 else {
			presentAlert(title: "Username must be longer than 6 characters", message: "")
			return
		}
		guard let password = typing_pattern.text, password.count > 6 else {
			presentAlert(title: "Password must be longer than 6 characters", message: "")
			return
		}
		
		//Save the response from both the /auto and /check API into this Struct.
		var user = User()
		
		let typingPattern = TypingDNARecorderMobile.getTypingPattern(1, 0, "", 0, typing_pattern);
		networkManager.save_pattern(user_id: userId, typing_pattern: typingPattern) { (json) in
			user.pattern_response = json
			
			//adding delay since free plan only allows for 1 api call per second
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
				
				self.networkManager.check_user(user_id:userId) { (json) in
					user.check_response = json
					
					guard let check_response = user.check_response, let pattern_response = user.pattern_response else {
						self.presentAlert(title: "Error", message: "Something went wrong, please try again")
						return
					}

					if let status =  pattern_response["status"] as? Int, status  > 200, let error_message = pattern_response["message"] as? String {
						self.presentAlert(title: "Error", message: error_message)
						return
					}
						
					if let action = pattern_response["action"] {
						if action as! String == "verify;enroll" || action as! String == "verify" {
							//Typing pattern has been authencated, login the user
							//This data is shown on the AuthencationViewController
							let data:[String:Any] = [
								"result": pattern_response["result"]  as! Int,
								"mobilecount":check_response["mobilecount"] as! Int,
								"high_confidence":pattern_response["high_confidence"] as! Int,
							]
							
							DispatchQueue.main.async {
								self.performSegue(withIdentifier: "didLogin", sender: data)
							}
							
						} else if action as! String == "enroll" {
							//Currently enrolling user..
							if let mobilecount = check_response["mobilecount"] as? Int {
								let num_enrollments_left = (3 - mobilecount)
								if num_enrollments_left == 0 {
									self.presentAlert(title: "Registration finished! Try to authenticate.", message: "You have successfully registered. Use the same email and password, in order to demo the typing biometrics authentication.")
									DispatchQueue.main.async {
										self.submit_btn.setTitle("Login", for: .normal)
									}
								} else {
									self.presentAlert(title: "Congratulations, you have enrolled a new pattern!", message: "For a successful authentication, you need at least \(num_enrollments_left) more typing patterns.")
								}
							}
						}
					}
				}
			}
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
	   let destVC : AutenticatedViewController = segue.destination as! AutenticatedViewController
		destVC.results = (sender as! [String : Any])
	}
	
	func presentAlert(title:String, message:String) {
		print("ALERT: \(title) Message: \(message)")
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
				//Clear text fields
				self.user_id.text = "";
				self.typing_pattern.text = ""
				//reset recorder in order to prevent sending duplicate typing pattern
				TypingDNARecorderMobile.reset(true);
			}))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func presentAlertTextField(title:String, message:String) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
			alert.addTextField { textField in
				textField.placeholder = "Delete Username?"
			}
			let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
				guard let alert = alert, let textField = alert.textFields?.first else { return }
				
				self.networkManager.remove_user(user_id: textField.text!) { (json) in
					print("remove user",json)
					self.presentAlert(title: "User Deleted", message: "")
				}
			}
			alert.addAction(confirmAction)
			self.present(alert, animated: true, completion: nil)
		}
	}
}
