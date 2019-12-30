//
//  LandingViewController.swift
//  FireChatApp
//
//  Created by DesmondWong on 26/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import UIKit
import Firebase

class LandingViewController: UITableViewController
{
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    var timer: Timer?
    let cellId = "cellId"
    var homeController: HomeController?
    
    override func viewDidLoad()
    {
        super.viewDidLoad()

        view.backgroundColor = UIColor.mainBlue()
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(requestLogout))
        navigationItem.leftBarButtonItem?.tintColor = .lightGray
        
        let image = UIImage(named: "baseline_chat_black_24pt")
        navigationItem.rightBarButtonItem = UIBarButtonItem(image: image, style: .plain, target: self, action: #selector(handleNewMessage))
        navigationItem.rightBarButtonItem?.tintColor = .lightGray
        
        checkIfUserLoggedIn()
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        tableView.separatorStyle = .none
        tableView.allowsSelectionDuringEditing = true
    }
    
    func observeUserMessages()
    {
        guard let uid = Auth.auth().currentUser?.uid else {
            return
        }
        
        let ref = Database.database().reference().child("user-messages").child(uid)
        
        ref.observe(.childAdded, with: {(snapshot) in
            
            let userId = snapshot.key
            
            Database.database().reference().child("user-messages").child(uid).child(userId).observe(.childAdded, with: {(snapshot) in
                
                print(snapshot)
                
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId: messageId)
                
            }, withCancel: nil)
            
        }, withCancel:  nil)
        
