//
//  ViewController.swift
//  MultipierDemo
//
//  Created by TechnoMac-1 on 28/12/16.
//  Copyright © 2016 Technostacks. All rights reserved.
//

import UIKit
import Foundation
import AVFoundation
import PeerKit
import AVKit
import MultipeerConnectivity

// -- structure Image Send
struct mydata: MPCSerializable {
    
    
    let img_video: String
    
    let strscrollPos : String
    
    var mpcSerialized: Data {
        return NSKeyedArchiver.archivedData(withRootObject: [ "img" : img_video ,"swipeanimation" : strscrollPos])
    }
    init(img_video: String ,strscrollPos : String) {
        self.img_video = img_video
        self.strscrollPos = strscrollPos
    }
    init(mpcSerialized: Data) {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: mpcSerialized) as! [String:String]
        img_video = dict["img"]!
        strscrollPos = dict["swipeanimation"]!
    }
}
// -- structure Image Scale
struct scaleStruct: MPCSerializable {
    
    var scale =  CGFloat()
    
    var mpcSerialized: Data {
        return NSKeyedArchiver.archivedData(withRootObject: [ "scale" : scale])
    }
    init(scale: CGFloat) {
        self.scale = scale
    }
    init(mpcSerialized: Data) {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: mpcSerialized) as! [String:CGFloat]
        scale = dict["scale"]!
    }
}
// -- structure Image Frame
struct frameStruct: MPCSerializable {
    var contentX = CGFloat()
    var contentY = CGFloat()
    var height = CGFloat()
    var width = CGFloat()
    
    var mpcSerialized: Data {
        return NSKeyedArchiver.archivedData(withRootObject: ["contentX":contentX,"contentY":contentY,"height":height,"width":width])
    }
    init( contentX : CGFloat,contentY : CGFloat,height : CGFloat,width : CGFloat) {
        self.contentX = contentX
        self.contentY = contentY
        self.height = height
        self.width = width
    }
    
    init(mpcSerialized: Data) {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: mpcSerialized) as! [String:CGFloat]
        
        contentX = dict ["contentX"]!
        contentY = dict ["contentY"]!
        height = dict ["height"]!
        width = dict ["width"]!
    }
}

// -- structure navigation Bar Hide and Show
struct tapNav: MPCSerializable {
    
    let navHide: String
    
    var mpcSerialized: Data {
        return NSKeyedArchiver.archivedData(withRootObject: [ "navHide" : navHide])
    }
    
    init(navHide: String) {
        self.navHide = navHide
    }
    
    init(mpcSerialized: Data) {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: mpcSerialized) as! [String:String]
        navHide = dict["navHide"]!
    }
}
struct orientationchange: MPCSerializable {
    
    let orientation: String
    
    var mpcSerialized: Data {
        return NSKeyedArchiver.archivedData(withRootObject: [ "orientation" : orientation])
    }
    
    init(orientation: String) {
        self.orientation = orientation
    }
    
    init(mpcSerialized: Data) {
        let dict = NSKeyedUnarchiver.unarchiveObject(with: mpcSerialized) as! [String:String]
        orientation = dict["orientation"]!
    }
}

class ViewController: UIViewController,UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout,scaleDelegate{
    
    
    @IBOutlet var scrlView: ImageScrollView!
    var assets: [DKAsset]?
    var btnPickImage = UIBarButtonItem()
    @IBOutlet var previewView: UICollectionView?
    var arrImages = NSMutableArray()
    var scale = CGFloat()
    var currentPage = Int()
    var image = UIImage()
    var x = CGFloat()
    var y = CGFloat()
    var isNavHide = Bool()
    var setScroll = Bool()
    var onceOnly = false
    var lastContentOffset = CGPoint()
    var isScrollLeft = Bool()
    
