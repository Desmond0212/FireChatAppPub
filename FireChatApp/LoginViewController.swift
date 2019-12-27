//
//  LoginViewController.swift
//  FireChatApp
//
//  Created by DesmondWong on 26/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import UIKit
import Firebase

extension UIViewController
{
    func HideKeyboard()
    {
        let Tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(DismissKeyboard))
        view.addGestureRecognizer(Tap)
    }
    
    @objc func DismissKeyboard()
    {
        view.endEditing(true)
        view.frame.origin.y = 0
    }
}

class LoginViewController: UIViewController
{
    var messageViewController: LandingViewController?
    
    let logoImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = #imageLiteral(resourceName: "profile_image_1")
        iv.layer.cornerRadius = 24
        iv.layer.masksToBounds = true
        iv.contentMode = .scaleAspectFill
        iv.translatesAutoresizingMaskIntoConstraints = false
        
        return iv
    }()
    
    lazy var emailContainerView: UIView = {
        let view = UIView()
        return view.textContainerView(view: view, #imageLiteral(resourceName: "baseline_mail_outline_white_24pt_2x"), emailTextField)
    }()
    
    lazy var passwordContainerView: UIView = {
        let view = UIView()
        return view.textContainerView(view: view, #imageLiteral(resourceName: "baseline_lock_white_36pt_3x"), passwordTextField)
    }()
    
    lazy var emailTextField: UITextField = {
        let tf = UITextField()
        return tf.textField(withPlaceHolder: "Email", isSecureTextEntry: false)
    }()
    
    lazy var passwordTextField: UITextField = {
        let tf = UITextField()
        return tf.textField(withPlaceHolder: "Password", isSecureTextEntry: true)
    }()
    
    let loginButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("LOG IN", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18)
        button.setTitleColor(UIColor.mainBlue(), for: .normal)
        button.backgroundColor = .white
        button.addTarget(self, action: #selector(handleLogin), for: .touchUpInside)
        button.layer.cornerRadius = 5
        return button
    }()
    
    let dontHaveAccountButton: UIButton = {
        let button = UIButton(type: .system)
        let attributedTitle = NSMutableAttributedString(string: "Don't have an account?  ", attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.white])
        attributedTitle.append(NSAttributedString(string: "Sign Up", attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 16), NSAttributedString.Key.foregroundColor: UIColor.white]))
        button.setAttributedTitle(attributedTitle, for: .normal)
        button.addTarget(self, action: #selector(handleShowSignUp), for: .touchUpInside)
        return button
    }()
    
    override func viewWillAppear(_ animated: Bool)
    {
        super.viewWillAppear(animated)
        self.setNeedsStatusBarAppearanceUpdate()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle
    {
        return .lightContent
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        configureViewComponents()
        
        //To dismiss keyboard.
        self.HideKeyboard()
        
        //Listener for keyboard events
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillShow/*UIResponder.keyboardWillShowNotification*/, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillHide/*UIResponder.keyboardWillHideNotification*/, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChange(notification:)), name: NSNotification.Name.UIKeyboardWillChangeFrame/*UIResponder.keyboardWillChangeFrameNotification*/, object: nil)
    }
    
    //stop listener for keyboard show/hide events.
    deinit
    {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillShow/*UIResponder.keyboardWillShowNotification*/, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillHide/*UIResponder.keyboardWillHideNotification*/, object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIKeyboardWillChangeFrame/*UIResponder.keyboardWillChangeFrameNotification*/, object: nil)
    }
    
    @objc func keyboardWillChange(notification: Notification)
    {
        print("Keyboard will show: \(notification.name.rawValue)")
        
        view.frame.origin.y = -50
    }
    
    @objc func handleLogin()
    {
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        
        logUserIn(withEmail: email, password: password)
    }
    
    @objc func handleShowSignUp()
    {
        if (emailTextField.text != nil)
        {
            emailTextField.text = ""
        }
        
        if(passwordTextField.text != nil)
        {
            passwordTextField.text = ""
        }
        
        let registerController = RegistrationViewController()
        self.present(registerController, animated: true, completion: nil)
    }
    
    func logUserIn(withEmail email: String, password: String)
    {
        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
            
            if (error != nil)
            {
                print("Failed to sign user in with error: ", error!.localizedDescription)
                return
            }
            else
            {
                guard let navController = UIApplication.shared.keyWindow?.rootViewController as? UINavigationController else { return }
                guard let controller = navController.viewControllers[0] as? LandingViewController else { return }
                
                controller.fetchUserAndSetupNavBarTitle()
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    func configureViewComponents()
    {
        view.backgroundColor = UIColor.mainBlue()
        navigationController?.navigationBar.isHidden = true
        UITabBar.appearance().barTintColor = .white
        
        view.addSubview(logoImageView)
        logoImageView.anchor(top: view.topAnchor, left: nil, bottom: nil, right: nil, paddingTop: 80, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 150)
        logoImageView.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        view.addSubview(emailContainerView)
        emailContainerView.anchor(top: logoImageView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 25, paddingLeft: 32, paddingBottom: 0, paddingRight: 32, width: 0, height: 50)
        
        view.addSubview(passwordContainerView)
        passwordContainerView.anchor(top: emailContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 16, paddingLeft: 32, paddingBottom: 0, paddingRight: 32, width: 0, height: 50)
        
        view.addSubview(loginButton)
        loginButton.anchor(top: passwordContainerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 24, paddingLeft: 32, paddingBottom: 0, paddingRight: 32, width: 0, height: 50)
        
        //        view.addSubview(dividerView)
        //        dividerView.anchor(top: loginButton.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 24, paddingLeft: 32, paddingBottom: 0, paddingRight: 32, width: 0, height: 50)
        //
        //        view.addSubview(googleLoginButton)
        //        googleLoginButton.anchor(top: dividerView.bottomAnchor, left: view.leftAnchor, bottom: nil, right: view.rightAnchor, paddingTop: 24, paddingLeft: 32, paddingBottom: 0, paddingRight: 32, width: 0, height: 50)
        
        view.addSubview(dontHaveAccountButton)
        dontHaveAccountButton.anchor(top: nil, left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingTop: 0, paddingLeft: 32, paddingBottom: 12, paddingRight: 32, width: 0, height: 50)
    }
}
