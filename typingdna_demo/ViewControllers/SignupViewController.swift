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
	var last_username:String?
	var last_password:String?
}

class SignupViewController: UIViewController {

	@IBOutlet weak var user_txt_field: UITextField!
	@IBOutlet weak var submit_btn: UIButton!
	@IBOutlet weak var password_txt_field: UITextField!
	
	var networkManager = NetworkManager();
	var user = User()
	
    override func viewDidLoad() {
        super.viewDidLoad()
		
		self.submit_btn.setTitle("Signup", for: .normal)

		TypingDNARecorderMobile.addTarget(user_txt_field)
		TypingDNARecorderMobile.addTarget(password_txt_field)
    }
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		self.submit_btn.setTitle("Signup", for: .normal)
	}
    
	@IBAction func deleteUser(_ sender: Any) {
		//Remove the username / pattern from service
		//This useful if you need to reset the typing pattern for a given user
		//Allows the user to enter a username to delete
		self.presentAlertTextField(title: "Enter the username to remove", placeholder:"Username to remove")
		
	}
	
	@IBAction func signupButtonTapped(_ sender: Any) {
	
		guard let username = user_txt_field.text, username.count > 6 else {
			presentAlert(title: "Username must be longer than 6 characters", message: "")
			return
		}
		guard let password = password_txt_field.text, password.count > 0 else {
			presentAlert(title: "Password must not be empty", message: "")
			return
		}

		//For the best accuracy in the typing pattern, the username and password text must very close(80%) to the previosuly entered credentials,
		//or be the same.
		//For this application, we compare the previously entered credentials, and verify that the strings are the same for both username and password

		if user.last_username != nil && user.last_password != nil {
			if username != user.last_username || password != user.last_password {
				presentAlert(title: "Credentials must identical to the previously entered credentials ", message: "")
				return
			}
		}

		//This is what is used to store the user's previous entered credentials
		user.last_username = username
		user.last_password = password

		let typing_pattern = TypingDNARecorderMobile.getTypingPattern(1, 0, "", 0, nil);
		networkManager.save_pattern(username: username, typing_pattern: typing_pattern) { (json) in
			//Save the response from the /auto endpoint into the User Object.
			self.user.pattern_response = json

			//adding delay since free plan only allows for 1 api call per second
			DispatchQueue.main.asyncAfter(deadline: .now() + 1) {

				self.networkManager.check_user(username:username) { (json) in
					//Save the response from the /check endpoint into the User Object.
					self.user.check_response = json

					guard let check_response = self.user.check_response, let pattern_response = self.user.pattern_response else {
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
								// When the user tries to authenticate, show the current number of attempts.
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
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: message, preferredStyle: UIAlertController.Style.alert)
			alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
				//Clear text fields
				self.user_txt_field.text = "";
				self.password_txt_field.text = ""
				//reset recorder in order to prevent sending duplicate typing pattern
				TypingDNARecorderMobile.reset(true);
			}))
			self.present(alert, animated: true, completion: nil)
		}
	}
	
	func presentAlertTextField(title:String, placeholder:String) {
		DispatchQueue.main.async {
			let alert = UIAlertController(title: title, message: nil, preferredStyle: UIAlertController.Style.alert)
			alert.addTextField { textField in
				textField.placeholder = placeholder
			}
			let confirmAction = UIAlertAction(title: "OK", style: .default) { [weak alert] _ in
				guard let alert = alert, let textField = alert.textFields?.first else { return }
				
				self.networkManager.remove_user(username: textField.text!) { (json) in
					print("remove user",json)
					self.presentAlert(title: "User Removed", message: "")
				}
			}
			alert.addAction(confirmAction)
			self.present(alert, animated: true, completion: nil)
		}
	}
}
