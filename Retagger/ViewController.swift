//
//  ViewController.swift
//  Retagger
//
//  Created by Andre Yonadam on 12/16/18.
//  Copyright © 2018 Andre Yonadam. All rights reserved.
//

import Cocoa

class ViewController: NSViewController {
    
    @IBOutlet weak var descriptionText: NSTextField!
    @IBOutlet weak var selectFolderButton: NSButton!
    @IBOutlet weak var progressIndicator: NSProgressIndicator!
    @IBOutlet weak var stopRetaggingButton: NSButton!
    
    var cancelClicked = false
    
    override func viewDidLoad() {
        super.viewDidLoad() 
        // Do any additional setup after loading the view.
    }
    
    override var representedObject: Any? {
        didSet {
            // Update the view, if already loaded.
        }
    }
    
    @IBAction func selectFolder(_ sender: Any) {
        let panel                     = NSOpenPanel()
        panel.canChooseDirectories    = true
        panel.canChooseFiles          = false
        panel.allowsMultipleSelection = true
        let clicked                   = panel.runModal()
        
        if clicked == NSApplication.ModalResponse.OK {
            descriptionText.isHidden = true
            selectFolderButton.isHidden = true
            progressIndicator.isHidden = false
            progressIndicator.startAnimation(nil)
            stopRetaggingButton.isHidden  = false
            
            DispatchQueue.global(qos: .background).async {
                let resourceKeys : [URLResourceKey] = [.creationDateKey, .isDirectoryKey]
                let documentsURL = panel.urls[0]
                let enumerator = FileManager.default.enumerator(at: documentsURL,
                                                                includingPropertiesForKeys: resourceKeys,
                                                                options: [.skipsHiddenFiles], errorHandler: { (url, error) -> Bool in
                                                                    print("directoryEnumerator error at \(url): ", error)
                                                                    return true
                })!
                innerLoop: for case let fileURL as URL in enumerator {
                    let url = URL(fileURLWithPath: fileURL.path)
                    do {
                        let resourceValues = try url.resourceValues(forKeys: [.tagNamesKey])
                        if let oldTags = resourceValues.tagNames {
                            let clearTags = [String]()
                            try (url as NSURL).setResourceValue(clearTags, forKey: .tagNamesKey)
                            try (url as NSURL).setResourceValue(oldTags, forKey: .tagNamesKey)
                        }
                    } catch {
                        print(error)
                    }
                    
                    // Check if cancel button clicked
                    if (self.cancelClicked) {
                        self.cancelClicked = false
                        break innerLoop
                    }
                    
                }
                
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Finished"
                    alert.informativeText = "Finished retagging folders and files"
                    alert.alertStyle = .informational
                    alert.addButton(withTitle: "Done")
                    alert.runModal()
                    
                    self.descriptionText.isHidden = false
                    self.selectFolderButton.isHidden = false
                    self.progressIndicator.isHidden = true
                    self.stopRetaggingButton.isHidden  = true
                }
            }
        }
        
    }
    
    @IBAction func stopRetaggingClicked(_ sender: Any) {
        cancelClicked = true
    }
}
