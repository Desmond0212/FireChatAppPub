//
//  User.swift
//  FireChatApp
//
//  Created by DesmondWong on 26/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import Foundation
import UIKit

class User: NSObject
{
    var Id: String?
    var Email: String?
    var Username: String?
    var ProfileImage: String?
    
    init(dictionary: [String: AnyObject])
    {
        self.Id = dictionary["Id"] as? String
        self.Email = dictionary["Email"] as? String
        self.Username = dictionary["Username"] as? String
        self.ProfileImage = dictionary["ProfileImageUrl"] as? String
    }
}
