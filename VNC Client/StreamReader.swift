//
//  StreamReader.swift
//  VNC Client
//
//  Created by Alex Barron on 6/23/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation

class StreamReader
{
    static func readAllFromServer(inputStream: InputStream?) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: 4096)
        //while (inputStream!.hasBytesAvailable){
        _ = inputStream!.read(&buffer, maxLength: buffer.count)
        //}
        return buffer
    }
    
    static func readAllFromServer(inputStream: InputStream?, maxlength: Int) -> [UInt8] {
        var buffer = [UInt8](repeating: 0, count: maxlength)
       // while (inputStream!.hasBytesAvailable){
        _ = inputStream!.read(&buffer, maxLength: buffer.count)
        //}
        
        return buffer
    }
}
