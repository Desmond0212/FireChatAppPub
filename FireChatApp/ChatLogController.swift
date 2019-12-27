//
//  ChatLogController.swift
//  FireChatApp
//
//  Created by DesmondWong on 27/12/2019.
//  Copyright © 2019 DesmondWong. All rights reserved.
//

import UIKit
import Foundation
import Firebase
import MobileCoreServices
import AVFoundation

class ChatLogController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout, UIImagePickerControllerDelegate, UINavigationControllerDelegate
{
    let cellId = "cellId"
    var messages = [Message]()
    var containerViewBottomAnchor: NSLayoutConstraint?
    var startingFrame: CGRect?
    var blackBackgroundView: UIView?
    var startingImageView: UIImageView?
    
    var user: User?
    {
        didSet
        {
            navigationItem.title = user?.Username
            observeMessages()
        }
    }
    
    override func viewDidLoad()
    {
        super.viewDidLoad()
        
        view.backgroundColor = UIColor.mainBlue()
        navigationController?.navigationBar.barStyle = .black
        
        collectionView?.contentInset = UIEdgeInsets(top: 10, left: 0, bottom: 68, right: 0)
        //collectionView?.scrollIndicatorInsets = UIEdgeInsets(top: 0, left: 0, bottom: 50, right: 0)
        collectionView?.backgroundColor = UIColor.mainBlue()//white
        collectionView?.alwaysBounceVertical = true
        collectionView?.register(ChatCollectionViewCell.self, forCellWithReuseIdentifier: cellId)
        collectionView?.keyboardDismissMode = .interactive
        
        //setupInputComponents()
        setupKeyboardObservers()
    }
    
