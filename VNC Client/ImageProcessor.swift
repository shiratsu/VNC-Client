//
//  ImageProcessor.swift
//  VNC Client
//
//  Created by Alex Barron on 6/26/15.
//  Copyright (c) 2015 Alex Barron. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

// TODO: このプログラムはどう直すか検討

class ImageProcessor
{
    static func imageFromARGB32Bitmap(data: NSData, width:Int, height:Int) -> UIImage {
        let bitsPerComponent:Int = 8
        let bitsPerPixel:Int = 32
        
        let providerRef = CGDataProvider(data: data)
        let rgb = CGColorSpaceCreateDeviceRGB()
        
        let bitmapinfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue)
            .union(.byteOrder32Little)
        
        let cgim: CGImage = CGImage.init(width: width, height: height, bitsPerComponent: bitsPerComponent, bitsPerPixel: bitsPerPixel, bytesPerRow: width * 4, space: rgb, bitmapInfo: bitmapinfo, provider: providerRef!, decode: nil, shouldInterpolate: true, intent: CGColorRenderingIntent.defaultIntent)!
        
        return UIImage(cgImage: cgim)
    }

}
