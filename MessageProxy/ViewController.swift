//
//  ViewController.swift
//  MessageProxy
//
//  Created by Salman Husain on 3/1/17.
//  Copyright © 2017 Salman Husain. All rights reserved.
//

import Cocoa
import GRDB
import GCDWebServer



class ViewController: NSViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
		setupWebserver()

    }


    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
	
	func setupWebserver() {
		do {
			let connector = try DatabaseConstructor(datebaseLocation: "/Users/Salman/Library/Messages/chat.db");
			
            //Set log level warning to stop console spam
            GCDWebServer.setLogLevel(3)
            
            //Create our server
			let apiServer = GCDWebServer()
            apiServer?.addDefaultHandler(forMethod: "GET", request: GCDWebServerRequest.self, processBlock: {request in
				return GCDWebServerDataResponse(html:"Access Denied")
				
			})
			
			apiServer?.addHandler(forMethod: "GET", path: "/conversations", request: GCDWebServerRequest.self, processBlock: {
				request in
				weak var weakConnector = connector;
				
				return GCDWebServerDataResponse(html:weakConnector?.getJSONConversations())
			})
			
			//Setup our send post.
			//Paramaters
			//Your post data needs the following values: participants and message. Each are strings. Participants is a comma seperate string of the recipients as you'd type them into the new message field in Message.app
			//curl http://127.0.0.1:8735/send  -XPOST -d "participants=imessage,3033744343&message=It's me from the command line"
			apiServer?.addHandler(forMethod: "POST", path: "/send", request: GCDWebServerURLEncodedFormRequest.self, processBlock: {
				request in
				weak var weakConnector = connector;
                
                //Grab our post data parser as a form
				let formRequest = request as! GCDWebServerURLEncodedFormRequest
				if (formRequest.arguments != nil) {
					let participiants = formRequest.arguments["participants"] as? String
					let message = formRequest.arguments["message"] as? String
                    //Do we have the correct paramaters? (are they set)
                    if (participiants != nil && message != nil) {
                        //Yes! Ask our controller to send a message
                        weakConnector?.sendMessage(toRecipients: participiants!, withMessage: message!)
                        return GCDWebServerDataResponse(html:"OK: \(participiants!) :: \(message!)")
                    }

				}
                //We couldn't find anyway else to return, give up
				return GCDWebServerDataResponse(html:"Invalid post data!")
			})
            
            //Setup our get messages post.
            //Paramaters
            //Your post data needs the following values: conversationID
            //curl http://127.0.0.1:8735/messages -XPOST -d "conversationID=7"
            apiServer?.addHandler(forMethod: "POST", path: "/messages", request: GCDWebServerURLEncodedFormRequest.self, processBlock: {
                request in
                weak var weakConnector = connector;
                
                //Grab our post data parser as a form
                let formRequest = request as! GCDWebServerURLEncodedFormRequest
                if (formRequest.arguments != nil) {
                    let conversationID = formRequest.arguments["conversationID"] as? String
                    //Do we have the correct paramaters? (are they set)
                    if (conversationID != nil) {
                        //Yes! Get our data from the controller
                        return GCDWebServerDataResponse(html:weakConnector?.getJSONMessages(forChatID: Int(conversationID!)!))
                    }
                    
                }
                //We couldn't find anyway else to return, give up
                return GCDWebServerDataResponse(html:"Invalid post data!")
            })
			
			apiServer?.start(withPort: 8735, bonjourName: "iMessage Proxy")
            if apiServer?.isRunning == true {
                print("Ready at \(apiServer!.serverURL!)")
            }else {
                print("Couldn't start the webserver! Failing permenantly")
            }
            
            
			
			
		} catch  {
			print("Database error!")
		}
		
		
	}
    
    
}
