//
//  NewMessageTableViewController.swift
//  FireChatApp
//
//  Created by DesmondWong on 26/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import UIKit
import Firebase

class NewMessageTableViewController: UITableViewController
{
    let cellId = "cellId"
    var users = [User]()
    var messageViewController: LandingViewController?

    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.mainBlue()
        navigationController?.navigationBar.barStyle = .black
        
        let image = UIImage(named: "baseline_close_black_24pt")
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleClose))
        navigationItem.leftBarButtonItem?.tintColor = .lightGray
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.separatorStyle = .none
        tableView.backgroundColor = UIColor.mainBlue()
        
        fetchUser()
    }

    func fetchUser()
    {
        Database.database().reference().child("Users").observe(.childAdded, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]
            {
                let user = User(dictionary: dictionary)
                user.Id = snapshot.key
                self.users.append(user)
                
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
            }
            print (snapshot)
            
        }, withCancel: nil)
    }
    
    @objc func handleClose()
    {
        dismiss(animated: true, completion: nil)
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        cell.backgroundColor = UIColor.mainBlue()
        
        let bgColor = UIView()
        bgColor.backgroundColor = UIColor.darkGray
        cell.selectedBackgroundView = bgColor
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        //let cell = UITableViewCell(style: .subtitle, reuseIdentifier: cellId)
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let user = users[indexPath.row]
        
        cell.textLabel?.text = user.Username
        cell.detailTextLabel?.text = user.Email
        
        if let profileImageUrl = user.ProfileImage
        {
            //To Load Images from Firebase
            /*let url = URL(string: profileImageUrl)
             URLSession.shared.dataTask(with: url!) {(data, response, error) in
             
             if (error != nil)
             {
             print(error!)
             cell.imageView?.image = UIImage(named: "profile_image_1")
             return
             }
             else
             {
             DispatchQueue.main.async(execute: {
             //cell.imageView?.image = UIImage(data: data!)
             cell.profileImageView.image = UIImage(data: data!)
             })
             }
             }.resume()*/
            
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        dismiss(animated: true) {
            let user = self.users[indexPath.row]
            self.messageViewController?.showChatControllerForUser(user)
        }
    }
}
