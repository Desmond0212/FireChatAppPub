//
//  Message.swift
//  FireChatApp
//
//  Created by DesmondWong on 26/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import Foundation
import Firebase

class Message: NSObject
{
    var fromId: String?
    var toId: String?
    var text: String?
    var timestamp: NSNumber?
    
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    var videoUrl: String?
    
    init(dictionary: [String: Any])
    {
        self.fromId = dictionary["FromId"] as? String
        self.toId = dictionary["ToId"] as? String
        self.text = dictionary["Message"] as? String
        self.timestamp = dictionary["Timestamp"] as? NSNumber
        
        self.imageUrl = dictionary["ImageUrl"] as? String
        self.imageWidth = dictionary["ImageWidth"] as? NSNumber
        self.imageHeight = dictionary["ImageHeight"] as? NSNumber
        self.videoUrl = dictionary["VideoUrl"] as? String
    }
    
    func chatPartnerId() -> String?
    {
        if (fromId == Auth.auth().currentUser?.uid)
        {
            return toId
        }
        else
        {
            return fromId
        }
    }
}
