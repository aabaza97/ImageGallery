//
//  Gallery.swift
//  ImageGallery
//
//  Created by Ahmed Abaza on 22/02/2022.
//

import UIKit

///The wrapper of all images of gallery.
struct Gallery: Codable, Equatable {
    
    var id: String = UUID().uuidString
    
    var images: [Image]
    
    var title: String
    
    static func == (lhs: Gallery, rhs: Gallery) -> Bool {
        lhs.id == rhs.id
    }
}

///The wrapper of an image data inside a gallery.
struct Image: Codable {
    let aspectRatio: CGFloat
    
    let url: URL?
    
    let image: Data?
    
    
    init (url: URL? = nil, image: Data? = nil) {
        
        if let url = url, let image = image, let aspectRatio = UIImage(data: image)?.aspectRatio {
            self.url = url
            self.image = image
            self.aspectRatio = aspectRatio
        } else {
            guard let defaultImage = UIImage(systemName: "livephoto.slash"), let defaultImageData = defaultImage.pngData() else {
                self.url = nil
                self.image = nil
                self.aspectRatio = 1.0
                return
            }
            
            self.url = URL(string: "https://www.google.com/images/branding/googlelogo/2x/googlelogo_light_color_272x92dp.png")!
            self.image = defaultImageData
            self.aspectRatio = 1.0
        }
    }
}


