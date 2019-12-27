//
//  HomeController.swift
//  FireChatApp
//
//  Created by DesmondWong on 27/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import UIKit
import Firebase

class HomeController: UIViewController
{
    var welcomeLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 28)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alpha = 0
        return label
    }()
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        authenticateUserAndConfigureView()
    }
    
    func authenticateUserAndConfigureView()
    {
        if Auth.auth().currentUser == nil
        {
            DispatchQueue.main.async {
                let navController = UINavigationController(rootViewController: LoginViewController())
                navController.navigationBar.barStyle = .black
                self.present(navController, animated: true, completion: nil)
            }
        }
        else
        {
            configureViewComponents()
            loadUserData()
        }
    }
    
    @objc func handleSignOut()
    {
        let alertController = UIAlertController(title: nil, message: "Are you sure you want to sign out?", preferredStyle: .actionSheet)
        alertController.addAction(UIAlertAction(title: "Sign Out", style: .destructive, handler: { (_) in
            self.signOut()
        }))
        alertController.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alertController, animated: true, completion: nil)
    }
    
    func loadUserData()
    {
        guard let uid = Auth.auth().currentUser?.uid else { return }
        Database.database().reference().child("Users").child(uid).child("Username").observeSingleEvent(of: .value) { (snapshot) in
            guard let username = snapshot.value as? String else { return }
            self.welcomeLabel.text = "Welcome, \(username)"
            
            print("Desmond Debug: Welcome LoadUSerData")
            
            UIView.animate(withDuration: 0.5, animations:
                {
                    self.welcomeLabel.alpha = 1
            })
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
    
    func configureViewComponents()
    {
        view.backgroundColor = UIColor.mainBlue()
        
        navigationItem.title = "Firebase Login"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(image: #imageLiteral(resourceName: "baseline_arrow_back_white_24pt_1x"), style: .plain, target: self, action: #selector(handleSignOut))
        navigationItem.leftBarButtonItem?.tintColor = .white
        
        navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Logout", style: .plain, target: self, action: #selector(handleSignOut))
        navigationItem.rightBarButtonItem?.tintColor = .white
        
        
        navigationController?.navigationBar.barTintColor = UIColor.mainBlue()
        
        view.addSubview(welcomeLabel)
        welcomeLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        welcomeLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor).isActive = true
    }
}