        //Remove Chat Log after Deleted Data from Firebase Database.
        ref.observe(.childRemoved, with: {(snapshot) in
            print(snapshot.key)
            print(self.messagesDictionary)
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
        }, withCancel: nil)
    }
    
    private func attemptReloadOfTable()
    {
        self.timer?.invalidate()
        self.timer = Timer.scheduledTimer(timeInterval: 0.01, target: self, selector: #selector(self.requestReloadTable), userInfo: nil, repeats: false)
    }
    
    private func fetchMessageWithMessageId(messageId: String)
    {
        let messageReference = Database.database().reference().child("Messages").child(messageId)
        
        messageReference.observe(.value, with: {(snapshot) in
            print(snapshot)
            
            if let dictionary = snapshot.value as? [String: AnyObject]
            {
                let message = Message(dictionary: dictionary)
                self.messages.append(message)
                
                //Identify Messages by Id.
                if let chatPartnerId = message.chatPartnerId()
                {
                    self.messagesDictionary[chatPartnerId] = message
                }
                
                self.attemptReloadOfTable()
            }
            
        },withCancel: nil)
    }
    
    @objc func requestReloadTable()
    {
        self.messages = Array(self.messagesDictionary.values)
        
        //Sorted by Latest Time
        self.messages.sort(by: {(message1, message2) -> Bool in
            return (message1.timestamp?.int32Value)! > (message2.timestamp?.int32Value)!
        })
        
        DispatchQueue.main.async(execute: {
            print("TableView has been refreshed!")
            self.tableView.reloadData()
        })
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    {
        return messages.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        let message = messages[indexPath.row]
        
        cell.message = message
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath)
    {
        cell.backgroundColor = UIColor.mainBlue()
        
        let bgColor = UIView()
        bgColor.backgroundColor = UIColor.darkGray
        cell.selectedBackgroundView = bgColor
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    {
        return 80
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    {
        let message = messages[indexPath.row]
        print(message.text ?? "", message.toId ?? "", message.fromId ?? "")
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("Users").child(chatPartnerId)
        ref.observe(.value, with: {(snapshot) in
            print(snapshot)
            
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            let user = User(dictionary: dictionary)
            user.Id = chatPartnerId
            self.showChatControllerForUser(user)
            
            
        }, withCancel: nil)
        
    }
    
    //For Slide to Delete Use Case.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath)
    {
        guard let uid = Auth.auth().currentUser?.uid else
        {
            return
        }
        
        let message = self.messages[indexPath.row]
        
        if let chatPartnerId = message.chatPartnerId()
        {
            Database.database().reference().child("user-messages").child(uid).child(chatPartnerId).removeValue(completionBlock: {(error, ref) in
                
                if (error != nil)
                {
                    print("Failed to remove selected chat log.", error!)
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: chatPartnerId)
                self.attemptReloadOfTable()
                
                //1st Option to Remove the Message Log from Mobile and Firebase.
                /*self.messages.remove(at: indexPath.row)
                 self.tableView.deleteRows(at: [indexPath], with: .automatic)*/
            })
        }
    }
    
    @objc func handleNewMessage()
    {
        let newMessageController = NewMessageTableViewController()
        newMessageController.messageViewController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController, animated: true, completion: nil)
    }
    
    func checkIfUserLoggedIn()
    {
        if (Auth.auth().currentUser?.uid == nil)
        {
            perform(#selector(requestLogoutWithoutUserId), with: nil, afterDelay: 0)
        }
        else
        {
            fetchUserAndSetupNavBarTitle()
        }
    }
    
    func fetchUserAndSetupNavBarTitle()
    {
        //To Set Username to Header Bar.
        guard let uid = Auth.auth().currentUser?.uid else {
            //if uid is empty or nil
            return
        }
        
        Database.database().reference().child("Users").child(uid).observeSingleEvent(of: .value, with: { (snapshot) in
            
            if let dictionary = snapshot.value as? [String: AnyObject]
            {
                let user = User(dictionary: dictionary)
                self.setupNavBarWithUser(user: user)
            }
            print(snapshot)
            
        }, withCancel: nil)
    }
    
    func setupNavBarWithUser(user: User)
    {
        messages.removeAll()
        messagesDictionary.removeAll()
        tableView.reloadData()
        
        observeUserMessages()
        
        //self.navigationItem.title = user.Username
        let titleView = UIView()
        titleView.frame = CGRect(x: 0, y: 0, width: 100, height: 40)
        
        let containerView = UIView()
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        titleView.addSubview(containerView)
        
        let profileImageView = UIImageView()
        profileImageView.translatesAutoresizingMaskIntoConstraints = false
        profileImageView.contentMode = .scaleAspectFill
        profileImageView.layer.cornerRadius = 20
        profileImageView.clipsToBounds = true
        if let profileImageUrl = user.ProfileImage {
            
            profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        containerView.addSubview(profileImageView)
        
        profileImageView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 40).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
        let nameLabel = UILabel()
        nameLabel.text = user.Username
        nameLabel.translatesAutoresizingMaskIntoConstraints = false
        nameLabel.textColor = .white
        
        containerView.addSubview(nameLabel)
        
        nameLabel.leftAnchor.constraint(equalTo: profileImageView.rightAnchor, constant: 8).isActive = true
        nameLabel.centerYAnchor.constraint(equalTo: profileImageView.centerYAnchor).isActive = true
        nameLabel.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        nameLabel.heightAnchor.constraint(equalTo: profileImageView.heightAnchor).isActive = true
        
        containerView.centerXAnchor.constraint(equalTo: titleView.centerXAnchor).isActive = true
        containerView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor).isActive = true
        
        self.navigationItem.titleView = titleView
        
        // titleView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(showChatController)))
        titleView.isUserInteractionEnabled = true
    }
    
    @objc func showChatControllerForUser(_ user: User)
    {
        let chatLogController = ChatLogController(collectionViewLayout: UICollectionViewFlowLayout())
        chatLogController.user = user
        navigationController?.pushViewController(chatLogController, animated: true)
    }
    
    @objc func requestLogoutWithoutUserId()
    {
        do
        {
            try Auth.auth().signOut()
        }
        catch let logoutError
        {
            print (logoutError)
        }
        
        let loginViewController = LoginViewController()
        loginViewController.messageViewController = self
        self.present(loginViewController, animated: true, completion: nil)
    }
    
    @objc func requestLogout()
    {
        //var systemVersion = UIDevice.current.systemVersion
        
        //Check iOS Version to Assign Defferent Logout Request.
        if #available(iOS 12, *)
        {
            let alertController = UIAlertController(title: nil, message: "Are you sure you want to sign out?", preferredStyle: .actionSheet)
            alertController.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { (_) in
                self.signOut()
            }))
            alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
            present(alertController, animated: true, completion: nil)
        }
        else
        {
            do
            {
                try Auth.auth().signOut()
            }
            catch let logoutError
            {
                print (logoutError)
            }
            
            let loginViewController = LoginViewController()
            loginViewController.messageViewController = self
            self.present(loginViewController, animated: true, completion: nil)
        }
    }
    
    func signOut()
    {
        do
        {
            try Auth.auth().signOut()
            let navController = UINavigationController(rootViewController: LoginViewController())
            navController.navigationBar.barStyle = .black
            self.present(navController, animated: true, completion: nil)
        }
        catch let error
        {
            print("Failed to sign out with error..", error)
        }
    }
}