    let appDelegateObject = UIApplication.shared.delegate as! AppDelegate
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.btnPickImage = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(self.sayHello(sender:)))
        self.navigationItem.leftBarButtonItem = self.btnPickImage
        self.btnPickImage.isEnabled = false
        self.navigationItem.title="Searching"
        isNavHide = false
        
        //   NotificationCenter.default.addObserver(self, selector: #selector(ViewController.rotated), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(ViewController.tapNavHide), name: NSNotification.Name(rawValue: "taponView"), object: nil)
        
        self.previewView?.addObserver(self, forKeyPath: "contentSize", options: .old, context: nil)
        
        
        // collectionView FlowLayout
        //        let flow = self.previewView?.collectionViewLayout as! UICollectionViewFlowLayout
        //        flow.sectionInset = UIEdgeInsetsMake(0, 0, 0, 0)
        
    }
    
    override open func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?)
    {
        for cell in self.previewView!.visibleCells as! [CustomCell] {
            
            // cell.scrlView.refresh()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        // Tap Gesture
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapNavHide(sender:)))
        self.scrlView.addGestureRecognizer(tapGesture)
        
        ConnectionManager.onConnect { _ in
            
            DispatchQueue.main.async {
                self.navigationItem.title="Connected"
                self.btnPickImage.isEnabled = true
            }
        }
        
        ConnectionManager.onDisconnect { _ in
            DispatchQueue.main.async {
                self.navigationItem.title="Disconnected"
                self.btnPickImage.isEnabled = false
                
            }
        }
        
        ConnectionManager.onEvent(.send) { [unowned self] _, object in
            // Recieve data Image From Sender side
            self.previewView?.isHidden = true
            self.scrlView.isHidden = false
            let dict = object as! [String: NSData]
            let mystruct = mydata(mpcSerialized:dict["data"] as! Data)
            
            let str : String = mystruct.img_video
            let dataDecoded:NSData = NSData(base64Encoded:str, options: NSData.Base64DecodingOptions.ignoreUnknownCharacters)!
            let image = UIImage(data: dataDecoded as Data)
            
            AppDelegate.appDelegate().strscrollPosition = mystruct.strscrollPos
            
            if let img = image
            {
                self.appDelegateObject.isViewerSide = true
                self.scrlView.display(image: img)
            }
            
            self.x = (self.scrlView.zoomView?.frame.origin.x)!
            self.y = (self.scrlView.zoomView?.frame.origin.y)!
        }
        
        ConnectionManager.onEvent(.scale) { [unowned self] _, object in
            
            // recieve data image Zoom scale From Sender
            
            let dictFrame = object as! [String: NSData]
            let myScale = scaleStruct(mpcSerialized:dictFrame["scaleData"] as! Data)
            let scale = myScale.scale
            if scale > 1 {
                self.scrlView.zoomView?.transform = CGAffineTransform(scaleX: myScale.scale, y: myScale.scale)
            }
        }
        
        ConnectionManager.onEvent(.orientation) { [unowned self] _, object in
            let dictFrame = object as! [String: NSData]
            let oret = orientationchange(mpcSerialized:dictFrame["orientation"] as! Data)
            let landscape = oret.orientation
            
            if landscape == "landscape"
            {
                AppDelegate.appDelegate().isViewerLandscapeUpdate = true
            }
            else
            {
                AppDelegate.appDelegate().isViewerLandscapeUpdate = false
            }
        }
        
        ConnectionManager.onEvent(.frame) { [unowned self] _, object in
            
            // recieve data image Frame From Sender
            
            let dictFrame = object as! [String: NSData]
            let myFrame = frameStruct(mpcSerialized:dictFrame["frameData"] as! Data)
            
            
            
            UIView.animate(withDuration: 0.3, animations: {
                self.scrlView.contentOffset = CGPoint(x: myFrame.contentX, y: myFrame.contentY)
                self.scrlView.zoomView?.frame = CGRect(x: self.x, y:self.y, width:myFrame.width, height: myFrame.height)
            })
            
            // self.scrlView.zoom(to: CGRect(x: self.x, y:self.y, width:myFrame.width, height: myFrame.height), animated: true)
            
        }
        ConnectionManager.onEvent(.nav) { [unowned self] _, object in
            
            // Recieve data navigation Hide and Show From Sender Side
            
            let dictFrame = object as! [String: NSData]
            let hideNav = tapNav(mpcSerialized:dictFrame["navHide"] as! Data)
            let hide = hideNav.navHide
            if hide == "true" {
                self.navigationController?.isNavigationBarHidden = true
            }else{
                self.navigationController?.isNavigationBarHidden = false
            }
        }
    }
    override func viewWillDisappear(_ animated: Bool) {
        ConnectionManager.onConnect(nil)
        ConnectionManager.onDisconnect(nil)
        ConnectionManager.onEvent(.send, run: nil)
        
        super.viewWillDisappear(animated)
    }
    
    
    func sayHello(sender: UIBarButtonItem) {
        
        // Select Photo From Gallery
        
        let pickerController = DKImagePickerController()
        pickerController.assetType = .allPhotos
        pickerController.didSelectAssets = { [unowned self] (assets: [DKAsset]) in
            print("didSelectAssets")
            self.arrImages.removeAllObjects()
            self.previewView?.isHidden = false
            self.scrlView.isHidden = true
            self.currentPage = 0
            self.assets = assets
            
            for asset in self.assets!
            {
                asset.fetchOriginalImage(true, completeBlock: { (image, info) in
                    self.arrImages.add(image)
                })
            }
            
            AppDelegate.appDelegate().isViewerSide = false
            
            self.previewView?.contentOffset = CGPoint(x: 0, y: 0)
            
            print(self.arrImages);
            self.setScroll = true
            self.onceOnly = false
            self.isScrollLeft = true
            self.currentPage = 0
            self.previewView?.isHidden = false
            self.previewView?.reloadData()
            
        }
        if UI_USER_INTERFACE_IDIOM() == .pad {
            pickerController.modalPresentationStyle = .formSheet
        }
        
        self.present(pickerController, animated: true) {}
    }
    
    // MARK :- status bar hide show method
    
    override var prefersStatusBarHidden: Bool {
        
        if isNavHide
        {
            return true
        }
        else
        {
            return false
        }
    }
    
    // MARK: - Custom method
    
    func captureScreenFromView(imgv:UIImageView) -> NSData?
    {
        let imgview = imgv
        
        //let dataimg = UIScreenCapture.takeSnapshotGetJPEG(0.4, size: CGSize(width: 640, height: 1136), view: imgview)
        
        let image = UIScreenCapture.takeSnapshot(with: CGSize(width: 640, height: 1136), view: imgview)
        
        let dataImage = UIImageJPEGRepresentation(image!, 0.1)
        return dataImage as NSData?
        
    }
    
    // MARK: - UICollectionViewDataSource, UICollectionViewDelegate methods
    
    func collectionView(_ collectionView: UICollectionView,
                        willDisplay cell: UICollectionViewCell,
                        forItemAt indexPath: IndexPath)
    {
        
        let pageWidth = self.previewView?.frame.size.width
        currentPage = Int(CGFloat((self.previewView?.contentOffset.x)! / pageWidth!))
        
        let cellCustom = cell as! CustomCell
        cellCustom.scrlView.refresh()
        
        if self.lastContentOffset.x < (self.previewView?.contentOffset.x)!
        {
            // right
            self.isScrollLeft = false
        }
        else
        {
            // left
            self.isScrollLeft = true
        }
        
        if !onceOnly
        {
//            let indexToScrollTo = NSIndexPath(row: 0, section: 0)
//            self.previewView?.scrollToItem(at: indexToScrollTo as IndexPath, at: .left, animated: false)
            
            let dataImg = captureScreenFromView(imgv: cellCustom.scrlView.zoomView!)
            sendImage(data: dataImg!)
            onceOnly = true
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath)
    {
        let pageWidth = self.previewView?.frame.size.width
        currentPage = Int(CGFloat((self.previewView?.contentOffset.x)! / pageWidth!))
        
        if self.lastContentOffset.x < (self.previewView?.contentOffset.x)!
        {
            // right
            self.isScrollLeft = false
        }
        else
        {
            // left
            self.isScrollLeft = true
        }
        
        if onceOnly
        {
            for cell in self.previewView!.visibleCells as! [CustomCell] {
                
                let dataImg = captureScreenFromView(imgv: cell.scrlView.zoomView!)
                sendImage(data: dataImg!)
                cell.scrlView.refresh()
                break
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrImages.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
    {
        var cell: CustomCell?
        
        cell = previewView?.dequeueReusableCell(withReuseIdentifier: "CustomCell", for: indexPath) as! CustomCell?
        
        if self.setScroll == true
        {
            cell?.scrlView.contentOffset = CGPoint(x: 0, y: 0)
            self.setScroll = false
        }
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapNavHide(sender:)))
        cell?.contentView.addGestureRecognizer(tapGesture)
        cell?.scrlView.delegateScale = self
        
        print(self.previewView?.frame as Any)
        cell?.scrlView.display(image: arrImages.object(at: indexPath.row) as! UIImage)
        
        return cell!
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if UIDevice.current.orientation.isLandscape {
            
            return CGSize(width: (self.view?.frame.size.width)!, height: (self.view?.frame.size.height)!)
            
        } else
        {
            return CGSize(width: (self.previewView?.frame.size.width)!, height: (self.previewView?.frame.size.height)!)
        }
    }
    func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool
    {
        return true
    }
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView)
    {
        self.lastContentOffset = scrollView.contentOffset
        
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView){
        
//        for cell in self.previewView!.visibleCells as! [CustomCell] {
//            
//            // for landscape
//            // cell.scrlView.refresh()
//        }
    }
    func tapNavHide(sender: UITapGestureRecognizer)
    {
        if (self.navigationController?.navigationBar.isHidden)!
        {
            isNavHide = false
            self.navigationController?.isNavigationBarHidden = false
            UIApplication.shared.isStatusBarHidden = false
        }
        else
        {
            isNavHide = true
            self.navigationController?.isNavigationBarHidden = true
            UIApplication.shared.isStatusBarHidden = true
            
        }
    }
    func sendContentOfSet( ContentX : CGFloat , ContentY : CGFloat , height : CGFloat , width : CGFloat)
    {
        if !appDelegateObject.isViewerSide
        {
            SendImageFrame( ContentX: ContentX, ContentY: ContentY, height: height, width: width)
        }
        
    }
    func SendScale(scale : CGFloat)
    {
        if appDelegateObject.isViewerSide
        {
            SendImageScale(zoomScale: scale)
        }
        
    }
    
    // send Image to reciever side
    
    fileprivate func sendImage(data:NSData) {
        
        ConnectionManager.sendEventForEach(.send) {
            
            let obj_dict = NSMutableDictionary()
            
            let imageData = data
            let base64String = imageData.base64EncodedString(options: .lineLength64Characters)
            
            obj_dict.setValue(base64String, forKey: "img")
            
            var strScroll = "right"
            if isScrollLeft
            {
                strScroll = "left"
            }
            obj_dict.setValue(strScroll, forKey: "swipeanimation")
            
            let dataExample : Data = NSKeyedArchiver.archivedData(withRootObject: obj_dict) as Data
            
            let struct_send = mydata(mpcSerialized:dataExample as Data)
            
            return["data":struct_send]
            
        }
    }
    
    // send image frame to reciever Side
    
    fileprivate func SendImageFrame( ContentX : CGFloat , ContentY : CGFloat, height : CGFloat , width : CGFloat) {
        
        ConnectionManager.sendEventForEach(.frame) {
            
            let obj_dict = NSMutableDictionary()
            
            
            obj_dict.setValue(ContentX, forKey: "contentX")
            obj_dict.setValue(ContentY, forKey: "contentY")
            obj_dict.setValue(height, forKey: "height")
            obj_dict.setValue(width, forKey: "width")
            
            let dataExample : Data = NSKeyedArchiver.archivedData(withRootObject: obj_dict) as Data
            
            let struct_send = frameStruct(mpcSerialized:dataExample as Data)
            
            return["frameData":struct_send]
            
        }
    }
    
    // send Image zoom Scale to reciever side
    
    fileprivate func SendImageScale(zoomScale : CGFloat) {
        
        ConnectionManager.sendEventForEach(.scale) {
            
            let obj_dict = NSMutableDictionary()
            
            obj_dict.setValue(zoomScale, forKey: "scale")
            
            let dataExample : Data = NSKeyedArchiver.archivedData(withRootObject: obj_dict) as Data
            
            let struct_send = scaleStruct(mpcSerialized:dataExample as Data)
            
            return["scaleData":struct_send]
            
        }
    }
    
    // send navigation hide or show data to reciever side
    
    fileprivate func SendHideNav(hide : String) {
        
        ConnectionManager.sendEventForEach(.nav) {
            
            let obj_dict = NSMutableDictionary()
            
            
            obj_dict.setValue(hide, forKey: "navHide")
            
            let dataExample : Data = NSKeyedArchiver.archivedData(withRootObject: obj_dict) as Data
            
            let struct_send = tapNav(mpcSerialized:dataExample as Data)
            
            return["navHide":struct_send]
            
        }
    }
    override func viewDidLayoutSubviews()
    {
        
    }
    
    override func viewWillLayoutSubviews() {
        
        if !onceOnly
        {
            for cell in self.previewView!.visibleCells as! [CustomCell] {
                
                cell.scrlView.refresh()
            }
        }
        
        // For landscape
        //        self.previewView?.collectionViewLayout.invalidateLayout()
        //        self.previewView?.reloadData()
        //        self.previewView?.setNeedsLayout()
        //        self.previewView?.performBatchUpdates({
        //
        //            for cell in self.previewView!.visibleCells as! [CustomCell] {
        //
        //                cell.scrlView.refresh()
        //            }
        //
        //        }, completion: { (anim) in
        //
        
        //        })
        
    }
    
    // MARK: Orientation method
    //    func rotated() {
    //        if UIDevice.current.orientation.isLandscape {
    //            print("Landscape")
    //
    //            let indexPath = NSIndexPath(item: currentPage, section: 0)
    //            if self.arrImages.count > 0
    //            {
    //                self.previewView?.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: false)
    //            }
    //            if !AppDelegate.appDelegate().isViewerSide
    //            {
    //                sendorientationChange(landscape: "landscape")
    //            }
    //            //self.previewView?.collectionViewLayout.invalidateLayout()
    //        } else {
    //            print("Portrait")
    //            let indexPath = NSIndexPath(item: currentPage, section: 0)
    //            if self.arrImages.count > 0
    //            {
    //                self.previewView?.scrollToItem(at: indexPath as IndexPath, at: .centeredHorizontally, animated: false)
    //            }
    //            if !AppDelegate.appDelegate().isViewerSide
    //            {
    //                sendorientationChange(landscape: "portait")
    //            }
    //
    //
    //            //self.previewView?.collectionViewLayout.invalidateLayout()
    //        }
    //    }
    
    fileprivate func sendorientationChange(landscape : String) {
        
        ConnectionManager.sendEventForEach(.orientation) {
            
            let obj_dict = NSMutableDictionary()
            
            
            obj_dict.setValue(landscape, forKey: "orientation")
            
            let dataExample : Data = NSKeyedArchiver.archivedData(withRootObject: obj_dict) as Data
            
            let struct_send = orientationchange(mpcSerialized:dataExample as Data)
            
            return["orientation":struct_send]
            
        }
    }
    
    override func viewWillTransition(to size: CGSize,
                                     with coordinator: UIViewControllerTransitionCoordinator)
    {
        coordinator.animate(alongsideTransition: { context in
            // do whatever with your context
            //            self.previewView?.collectionViewLayout.invalidateLayout()
            //            self.previewView?.frame = self.view.bounds
            //            self.previewView?.reloadData()
            // self.scrlView.refresh()
            
            context.viewController(forKey: UITransitionContextViewControllerKey.from)
            
        }, completion: nil)
    }
}




