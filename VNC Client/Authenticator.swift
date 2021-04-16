//
//  Authenticator.swift
//  VNC Client
//
//  Created by Alex Barron on 6/21/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class Authenticator
{
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    init(inputStream: InputStream?, outputStream: OutputStream?) {
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    func authenticate(password: String) {
        var buffer = StreamReader.readAllFromServer(inputStream: inputStream)
        var authenticationType = buffer[3]
        print("\(authenticationType)")
        switch authenticationType {
        case 2:
            buffer.removeSubrange(0...3)
//            buffer.removeRange(0...3)
            replyWithPassword(var: buffer, password: password)
            break
        default:
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: serverConnectionErrorNotificationKey), object: self)
            
            
            print("First char: \(buffer[9])")
            var reason = buffer[8...65]
            for index in reason {
                var char = CChar(index)
                print("\(char)")
            }
        }
        
    }
    
    func getAuthStatus() -> Bool {
        //either want to prompt to try a new password
        //or inform the user that we are connected!!!
        var buffer = StreamReader.readAllFromServer(inputStream: inputStream)
        print("\(buffer[3])")
        var authstatus = buffer[3]
        switch authstatus {
        case 0:
            print("Connected!")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: connectedNotificationKey), object: self)
            return true
        case 1:
            print("Wrong Password!")
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: wrongPasswordNotificationKey), object: self)
            inputStream!.close()
            outputStream!.close()
            return false
        case 2:
            print("Too many attempts")
            inputStream!.close()
            outputStream!.close()
            return false
        default:
            return false
        }
    }
    
    // TODO: ここ直すところ多そう。
    private func encryptChallenge(var challenge: [UInt8], keyBytes: [UInt8]) -> [UInt8] {
        
        let range1: Range<Int> = 8..<15
        let range2: Range<Int> = 0..<8
        var challenge2 = challenge
        var challenge3 = challenge
        challenge3.removeSubrange(range1)
        challenge2.removeSubrange(range2)
//        challenge.removeRange(8...15)
//        challenge2.removeRange(0...7)
        let first8bytes = Data(bytes: challenge, count: 8)
        let second8bytes = Data(bytes: challenge2, count: 8)
        let key = Data(bytes: keyBytes, count: keyBytes.count)
        print("Key: \(key)")
        print("First half: \(first8bytes)")
        print("Second half: \(second8bytes)")
        let firstHalfOfResult = DESEncryptor.encryptData(first8bytes as Data, key: key as Data)
        print("First Result: \(firstHalfOfResult)")
        let secondHalfOfResult = DESEncryptor.encryptData(second8bytes, key: key)
        print("Second Result: \(secondHalfOfResult)")
        let firstHalfResponse = [UInt8](repeating: 0, count: 8)
        let secondHalfResponse = firstHalfResponse
        let first1 = Array(firstHalfResponse[0..<9])
        let second1 = Array(secondHalfResponse[8..<16])
        let merged = first1 + second1
        return merged
    }
    
    private func flipPassword(password: String) -> [UInt8] {
        var passBytes = [UInt8](password.utf8)
        var flippedBytes = [UInt8](repeating: 0, count: 8)
        //need a function which takes a UInt8 and flips the bits
        for i in 0...7 {
            if i < passBytes.count {
                var byte = passBytes[i]
                byte = (byte & 0xF0) >> 4 | (byte & 0x0F) << 4;
                byte = (byte & 0xCC) >> 2 | (byte & 0x33) << 2;
                byte = (byte & 0xAA) >> 1 | (byte & 0x55) << 1;
                flippedBytes[i] = byte
            }
            else {
                //null pad flipped key
                flippedBytes[i] = 0
            }
        }
        return flippedBytes
    }
    
    private func replyWithPassword(var challenge: [UInt8], password: String) {
        var keyBytes = flipPassword(password: password)
        var response = encryptChallenge(var: challenge, keyBytes: keyBytes)
        outputStream!.write(&response, maxLength: response.count)
    }
}
