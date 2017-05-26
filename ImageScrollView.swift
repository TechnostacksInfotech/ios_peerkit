//
//  ImageScrollView.swift
//  Beauty
//
//  Created by Nguyen Cong Huy on 1/19/16.
//  Copyright © 2016 Nguyen Cong Huy. All rights reserved.
//

import UIKit

protocol scaleDelegate {
    
    func SendScale(scale : CGFloat)
    func sendContentOfSet( ContentX : CGFloat , ContentY : CGFloat , height : CGFloat , width : CGFloat)
}
open class ImageScrollView: UIScrollView {
    
    
    var delegateScale : scaleDelegate?
    
    static let kZoomInFactorFromMinWhenDoubleTap: CGFloat = 2
    
    var zoomView: UIImageView? = nil
    var imageSize: CGSize = CGSize.zero
    fileprivate var pointToCenterAfterResize: CGPoint = CGPoint.zero
    fileprivate var scaleToRestoreAfterResize: CGFloat = 1.0
    var maxScaleFromMinScale: CGFloat = 3.0
   
    override open var frame: CGRect {
        willSet {
            if frame.equalTo(newValue) == false && newValue.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                prepareToResize()
            }
        }
        
        didSet {
            if frame.equalTo(oldValue) == false && frame.equalTo(CGRect.zero) == false && imageSize.equalTo(CGSize.zero) == false {
                recoverFromResizing()
            }
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        initialize()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        initialize()
    }
    
    fileprivate func initialize() {
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        bouncesZoom = true
        decelerationRate = UIScrollViewDecelerationRateFast
        delegate = self
    }
    
    func adjustFrameToCenter() {
        
        guard zoomView != nil else {
            return
        }
        
        var frameToCenter = zoomView!.frame
        
        // center horizontally
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        }
        else {
            frameToCenter.origin.x = 0
        }
        
