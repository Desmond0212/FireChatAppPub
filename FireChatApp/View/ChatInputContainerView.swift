//
//  ChatInputContainerView.swift
//  FireChatApp
//
//  Created by DesmondWong on 27/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import Foundation
import UIKit

class ChatInputContainerView: UIView, UITextFieldDelegate
{
    let sendButton = UIButton(type: .system)
    
    var chatLogController: ChatLogController?
    {
        didSet
        {
            sendButton.addTarget(chatLogController, action: #selector(ChatLogController.requestSendMessage), for: .touchUpInside)
            uploadImageView.addGestureRecognizer(UITapGestureRecognizer(target: chatLogController, action: #selector(ChatLogController.handleUploadTap)))
        }
    }
    
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
//        textField.placeholder = "Enter message..."
        textField.attributedPlaceholder = NSAttributedString(string: "Enter message...", attributes: [NSAttributedStringKey.foregroundColor: UIColor.darkGray])
        textField.textColor = UIColor.white
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        
        return textField
    }()
    
    let uploadImageView: UIImageView = {
        let uploadImageView = UIImageView()
        uploadImageView.image = UIImage(named: "baseline_insert_photo_white_48pt")//(named: "upload_image_icon")
        uploadImageView.isUserInteractionEnabled = true
        uploadImageView.translatesAutoresizingMaskIntoConstraints = false
        uploadImageView.tintColor = UIColor.mainBlue()
        
        return uploadImageView
    }()
    
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        
        backgroundColor = UIColor.mainBlue()//.white
        
        addSubview(uploadImageView)
        
        uploadImageView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        uploadImageView.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        uploadImageView.widthAnchor.constraint(equalToConstant: 44).isActive = true
        uploadImageView.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        //sendButton.setTitle("Send", for: .normal)
        if let image = UIImage(named: "baseline_send_white_36pt") {
            sendButton.setImage(image, for: .normal)
        }
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.isEnabled = false
        
        addSubview(sendButton)
        
        sendButton.rightAnchor.constraint(equalTo: rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 60).isActive = true
        sendButton.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        addSubview(self.inputTextField)
        
        self.inputTextField.leftAnchor.constraint(equalTo: uploadImageView.rightAnchor, constant: 8).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: centerYAnchor).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: heightAnchor).isActive = true
        
        let lineView = UIView()
        lineView.backgroundColor = UIColor.darkGray//lineViewColor()//(r: 220, g: 220, b:220)
        lineView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(lineView)
        
        lineView.leftAnchor.constraint(equalTo: leftAnchor).isActive = true
        lineView.topAnchor.constraint(equalTo: topAnchor).isActive = true
        lineView.widthAnchor.constraint(equalTo: widthAnchor).isActive = true
        lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
    }
    
    //Press "Enter" to Send Message
    func textFieldShouldReturn(_ textField: UITextField) -> Bool
    {
        chatLogController?.requestSendMessage()
        sendButton.isEnabled = false
        return true
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let text = (textField.text! as NSString).replacingCharacters(in: range, with: string)
        
        if (!text.isEmpty)
        {
            sendButton.tintColor = .white
            sendButton.isEnabled = true
        }
        else
        {
            sendButton.isEnabled = false
        }
        
        return true
    }
    
    required init?(coder aDecoder: NSCoder)
    {
        fatalError("init(coder:) has not been implemented")
    }
}
