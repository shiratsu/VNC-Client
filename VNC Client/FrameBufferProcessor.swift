//
//  FrameBufferProcessor.swift
//  VNC Client
//
//  Created by Alex Barron on 6/23/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import CoreFoundation
import UIKit

class FrameBufferProcessor
{
    private var inputStream: InputStream?
    private var outputStream: OutputStream?
    
    let encodingMessageType = 2
    var pixelRectangle: PixelRectangle?
    
    let frameBufferRequestMessageType = UInt8(3)
    
    var pixelsToRead = 0
    var rectsToRead = 0
    var pixelBuffer = [UInt8]()
    
    struct Point {
        var x = 0;
        var y = 0;
    }
   // var rects = [Point:(Int, Int)]()
    
    init(inputStream: InputStream?, outputStream: OutputStream?) {
        self.inputStream = inputStream
        self.outputStream = outputStream
    }
    
    //frame buffer constants
    var framebufferwidth = 0
    var framebufferheight = 0
    var bitsperpixel = 0
    var depth = 0
    var bigendianflag = 0
    var truecolourflag = 0
    var redmax = 0
    var greenmax = 0
    var bluemax = 0
    var redshift = 0
    var greenshift = 0
    var blueshift = 0
    
    func initialise() {
        var buffer = StreamReader.readAllFromServer(inputStream: inputStream)
        let data = NSData(bytes: buffer, length: 4096)
        
        //extract constants
        data.getBytes(&framebufferwidth, range: NSMakeRange(0,2))
        data.getBytes(&framebufferheight, range: NSMakeRange(2,2))
        data.getBytes(&bitsperpixel, range: NSMakeRange(4,1))
        data.getBytes(&depth, range: NSMakeRange(5,1))
        data.getBytes(&bigendianflag, range: NSMakeRange(6,1))
        data.getBytes(&truecolourflag, range: NSMakeRange(7,1))
        data.getBytes(&redmax, range: NSMakeRange(8,2))
        data.getBytes(&greenmax, range: NSMakeRange(10,2))
        data.getBytes(&bluemax, range: NSMakeRange(12,2))
        data.getBytes(&redshift, range: NSMakeRange(14,1))
        data.getBytes(&greenshift, range: NSMakeRange(15,1))
        data.getBytes(&blueshift, range: NSMakeRange(16,1))
        
        //fix network byte order
        framebufferwidth = Int(CFSwapInt16(UInt16(framebufferwidth)))
        framebufferheight = Int(CFSwapInt16(UInt16(framebufferheight)))
        redmax = Int(CFSwapInt16(UInt16(redmax)))
        greenmax = Int(CFSwapInt16(UInt16(greenmax)))
        bluemax = Int(CFSwapInt16(UInt16(bluemax)))
        
        print("Frame Width: \(framebufferwidth)")
        print("Frame Height: \(framebufferheight)")
        print("Bits Per Pixel: \(bitsperpixel)")
        print("True colour: \(truecolourflag)")
        print("Depth:  \(depth)")
        print("redmax:  \(redmax)")
        print("redshift:  \(redshift)")
        
        //set encoding
        var encoding: [UInt8] = [UInt8(encodingMessageType), 0, 0, 1, 0, 0, 0, 0]
        outputStream!.write(&encoding, maxLength: encoding.count)
        
        //set size of pixel buffer according to frame size
        pixelBuffer = [UInt8](repeating: 0, count: framebufferwidth * framebufferheight * 4)
        
        //send initial frame buffer request
        sendFrameBufferRequest(incremental: 0, xvalue: 0, yvalue: 0, width: UInt16(framebufferwidth), height: UInt16(framebufferheight))
    }
    
    private func sendFrameBufferRequest(incremental: UInt8, xvalue: UInt16, yvalue: UInt16, width: UInt16, height: UInt16) {
        
        let firstbytex = UInt8(xvalue)
        let secondbytex = UInt8(xvalue.byteSwapped)
        let firstbytey = UInt8(yvalue)
        let secondbytey = UInt8(yvalue.byteSwapped)
        let firstbytewidth = UInt8(width)
        let secondbytewidth = UInt8(width.byteSwapped)
        let firstbyteheight = UInt8(height)
        let secondbyteheight = UInt8(height.byteSwapped)
        let info = [frameBufferRequestMessageType, incremental, secondbytex, firstbytex, secondbytey, firstbytey, secondbytewidth, firstbytewidth, secondbyteheight, firstbyteheight]
        outputStream?.write(info, maxLength: info.count)
    }
    
    func sendRequest() {
        sendFrameBufferRequest(incremental: 1, xvalue: 0, yvalue: 0, width: UInt16(framebufferwidth), height: UInt16(framebufferheight))
    }
    
