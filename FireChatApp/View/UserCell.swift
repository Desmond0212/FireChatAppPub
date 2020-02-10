//
//  UserCell.swift
//  FireChatApp
//
//  Created by DesmondWong on 26/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import Foundation
import UIKit
import Firebase

class UserCell: UITableViewCell
{
    var message: Message?
    {
        didSet
        {
            setupNameAndProfileImage()
            
            if (message?.text != nil)
            {
                detailTextLabel?.text = message?.text
                detailTextLabel?.font = UIFont.systemFont(ofSize: 14)
            }
            else if (message?.imageUrl != nil && message?.videoUrl != nil)
            {
                detailTextLabel?.font = UIFont.italicSystemFont(ofSize: 14)
                detailTextLabel?.text = "This is an Video..."
            }
            else if (message?.imageUrl != nil)
            {
                detailTextLabel?.font = UIFont.italicSystemFont(ofSize: 14)
                detailTextLabel?.text = "This is a Image..."
            }
            
            
            //Date and Time Formatter
            /*if let dateTime = message?.timestamp?.doubleValue {
             let timestampDate = NSDate(timeIntervalSince1970: dateTime)
             timeLabel.text = timestampDate.description
             }*/
            
            //Time Formatter
            if let time = message?.timestamp?.doubleValue {
                let timestampDate = NSDate(timeIntervalSince1970: time)
                let timeFormatter = DateFormatter()
                timeFormatter.dateFormat = "hh:mm:ss a"
                timeLabel.text = timeFormatter.string(from: timestampDate as Date)
            }
        }
    }
    
    private func setupNameAndProfileImage()
    {
        /*let chatPartnerId: String?
         
         if (message?.fromId == Auth.auth().currentUser?.uid)
         {
         chatPartnerId = message?.toId
         }
         else
         {
         chatPartnerId = message?.fromId
         }*/
        
        if let id = message?.chatPartnerId()
        {
            let ref = Database.database().reference().child("Users").child(id)
            
            ref.observe(.value, with: {(snapshot) in
                
                print(snapshot)
                
                if let dictionary = snapshot.value as? [String: AnyObject]
                {
                    self.textLabel?.text = dictionary["Username"] as? String
                    
                    if let profileImageUrl = dictionary["ProfileImageUrl"] as? String {
                        self.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                    }
                }
                
            }, withCancel: nil)
        }
    }
    
    override func layoutSubviews()
    {
        super.layoutSubviews()
        
        textLabel?.frame = CGRect(x: 70, y: textLabel!.frame.origin.y - 4, width: 200, height: textLabel!.frame.height)
        detailTextLabel?.frame = CGRect(x: 70, y: detailTextLabel!.frame.origin.y + 4, width: 200/*detailTextLabel!.frame.width*/, height: detailTextLabel!.frame.height)
        
        textLabel?.textColor = .white
        textLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        detailTextLabel?.textColor = .white
    }
    
    let timeLabel: UILabel = {
        let label = UILabel()
        //label.text = "HH:MM:SS"
        label.textColor = UIColor.darkGray
        label.font = UIFont.systemFont(ofSize: 13)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = UIColor.lightGray
        
        return label
    }()
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(named: "profile_image_1")
        imageView.layer.cornerRadius = 24
        imageView.layer.masksToBounds = true
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        
        return imageView
    }()
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?)
    {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        
        //ImageView
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 10).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 50).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        addSubview(timeLabel)
        
        //Time
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 18).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: textLabel!.heightAnchor).isActive = true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