    lazy var inputContainerView: ChatInputContainerView = {
        
        let chatInputContainerView = ChatInputContainerView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 50))
        chatInputContainerView.chatLogController = self
        
        return chatInputContainerView
    }()
    
    override var inputAccessoryView: UIView?
        {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool
    {
        return true
    }
    
    @objc func handleUploadTap()
    {
        let imagePickerController = UIImagePickerController()
        
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        //To Upload Images and Videos from Mobile Phone.
        imagePickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
        
        present(imagePickerController, animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController)
    {
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any])
    {
        print("An image has been selected!")
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL
        {
            //A Video has been Selected by the User.
            print("Video URL: ", videoUrl)
            handleVideoSelectedForUrl(videoUrl: videoUrl)
        }
        else
        {
            //An Image has been Selected by the User.
            handleImageSelectedForInfo(info: info as [String : AnyObject])
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func handleVideoSelectedForUrl(videoUrl: URL)
    {
        let filename = UUID().uuidString + ".mov"
        let ref = Storage.storage().reference().child("message_videos").child(filename)
        let uploadTask = ref.putFile(from: videoUrl, metadata: nil, completion: { (_, err) in
            if let err = err {
                print("Failed to upload movie:", err)
                return
            }
            
            ref.downloadURL(completion: { (downloadUrl, err) in
                if let err = err {
                    print("Failed to get download url:", err)
                    return
                }
                
                guard let downloadUrl = downloadUrl else { return }
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(videoUrl: videoUrl)
                {
                    self.uploadToFirebaseStorageUsingImage(image: thumbnailImage, completion: {(imageUrl) in
                        let properties: [String: Any] = ["ImageUrl": imageUrl, "ImageWidth": thumbnailImage.size.width, "ImageHeight": thumbnailImage.size.height, "VideoUrl": downloadUrl.absoluteString]
                        self.sendMessageWithProperties(properties: properties)
                        
                    })
                }
            })
        })
        
        uploadTask.observe(.progress) { (snapshot) in
            /*if let completedUnitCount = snapshot.progress?.completedUnitCount
             {
             self.navigationItem.title = String(completedUnitCount)
             }*/
            self.navigationItem.title = "Sending Video..."
        }
        
        uploadTask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.user?.Username
        }
    }
    
    private func thumbnailImageForFileUrl(videoUrl: URL) -> UIImage?
    {
        let asset = AVAsset(url: videoUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        do {
            
            let thumbnailCGImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)
            return UIImage(cgImage: thumbnailCGImage)
            
        } catch let err {
            print(err)
        }
        
        return nil
    }
    
    private func handleImageSelectedForInfo(info: [String: AnyObject])
    {
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage
        {
            selectedImageFromPicker = editedImage
        }
        else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage
        {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker
        {
            uploadToFirebaseStorageUsingImage(image: selectedImage, completion: {(imageUrl) in
                self.sendMessageWithImageUrl(imageUrl: imageUrl, image: selectedImage)
            })
        }
    }
    
    private func uploadToFirebaseStorageUsingImage(image: UIImage, completion: @escaping (_ imageUrl: String) -> ())
    {
        print("Selected image is uploading to Firebase.")
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        
        if let uploadData = UIImageJPEGRepresentation(image, 0.2) {
            ref.putData(uploadData, metadata: nil, completion: {(metadata, error) in
                
                if (error != nil)
                {
                    print("Failed to upload:", error!)
                    return
                }
                
                ref.downloadURL(completion: { (url, err) in
                    if let err = err {
                        print(err)
                        return
                    }
                    
                    //self.sendMessageWithImageUrl(imageUrl: url!.absoluteString, image: image)
                    completion(url?.absoluteString ?? "")
                })
                
                
            })
        }
    }
    
    /*func setupInputComponents()
     {
     let containerView = UIView()
     containerView.translatesAutoresizingMaskIntoConstraints = false
     containerView.backgroundColor = UIColor.white
     
     view.addSubview(containerView)
     
     containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
     containerViewBottomAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
     containerViewBottomAnchor?.isActive = true
     containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
     containerView.heightAnchor.constraint(equalToConstant: 50).isActive = true
     
     let sendButton = UIButton(type: .system)
     sendButton.setTitle("Send", for: .normal)
     sendButton.translatesAutoresizingMaskIntoConstraints = false
     sendButton.addTarget(self, action: #selector(requestSendMessage), for: .touchUpInside)
     
     containerView.addSubview(sendButton)
     
     sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
     sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
     sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
     sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
     
     /*let inputTextField = UITextField()
     inputTextField.placeholder = "Enter message..."
     inputTextField.translatesAutoresizingMaskIntoConstraints = false*/
     
     containerView.addSubview(inputTextField)
     
     inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
     inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor).isActive = true
     inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
     inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
     
     let lineView = UIView()
     lineView.backgroundColor = UIColor(r: 220, g: 220, b:220)
     lineView.translatesAutoresizingMaskIntoConstraints = false
     
     containerView.addSubview(lineView)
     
     lineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
     lineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
     lineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
     lineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
     }*/
    
    override func viewDidDisappear(_ animated: Bool)
    {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
    }
    
    func setupKeyboardObservers()
    {
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardDidShow), name: NSNotification.Name.UIKeyboardDidShow, object: nil)
        
        /*NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: NSNotification.Name.UIKeyboardWillShow, object: nil)
         NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: NSNotification.Name.UIKeyboardWillHide, object: nil)*/
    }
    
    @objc func handleKeyboardDidShow()
    {
        if messages.count > 0
        {
            let indexPath = NSIndexPath(item: messages.count - 1, section: 0)
            collectionView?.scrollToItem(at: indexPath as IndexPath, at: .top, animated: true)
        }
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification)
    {
        let keyboardFrame = (notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = -keyboardFrame!.height
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification)
    {
        let keyboardDuration = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as AnyObject).doubleValue
        
        containerViewBottomAnchor?.constant = 0
        UIView.animate(withDuration: keyboardDuration!, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator)
    {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatCollectionViewCell
        let message = messages[indexPath.item]
        
        cell.message = message
        cell.chatLogController = self
        setupCell(cell: cell, message: message)
        cell.textView.text = message.text
        
        if let text = message.text {
            cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: text).width + 32
            cell.textView.isHidden = false
        }
        else if (message.imageUrl != nil)
        {
            cell.bubbleWidthAnchor?.constant = 200
            cell.textView.isHidden = true
        }
        
        cell.playButton.isHidden = message.videoUrl == nil
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        var height: CGFloat = 100
        let message = messages[indexPath.item]
        if let text = message.text
        {
            height = estimateFrameForText(text: text).height + 20
        }
        else if let imageWidth = message.imageWidth?.floatValue, let imageHeight = message.imageHeight?.floatValue
        {
            height = CGFloat(imageHeight / imageWidth * 200)
        }
        
        let width = UIScreen.main.bounds.width
        
        return CGSize(width: width, height: height)
    }
    
    private func setupCell(cell: ChatCollectionViewCell, message: Message)
    {
        if let profileImageUrl = self.user?.ProfileImage
        {
            cell.profileImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
        }
        
        if message.fromId == Auth.auth().currentUser?.uid
        {
            //Sender's BubbleView Color. [OUT]
            cell.bubbleView.backgroundColor = UIColor.bubbleViewBackgroundOUT()//(r:40, g:70, b:90)
            cell.textView.textColor = UIColor.white
            cell.bubbleViewLeftAnchor?.isActive = false
            cell.bubbleViewRightAnchor?.isActive = true
            cell.profileImageView.isHidden = true
        }
        else
        {
            //Receiver's BubbleView Color. [IN]
            cell.bubbleView.backgroundColor = UIColor.bubbleViewBackgroundIN()//(r:240, g:240, b:240)
            cell.textView.textColor = UIColor.black
            cell.bubbleViewLeftAnchor?.isActive = true
            cell.bubbleViewRightAnchor?.isActive = false
            cell.profileImageView.isHidden = false
        }
        
        if let messageImageUrl = message.imageUrl
        {
            cell.messageImageView.loadImageUsingCacheWithUrlString(urlString: messageImageUrl)
            cell.messageImageView.isHidden = false
        }
        else
        {
            cell.messageImageView.isHidden = true
        }
    }
    
    private func estimateFrameForText(text: String) -> CGRect
    {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string: text).boundingRect(with: size, options: options, attributes: [kCTFontAttributeName as NSAttributedString.Key: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    func observeMessages()
    {
        guard let uid = Auth.auth().currentUser?.uid, let toId = user?.Id else {
            return
        }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(uid).child(toId)
        userMessagesRef.observe(.childAdded, with: {(snapshot) in
            print(snapshot)
            
            let messageId = snapshot.key
            let messageRef = Database.database().reference().child("Messages").child(messageId)
            
            messageRef.observe(.value, with: {(snapshot) in
                print(snapshot)
                
                guard let dictionary = snapshot.value as? [String: AnyObject] else
                {
                    return
                }
                
                /*let message = Message(dictionary: dictionary)
                 
                 if (message.chatPartnerId() == self.user?.Id)
                 {
                 self.messages.append(Message(dictionary: dictionary))
                 
                 DispatchQueue.main.async(execute: {
                 self.collectionView?.reloadData()
                 })
                 }*/
                self.messages.append(Message(dictionary: dictionary))
                
                DispatchQueue.main.async(execute: {
                    self.collectionView?.reloadData()
                    
                    //Auto Scroll Message to the Latest Index
                    let indexPath = NSIndexPath(item: self.messages.count - 1, section: 0)
                    self.collectionView?.scrollToItem(at: indexPath as IndexPath, at: .bottom, animated: true)
                })
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    @objc func requestSendMessage()
    {
        print(inputContainerView.inputTextField.text!)
        
        let properties: [String: AnyObject]  = ["Message": inputContainerView.inputTextField.text! as AnyObject]
        
        sendMessageWithProperties(properties: properties)
        inputContainerView.sendButton.isEnabled = false
        
        //Modify Use Case
        /*let ref = Database.database().reference().child("Messages")
         let values = ["text": inputTextField.text!]
         ref.updateChildValues(values)*/
    }
    
    private func sendMessageWithImageUrl(imageUrl: String, image: UIImage)
    {
        let properties: [String: AnyObject] = ["ImageUrl": imageUrl as AnyObject, "ImageWidth": image.size.width as AnyObject, "ImageHeight": image.size.height as AnyObject]
        
        sendMessageWithProperties(properties: properties)
        
        /*let ref = Database.database().reference().child("Messages")
         let childRef = ref.childByAutoId()
         let toUsername = user!.Username!
         let toId = user!.Id!
         let fromId = Auth.auth().currentUser!.uid
         let currentUser = Auth.auth().currentUser
         let fromEmail = currentUser!.email!
         let timestamp = Int(Date().timeIntervalSince1970)
         let values: [String: Any]  = ["ImageUrl": imageUrl, "ToUsername" : toUsername, "ToId": toId, "FromId": fromId, "FromEmail": fromEmail, "Timestamp": timestamp, "ImageWidth": image.size.width, "ImageHeight": image.size.height]
         
         childRef.updateChildValues(values) {(error, ref) in
         if (error != nil)
         {
         print(error!)
         return
         }
         
         self.inputTextField.text = nil
         let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
         let messageId = childRef.key
         let values: [String: Any] = [messageId!: 1]
         
         userMessageRef.updateChildValues(values)
         
         let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
         let recipientValues: [String: Any] = [messageId!: 1]
         
         recipientUserMessagesRef.updateChildValues(recipientValues)
         }*/
    }
    
    private func sendMessageWithProperties(properties: [String: Any])
    {
        let ref = Database.database().reference().child("Messages")
        let childRef = ref.childByAutoId()
        let toUsername = user!.Username!
        let toId = user!.Id!
        let fromId = Auth.auth().currentUser!.uid
        let currentUser = Auth.auth().currentUser
        let fromEmail = currentUser!.email!
        let timestamp = Int(Date().timeIntervalSince1970)
        var values: [String: Any]  = [ "ToUsername" : toUsername, "ToId": toId, "FromId": fromId, "FromEmail": fromEmail, "Timestamp": timestamp]
        
        properties.forEach({values[$0] = $1})
        
        childRef.updateChildValues(values) {(error, ref) in
            if (error != nil)
            {
                print(error!)
                return
            }
            
            self.inputContainerView.inputTextField.text = nil
            let userMessageRef = Database.database().reference().child("user-messages").child(fromId).child(toId)
            let messageId = childRef.key
            let values: [String: Any] = [messageId!: 1]
            
            userMessageRef.updateChildValues(values)
            
            let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId).child(fromId)
            let recipientValues: [String: Any] = [messageId!: 1]
            
            recipientUserMessagesRef.updateChildValues(recipientValues)
        }
    }
    
    //Custom Zoom In Logic
    func performZoomInForStartingImageView(startingImageView: UIImageView)
    {
        self.startingImageView = startingImageView
        self.startingImageView?.isHidden = true
        startingFrame = startingImageView.superview?.convert(startingImageView.frame, to: nil)
        print(startingFrame!)
        
        let zoomingImageView = UIImageView(frame: startingFrame!)
        zoomingImageView.backgroundColor = UIColor.red
        zoomingImageView.image = startingImageView.image
        zoomingImageView.isUserInteractionEnabled = true
        zoomingImageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(handleZoomOut)))
        
        if let keyWindow = UIApplication.shared.keyWindow {
            
            blackBackgroundView = UIView(frame: keyWindow.frame)
            blackBackgroundView?.backgroundColor = UIColor.black
            blackBackgroundView?.alpha = 0
            
            keyWindow.addSubview(blackBackgroundView!)
            keyWindow.addSubview(zoomingImageView)
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                self.blackBackgroundView?.alpha = 1
                self.inputContainerView.alpha = 0
                
                let height = self.startingFrame!.height / self.startingFrame!.width * keyWindow.frame.width
                
                zoomingImageView.frame = CGRect(x: 0, y: 0, width: keyWindow.frame.width, height: height)
                zoomingImageView.center = keyWindow.center
                
            }, completion: { (completed) in
                //don't do anything in this section.
            })
        }
    }
    
    @objc func handleZoomOut(tapGesture: UITapGestureRecognizer)
    {
        if let zoomOutImageView = tapGesture.view {
            //Animation for Zooming Out to ViewController
            zoomOutImageView.layer.cornerRadius = 16
            zoomOutImageView.clipsToBounds = true
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: 1, options: .curveEaseOut, animations: {
                
                zoomOutImageView.frame = self.startingFrame!
                self.blackBackgroundView?.alpha = 0
                self.inputContainerView.alpha = 1
                
            }, completion: { (completed) in
                zoomOutImageView.removeFromSuperview()
                self.startingImageView?.isHidden = false
            })
        }
    }
}