        // center vertically
        if frameToCenter.size.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        }
        else {
            frameToCenter.origin.y = 0
        }
       // print(zoomScale)
       
        zoomView!.frame = frameToCenter
    }
    
    fileprivate func prepareToResize()
    {
        let boundsCenter = CGPoint(x: bounds.midX, y: bounds.midY)
        pointToCenterAfterResize = convert(boundsCenter, to: zoomView)
        
        scaleToRestoreAfterResize = zoomScale
        
        // If we're at the minimum zoom scale, preserve that by returning 0, which will be converted to the minimum
        // allowable scale when the scale is restored.
        if scaleToRestoreAfterResize <= minimumZoomScale + CGFloat(FLT_EPSILON) {
            scaleToRestoreAfterResize = 0
        }
    }
    
    fileprivate func recoverFromResizing() {
        setMaxMinZoomScalesForCurrentBounds()
        
        // restore zoom scale, first making sure it is within the allowable range.
        let maxZoomScale = max(minimumZoomScale, scaleToRestoreAfterResize)
        zoomScale = min(maximumZoomScale, maxZoomScale)
        
        // restore center point, first making sure it is within the allowable range.
        
        // convert our desired center point back to our own coordinate space
        let boundsCenter = convert(pointToCenterAfterResize, to: zoomView)
        
        // calculate the content offset that would yield that center point
        var offset = CGPoint(x: boundsCenter.x - bounds.size.width/2.0, y: boundsCenter.y - bounds.size.height/2.0)
        
        // restore offset, adjusted to be within the allowable range
        let maxOffset = maximumContentOffset()
        let minOffset = minimumContentOffset()
        
        var realMaxOffset = min(maxOffset.x, offset.x)
        offset.x = max(minOffset.x, realMaxOffset)
        
        realMaxOffset = min(maxOffset.y, offset.y)
        offset.y = max(minOffset.y, realMaxOffset)
        
        contentOffset = offset
    }
    
    fileprivate func maximumContentOffset() -> CGPoint {
        return CGPoint(x: contentSize.width - bounds.width,y:contentSize.height - bounds.height)
    }
    
    fileprivate func minimumContentOffset() -> CGPoint {
        return CGPoint.zero
    }

    // MARK: - Display image
    
    open func display(image: UIImage) {

        if let zoomView = zoomView {
            
            if AppDelegate.appDelegate().isViewerSide
            {
                let when = DispatchTime.now() + 0.2 // change 2 to desired number of seconds
                DispatchQueue.main.asyncAfter(deadline: when) {
                    // Your code with delay
                    self.removeImage(imageV: zoomView)
                }
            }
            else
            {
                self.removeImage(imageV: zoomView)
            }
            
        }
        
        print(self.frame)
        
        zoomView = UIImageView(image: image)
        zoomView!.isUserInteractionEnabled = true
        zoomView?.backgroundColor = UIColor.clear
        self.addSubview(self.zoomView!)
        
        if AppDelegate.appDelegate().isViewerSide
        {
            let transition = CATransition()
            
            transition.duration = 0.3
            
            transition.type = kCATransitionMoveIn
            
            if AppDelegate.appDelegate().strscrollPosition == "left"
            {
                transition.subtype = kCATransitionFromLeft
            }
            else
            {
                transition.subtype = kCATransitionFromRight
            }
            self.zoomView?.layer.add(transition, forKey: kCATransition)
        }
        
        let tapdoubleGesture = UITapGestureRecognizer(target: self, action: #selector(ImageScrollView.doubleTapGestureRecognizer(_:)))
        tapdoubleGesture.numberOfTapsRequired = 2
        zoomView!.addGestureRecognizer(tapdoubleGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(ImageScrollView.singleTapGesture(_:)))
        tapGesture.numberOfTapsRequired = 1
        zoomView!.addGestureRecognizer(tapGesture)
        
        tapGesture.require(toFail: tapdoubleGesture)
        
        configureImageForSize(image.size)
    }
    
    func removeImage(imageV:UIImageView)
    {
        imageV.removeFromSuperview()
    }
    
    func singleTapGesture(_ gesture : UIGestureRecognizer)
    {
        NotificationCenter.default.post(name: NSNotification.Name(rawValue: "taponView"), object: nil)
    }
    
    fileprivate func configureImageForSize(_ size: CGSize) {
        imageSize = size
        contentSize = imageSize
        setMaxMinZoomScalesForCurrentBounds()
        zoomScale = minimumZoomScale
        contentOffset = CGPoint.zero
    }
    
    fileprivate func setMaxMinZoomScalesForCurrentBounds() {
        // calculate min/max zoomscale
        let xScale = bounds.width / imageSize.width    // the scale needed to perfectly fit the image width-wise
        let yScale = bounds.height / imageSize.height   // the scale needed to perfectly fit the image height-wise
        
        // fill width if the image and phone are both portrait or both landscape; otherwise take smaller scale
        let imagePortrait = imageSize.height > imageSize.width
        let phonePortrait = bounds.height >= bounds.width
        var minScale = (imagePortrait == phonePortrait) ? xScale : min(xScale, yScale)
        
        let maxScale = maxScaleFromMinScale*minScale
        
        // don't let minScale exceed maxScale. (If the image is smaller than the screen, we don't want to force it to be zoomed.)
        if minScale > maxScale {
            minScale = maxScale
        }
        
        maximumZoomScale = maxScale
        minimumZoomScale = minScale * 0.999 // the multiply factor to prevent user cannot scroll page while they use this control in UIPageViewController
    }
    
    // MARK: - Gesture
    
    func doubleTapGestureRecognizer(_ gestureRecognizer: UIGestureRecognizer) {
        // zoom out if it bigger than middle scale point. Else, zoom in
        if zoomScale >= maximumZoomScale / 2.0 {
            setZoomScale(minimumZoomScale, animated: true)
        }
        else {
            let center = gestureRecognizer.location(in: gestureRecognizer.view)
            let zoomRect = zoomRectForScale(ImageScrollView.kZoomInFactorFromMinWhenDoubleTap * minimumZoomScale, center: center)
            zoom(to: zoomRect, animated: true)
        }
    }
    
    fileprivate func zoomRectForScale(_ scale: CGFloat, center: CGPoint) -> CGRect {
        var zoomRect = CGRect.zero
        
        // the zoom rect is in the content view's coordinates.
        // at a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
        // as the zoom scale decreases, so more content is visible, the size of the rect grows.
        zoomRect.size.height = frame.size.height / scale
        zoomRect.size.width  = frame.size.width  / scale
        
        // choose an origin so as to get the right center.
        zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0)
        zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0)
        
        return zoomRect
    }
    
    open func refresh() {
        if let image = zoomView?.image {
            display(image: image)
        }
    }
}

extension ImageScrollView: UIScrollViewDelegate{
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        
        return zoomView
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
     
        delegateScale?.SendScale(scale: scrollView.zoomScale)
        adjustFrameToCenter()
    }
    public func scrollViewDidScroll(_ scrollView: UIScrollView){
        
        
            delegateScale?.sendContentOfSet( ContentX: scrollView.contentOffset.x, ContentY: scrollView.contentOffset.y, height: scrollView.contentSize.height, width: scrollView.contentSize.width)
    }
    
}
