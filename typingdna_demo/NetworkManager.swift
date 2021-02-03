//
//  NetworkManager.swift
//  typingdna_demo
//
//  Created by Antonio Hung on 1/20/21.
//

import Foundation
import CryptoKit

class NetworkManager {	
	private let base_url = "https://api.typingdna.com"
	var api_key = "xx" // TypingDNA API Key
	var api_secret = "xx" // TypingDNA API Secret
	
	func save_pattern(username:String, typing_pattern:String, completionHandler:@escaping (_ result:[String: Any]) -> Void) {
			
			let hashed_user_id = MD5(string: username)
			let serviceUrl = URL(string: base_url+"/auto/"+hashed_user_id)

			let parameterDictionary = ["tp" : typing_pattern]
			   var request = URLRequest(url: serviceUrl!)
			   request.httpMethod = "POST"
			   request.setValue("Application/json", forHTTPHeaderField: "Content-Type")
				let authString = encode_auth()
				request.setValue(authString, forHTTPHeaderField: "Authorization")
			   guard let httpBody = try? JSONSerialization.data(withJSONObject: parameterDictionary, options: []) else {
				   return
			   }
			   request.httpBody = httpBody
			   
			   let session = URLSession.shared
			   session.dataTask(with: request) { (data, response, error) in
				   if let data = data {
					   do {
						let json = try JSONSerialization.jsonObject(with: data, options: [])
						completionHandler(json as! [String : Any])
					   } catch {
						   print(error)
					   }
				   }
			   }.resume()
		}
	
	func remove_user(username:String, completionHandler:@escaping (_ result:[String: Any]) -> Void) {
		
		let hashed_user_id = MD5(string: username)
		let serviceUrl = URL(string: base_url+"/user/"+hashed_user_id)

		   var request = URLRequest(url: serviceUrl!)
		   request.httpMethod = "DELETE"
		   request.setValue("Application/json", forHTTPHeaderField: "Content-Type")

			let authString = encode_auth()
			request.setValue(authString, forHTTPHeaderField: "Authorization")

		   
		   let session = URLSession.shared
		   session.dataTask(with: request) { (data, response, error) in
//			   if let response = response {
//				   print(response)
//			   }
			   if let data = data {
				   do {
					   let json = try JSONSerialization.jsonObject(with: data, options: [])
						completionHandler(json as! [String : Any])
				   } catch {
					   print(error)
				   }
			   }
		   }.resume()
	}

	func check_user(username:String, completionHandler:@escaping (_ result:[String: Any]) -> Void) {
		
		let hashed_user_id = MD5(string: username)
		let serviceUrl = URL(string: base_url+"/user/"+hashed_user_id + "?type=1")

		   var request = URLRequest(url: serviceUrl!)
		   request.httpMethod = "GET"
		   request.setValue("Application/json", forHTTPHeaderField: "Content-Type")

			let authString = encode_auth()
			request.setValue(authString, forHTTPHeaderField: "Authorization")
 
		   let session = URLSession.shared
		   session.dataTask(with: request) { (data, response, error) in

			   if let data = data {
				   do {
					   let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
					completionHandler(json!)
				   } catch {
					   print(error)
				   }
			   }
		   }.resume()
	}
	
	private func encode_auth() -> String {
		let userPasswordString = "\(api_key):\(api_secret)"
		let utf8str = userPasswordString.data(using: .utf8)
		let base64Encoded = utf8str?.base64EncodedString(options: Data.Base64EncodingOptions(rawValue: 0))
		let authString = "Basic \(base64Encoded!)"
		return authString
	}
	
	private func MD5(string: String) -> String {
		let digest = Insecure.MD5.hash(data: string.data(using: .utf8) ?? Data())

		  return digest.map {
			  String(format: "%02hhx", $0)
		  }.joined()
		}
}
