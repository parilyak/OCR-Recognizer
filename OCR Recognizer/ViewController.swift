//
//  ViewController.swift
//  OCR Recognizer
//
//  Created by Lilya on 25.05.2020.
//  Copyright © 2020 Lilya. All rights reserved.
//

import UIKit
import MobileCoreServices
import TesseractOCR
import GPUImage

class ViewController: UIViewController {
  @IBOutlet weak var textView: UITextView!
  @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
  
  override func viewDidLoad() {
    super.viewDidLoad()
  }
  
  // IBAction methods
  @IBAction func backgroundTapped(_ sender: Any) {
    view.endEditing(true)
  }
  
  @IBAction func takePhoto(_ sender: Any) {
    let imagePickerActionSheet =
      UIAlertController(title: "Snap/Upload Image",
                        message: nil,
                        preferredStyle: .actionSheet)
    
    if UIImagePickerController.isSourceTypeAvailable(.camera) {
      let cameraButton = UIAlertAction(
        title: "Take Photo",
        style: .default) { (alert) -> Void in
          self.activityIndicator.startAnimating()
          let imagePicker = UIImagePickerController()
          imagePicker.delegate = self
          imagePicker.sourceType = .camera
          imagePicker.mediaTypes = [kUTTypeImage as String]
          self.present(imagePicker, animated: true, completion: {
            self.activityIndicator.stopAnimating()
          })
      }
      imagePickerActionSheet.addAction(cameraButton)
    }
    
    let libraryButton = UIAlertAction(
      title: "Choose Existing",
      style: .default) { (alert) -> Void in
        self.activityIndicator.startAnimating()
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.mediaTypes = [kUTTypeImage as String]
        self.present(imagePicker, animated: true, completion: {
          self.activityIndicator.stopAnimating()
        })
    }
    imagePickerActionSheet.addAction(libraryButton)
    
    let cancelButton = UIAlertAction(title: "Cancel", style: .cancel)
    imagePickerActionSheet.addAction(cancelButton)
    
    present(imagePickerActionSheet, animated: true)
  }

  // Tesseract Image Recognition
  func performImageRecognition(_ image: UIImage) {
    let scaledImage = image.scaledImage(1000) ?? image
    let preprocessedImage = scaledImage.preprocessedImage() ?? scaledImage
    
    if let tesseract = G8Tesseract(language: "eng+fra") {
      tesseract.engineMode = .tesseractCubeCombined
      tesseract.pageSegmentationMode = .auto
      
      tesseract.image = preprocessedImage
      tesseract.recognize()
      textView.text = tesseract.recognizedText
    }
    activityIndicator.stopAnimating()
  }
}

// MARK: - UINavigationControllerDelegate
extension ViewController: UINavigationControllerDelegate {
}

// MARK: - UIImagePickerControllerDelegate
extension ViewController: UIImagePickerControllerDelegate {
  func imagePickerController(_ picker: UIImagePickerController,
       didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
    guard let selectedPhoto =
      info[.originalImage] as? UIImage else {
        dismiss(animated: true)
        return
    }
    activityIndicator.startAnimating()
    dismiss(animated: true) {
      self.performImageRecognition(selectedPhoto)
    }
  }
}

// MARK: - UIImage extension
extension UIImage {
  func scaledImage(_ maxDimension: CGFloat) -> UIImage? {
    var scaledSize = CGSize(width: maxDimension, height: maxDimension)

    if size.width > size.height {
      scaledSize.height = size.height / size.width * scaledSize.width
    } else {
      scaledSize.width = size.width / size.height * scaledSize.height
    }

    UIGraphicsBeginImageContext(scaledSize)
    draw(in: CGRect(origin: .zero, size: scaledSize))
    let scaledImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return scaledImage
  }
  
  func preprocessedImage() -> UIImage? {
    let stillImageFilter = GPUImageAdaptiveThresholdFilter()
    stillImageFilter.blurRadiusInPixels = 15.0
    let filteredImage = stillImageFilter.image(byFilteringImage: self)
    return filteredImage
  }
}

