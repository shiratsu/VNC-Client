//
//  ViewController.swift
//  VNC Client
//
//  Created by Alex Barron on 6/20/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import UIKit
import CoreGraphics

class ViewController: UIViewController {
    
    var servCon = ServerConnector()
    var firstCon = true

    @IBOutlet weak var desktopView: UIImageView!
    
    @IBOutlet weak var hostField: UITextField!
    @IBOutlet weak var passField: UITextField!
    @IBOutlet weak var connectButton: UIButton!
    
    let scrollViewSize = CGSize(width: 1680/3, height: 1050/2)
    
    private func addNotificationObservers() {
        NotificationCenter.default.addObserver(self, selector: Selector("actOnConnection"), name: NSNotification.Name(rawValue: connectedNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector("actOnServerError"), name: NSNotification.Name(rawValue: serverConnectionErrorNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector("actOnWrongPassword"), name: NSNotification.Name(rawValue: wrongPasswordNotificationKey), object: nil)
        NotificationCenter.default.addObserver(self, selector: Selector("actOnPixelData:"), name: NSNotification.Name(rawValue: pixelDataNotificationKey), object: nil)

    }
    
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBAction func connectToServer() {
        addNotificationObservers()
        servCon.connect(hostIP: hostField.text ?? "", password: passField.text ?? "")
        var size = scrollViewSize
        scrollView.contentSize = size

    }
    
    func actOnConnection() {
        print("Connected!")
        
    }
    
    func actOnServerError() {
        print("Server Error")
    }
    
    func actOnWrongPassword() {
        print("Wrong Password")
    }
    
    func actOnPixelData(notification: NSNotification) {
        
        print("Pixel data arriving!")
        var dataMap: Dictionary<String,PixelRectangle> = notification.userInfo as! Dictionary<String,PixelRectangle>
        var pixelRect = dataMap["data"]
        
        desktopView.image = pixelRect!.image
        desktopView.setNeedsDisplay()
        
    }

    
}