    //return the number of pixels found
    private func ingestRectangle(offset: Int, data: NSData) -> PixelRectangle {
        var xvalue = 0
        var yvalue = 0
        var width = 0
        var height = 0
        var encodingtype = 0
        data.getBytes(&xvalue, range: NSMakeRange(offset, 2))
        data.getBytes(&yvalue, range: NSMakeRange(offset + 2, 2))
        data.getBytes(&width, range: NSMakeRange(offset + 4, 2))
        data.getBytes(&height, range: NSMakeRange(offset + 6, 2))
        data.getBytes(&encodingtype, range: NSMakeRange(offset + 8, 4))
        xvalue = Int(CFSwapInt16(UInt16(xvalue)))
        yvalue = Int(CFSwapInt16(UInt16(yvalue)))
        width = Int(CFSwapInt16(UInt16(width)))
        height = Int(CFSwapInt16(UInt16(height)))
        encodingtype = Int(CFSwapInt16(UInt16(encodingtype)))
        print("xvalue: \(xvalue)")
        print("yvalue: \(yvalue)")
        print("width: \(width)")
        print("height: \(height)")
        print("encodingtype: \(encodingtype)")
        return PixelRectangle(xvalue: xvalue, yvalue: yvalue, width: width, height: height, encodingtype: 0, image: nil)
    }
    
    func readHeader() {
        let buffer = StreamReader.readAllFromServer(inputStream: inputStream, maxlength: 4)
        print("Message type: \(buffer[0])")
        var data = NSData(bytes: buffer, length: 4)
        data.getBytes(&rectsToRead, range: NSMakeRange(2, 2))
        print("Num rects: \(Int(CFSwapInt16(UInt16(rectsToRead))))")
        rectsToRead = (Int(CFSwapInt16(UInt16(rectsToRead))))
        print("rectsToRead: \(rectsToRead)")
    }
    
    func readRectHeader() -> Bool {
        
        if rectsToRead == 0 { return false }
        var buffer = StreamReader.readAllFromServer(inputStream: inputStream, maxlength: 12)
        var data = NSData(bytes: buffer, length: 12)
        pixelRectangle = ingestRectangle(offset: 0, data: data)
        rectsToRead-=1
        pixelsToRead = pixelRectangle!.width * pixelRectangle!.height * 4
        return true
    }
    
    private func createImage() -> UIImage {
        
        //lets make a UIImage first
        return ImageProcessor.imageFromARGB32Bitmap(data: NSData(bytes: &pixelBuffer, length: pixelBuffer.count), width: framebufferwidth, height: framebufferheight)
        
    }
    //transfer pixels directly to buffer, then we'll update the image
    private func addPixelsToBuffer(buffer: [UInt8], len: Int) {
        //need to use pixelsToRead and the size and x/y position of the rectangle we're trying to draw to do this
        //every rect width need to go down a level
        //figure out coordinates in pixel rect
        //then transfer this to overall thing?
        var pixelsRead = pixelRectangle!.width * pixelRectangle!.height * 4 - pixelsToRead
        var xCoordInRect = pixelsRead % (pixelRectangle!.width * 4)
        var yCoordInRect = pixelsRead / (pixelRectangle!.width * 4)
        
        var initialIndex = ((pixelRectangle!.yvalue) + yCoordInRect) * (framebufferwidth * 4) + (pixelRectangle!.xvalue  * 4) + xCoordInRect
        //print("Initial index: \(initialIndex)")
        //outer for loop goes through every level
        
        for i in 0..<len {
            var curIndex = (initialIndex + i) + (framebufferwidth * 4 - pixelRectangle!.width * 4) * (((pixelsRead + i) / (pixelRectangle!.width * 4)) - yCoordInRect)
            pixelBuffer[curIndex] = buffer[i]
        }
    }
    
    func getPixelData() -> Int {
        if pixelsToRead > 0 {
           
            var buffer = [UInt8](repeating: 0, count: pixelsToRead)
            var len = inputStream!.read(&buffer, maxLength: buffer.count)
            
            var tempByte = UInt8(0)
            //change from bgr to rgb
            
            for index in 0 ..< len {
                if index % 4 != 0{
                    continue
                }
                tempByte = buffer[index]
                buffer[index] = buffer[index + 2]
                buffer[index + 2] = tempByte
            }
            addPixelsToBuffer(buffer: buffer, len: len)
            pixelsToRead -= len
            print("Len: \(len)")
            print("pixels left: \(pixelsToRead)")
        }
        if pixelsToRead == 0 {
            print("rectsToRead: \(rectsToRead)")
            var image = createImage()
            pixelRectangle!.image = image
            NotificationCenter.default.post(name: NSNotification.Name(rawValue: "pixeldataavailiable"), object: nil, userInfo: ["data":pixelRectangle!])
            if rectsToRead > 0 {
                print("returning 1")
                return 1
            }
            else { return 2 }
        }
        return 0 //signifies keep reading pixels
    }
}
