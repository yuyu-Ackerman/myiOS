//
//  DiaryEditViewViewModel.swift
//  try
//
//  Created by 小余 on 2026/2/18.
//

import UIKit

class DiaryEditViewModel {
    let model = DiaryEditModel()
    
    func getStarRate() -> Float {
        return model.starRate
    }
    
    func getDescription() -> String {
        return model.description
    }
    
    func getPictures() -> [UIImage] {
        return model.pictures
    }
    
    func getFirstPicture() -> UIImage {
        return model.pictures.first ?? UIImage()
    }
    
    func setStarRate(with starRate: Float) {
        model.starRate = starRate
    }
    
    func setDescription(with text: String) {
        model.description = text
    }
    
    func setPictures(with images: [UIImage]) {
        model.pictures = images
    }
}

