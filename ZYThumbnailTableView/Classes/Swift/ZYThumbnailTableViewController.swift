//
//  ZYThumbnailTableViewController.swift
//  ZYThumbnailTableView
//
//  Created by lzy on 16/2/9.
//  Copyright © 2016年 lzy. All rights reserved.
//

import UIKit

typealias ConfigureTableViewCellBlock = () -> UITableViewCell?
typealias UpdateTableViewCellBlock = (cell: UITableViewCell, indexPath: NSIndexPath) -> Void
typealias SpreadCellAnimationBlick = (cell: UITableViewCell) -> Void
typealias CreateTopExpansionViewBlock = () -> UIView
typealias CreateBottomExpansionViewBlock = () -> UIView

let NOTIFY_NAME_DISMISS_PREVIEW = "NOTIFY_NAME_DISMISS_PREVIEW"


class ZYThumbnailTableViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {

    
//MARK: DEFINE
    private static let CELL_HEIGHT_DEFAULT = CGFloat(100.0)
    private static let EXPAND_THUMBNAILVIEW_AMPLITUDE_DEFAULT = CGFloat(10)
    let TYPE_EXPANSION_VIEW_TOP = "TYPE_EXPANSION_VIEW_TOP"
    let TYPE_EXPANSION_VIEW_BOTTOM = "TYPE_EXPANSION_VIEW_BOTTOM"
    
//MARK: PROPERTY
    var cellHeight: CGFloat = CELL_HEIGHT_DEFAULT
    //todo数据源要不要规定成字典数组?
    var dataList = NSArray()
    var cellReuseId = "diyCell"
    
    private var mainTableView: UITableView!
    private var clickIndexPathRow: Int?
    private var spreadCellHeight: CGFloat?
    private var cellDictionary: NSMutableDictionary = NSMutableDictionary()
    private var thumbnailView: UIView!
    private var thumbnailViewCanPan = true
    private var animator: UIDynamicAnimator!
    private var expandAmplitude = EXPAND_THUMBNAILVIEW_AMPLITUDE_DEFAULT
    
    
//MARK: BLOCKS
    lazy var configureTableViewCellBlock: ConfigureTableViewCellBlock = {
        return {
            assertionFailure("ERROR: You must configure the configureTableViewCellBlock")
            return nil
        }
    }()
    
    lazy var updateTableViewCellBlock: UpdateTableViewCellBlock = {
        return {
            print("ERROR: You must configure the updateTableViewCellBlock")
        }
    }()
    
    lazy var spreadCellAnimationBlock: SpreadCellAnimationBlick = {
        return {
            assertionFailure("ERROR: You must configure the spreadCellAnimationBlock")
        }
    }()
    
    lazy var createTopExpansionViewBlock: CreateTopExpansionViewBlock = {
        return {
            assertionFailure("ERROR: You must configure the createTopExpansionViewBlock")
            return UIView()
        }
    }()
    
    lazy var createBottomExpansionViewBlock: CreateBottomExpansionViewBlock = {
        return {
            assertionFailure("ERROR: You must configure the createBottomExpansionViewBlock")
            return UIView()
        }
    }()
    
//MARK: FUNCTION
    override func viewDidLoad() {
        super.viewDidLoad()

        self.navigationItem.title = "ZYThumbnailTableView"
        self.mainTableView = UITableView(frame: self.view.frame)
        
        configureTableView()
        
        registerNotification()
        
        mainTableView.backgroundColor = UIColor.whiteColor()
        
        let titleView = UILabel(frame: CGRectMake(0, 0, 200, 44))
        titleView.text = "woshibiaoti"
        titleView.textAlignment = .Center
        titleView.font = UIFont.systemFontOfSize(20.0);
        //503f39
        titleView.textColor = UIColor(red: 63/255.0, green: 47/255.0, blue: 41/255.0, alpha: 1.0)
        self.navigationItem.titleView = titleView
    }
    
    override func viewDidLayoutSubviews() {
        self.mainTableView.updateHeight(self.view.frame.height)
    }
    
    deinit {
        resignNotification()
    }
    
    func registerNotification() {
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "dismissPreview", name: NOTIFY_NAME_DISMISS_PREVIEW, object: nil)
    }
    
    func resignNotification() {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    func configureTableView() {
        self.view.addSubview(mainTableView)
        
//        mainTableView.backgroundColor = UIColor(red: 53/255.0, green: 72/255.0, blue: 83/255.0, alpha: 1.0)
        mainTableView.backgroundColor = UIColor(red: 244/255.0, green: 244/255.0, blue: 244/255.0, alpha: 1.0)
        mainTableView.delegate = self
        mainTableView.dataSource = self
        mainTableView.separatorStyle = .None
        mainTableView.reloadData()
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dataList.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let identifier = cellReuseId
        var cell = tableView.dequeueReusableCellWithIdentifier(identifier)
        if cell == nil {
            //配置cell的Block
            cell = configureTableViewCellBlock()
            cell?.selectionStyle = .None
        }
        guard let nonNilcell = cell else {
            assertionFailure("ERROR: cell can not be nil, plase config cell aright with configureTableViewCellBlock")
            return UITableViewCell(frame: CGRectZero)
        }
        //这里updateCell
        updateTableViewCellBlock(cell: nonNilcell, indexPath: indexPath)
        
        //记录所有cell,didSelected后拿出来配置
        cellDictionary.setValue(nonNilcell, forKey: "\(indexPath.row)")
        return nonNilcell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        if indexPath.row == clickIndexPathRow {
            guard let nonNilspreadCellHeight = spreadCellHeight else {
                return cellHeight
            }
            return nonNilspreadCellHeight
        }
        return cellHeight
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = cellDictionary.valueForKey("\(indexPath.row)") as? UITableViewCell
        if let nonNilSelectedCell = selectedCell {
            //计算高度
            calculateCell(nonNilSelectedCell, indexPath: indexPath)
            
            //记录点击cell的index
            clickIndexPathRow = indexPath.row
            
            //update Cell
            mainTableView.beginUpdates()
            mainTableView.endUpdates()
            
            //动画纠正thumbnailView
            let tempConvertRect = mainTableView.convertRect(nonNilSelectedCell.frame, toView: self.view)
            var thumbnailViewFrame = self.thumbnailView.frame
            thumbnailViewFrame.origin.y = tempConvertRect.origin.y
            UIView.animateWithDuration(0.3, animations: { () -> Void in
                self.thumbnailView.frame = thumbnailViewFrame
            })
        } else {
            print("ERROR: can not find the cell in cellDictionary")
        }
    }
    
    func calculateCell(cell: UITableViewCell, indexPath: NSIndexPath) {
        let tempConstraint = NSLayoutConstraint(item: cell.contentView,
                                           attribute: NSLayoutAttribute.Width,
                                           relatedBy: NSLayoutRelation.Equal,
                                              toItem: nil,
                                           attribute: NSLayoutAttribute.NotAnAttribute,
                                          multiplier: 1.0,
                                            constant: CGRectGetWidth(mainTableView.frame))
        cell.contentView.addConstraint(tempConstraint)
        let size = cell.contentView.systemLayoutSizeFittingSize(UILayoutFittingCompressedSize)
        cell.contentView.removeConstraint(tempConstraint)
        spreadCellHeight = size.height
        previewCell(cell, indexPatch: indexPath)
    }
    
    func previewCell(cell: UITableViewCell, indexPatch: NSIndexPath) {
        //create previewCover
        let previewCover = UIView(frame: mainTableView.frame)
        previewCover.backgroundColor = UIColor.blackColor()
//        previewCover.image = BlurUtil.applyBlurOnImage(UIImage(named: "bg1"), withRadius: 0.8)
        //todo 修改透明度
        previewCover.alpha = 0.9
        let tapGesture = UITapGestureRecognizer(target: self, action: "tapPreviewCover:")
        previewCover.addGestureRecognizer(tapGesture)
        self.view.insertSubview(previewCover, aboveSubview: mainTableView)
        //animator
        animator = UIDynamicAnimator(referenceView: previewCover)
        
        //create thumbnailView
        let convertRect = mainTableView.convertRect(cell.frame, toView: self.view)
        let thumbnailLocationY = CGRectGetMinY(convertRect)
        let thumbnailView = UIView(frame: CGRectMake(0, thumbnailLocationY, mainTableView.bounds.width, cellHeight))
        self.thumbnailView = thumbnailView
        thumbnailView.backgroundColor = UIColor.whiteColor()
        let panGesture = UIPanGestureRecognizer(target: self, action: "panThumbnailView:")
        thumbnailView.addGestureRecognizer(panGesture)
        previewCover.addSubview(thumbnailView)
        
        //can not copy object in swift, we can only create a new one with configureTableViewCellBlock
        let previewCell = configureTableViewCellBlock()
        previewCell?.selectionStyle = .None
        updateTableViewCellBlock(cell: previewCell!, indexPath: indexPatch)
        
        //layout cell contentView in thumbnailView with VFL
        let contentView = previewCell!.contentView
        contentView.translatesAutoresizingMaskIntoConstraints = false
        let views = ["contentView":contentView]
        thumbnailView.addSubview(contentView)
        thumbnailView.clipsToBounds = true
        
        //dont contain the bottom constraint here
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView]|", options: NSLayoutFormatOptions.AlignAllCenterX, metrics: nil, views: views))
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: .AlignAllCenterY, metrics: nil, views: views))
        
        //spread thumbnailView
        guard let nonNilSpreadCellHeight = spreadCellHeight else {
            print("ERROR: spreadCellHeight is nil")
            return
        }
        var toFrame = thumbnailView.frame
        toFrame.size.height = nonNilSpreadCellHeight
        UIView.animateWithDuration(0.201992, animations: { () -> Void in
            thumbnailView.frame = toFrame
            }) { (finish) -> Void in
                //Overflow screen
                self.handleOverFlowScreen(self.thumbnailView)
        }
    }
    
    func tapPreviewCover(gesture: UITapGestureRecognizer) {
        dismissPreview()
    }
    
    func dismissPreview() {
        clickIndexPathRow = nil
        //todo 这里给开发者一个选择，要动画过程还是立即完成
        //        mainTableView.reloadData()
        mainTableView.beginUpdates()
        mainTableView.endUpdates()
        UIView.animateWithDuration(0.301992, animations: { () -> Void in
            self.thumbnailView.superview?.alpha = 0
            }) { (finish) -> Void in
                self.thumbnailView.superview?.removeFromSuperview()
                self.thumbnailViewCanPan = true
        }
    }
    
    func panThumbnailView(gesture: UIPanGestureRecognizer) {
        let thumbnailViewHeight = gesture.view!.bounds.height
        let gestureTranslation = gesture.translationInView(gesture.view)
        let thresholdValue = thumbnailViewHeight * 0.3
        if thumbnailViewCanPan {
            if gestureTranslation.y > thresholdValue {
                layoutTopView()
                thumbnailViewCanPan = false
            } else if gestureTranslation.y < -thresholdValue {
                layoutBottomView()
                thumbnailViewCanPan = false
            }
        }
        //gesture state
        switch gesture.state {
        case .Began:
            animator.removeAllBehaviors()
            break
        case .Ended:
            break
        default:
            break
        }
    }
    
    func shock(view: UIView, type: String) {
        //超出tableview范围不shock
        var expandShockAmplitude: CGFloat!
        let convertRect = view.superview?.convertRect(view.frame, toView: self.view)
        guard let nonNilConvertRect = convertRect else {
            print("ERROR: convertRect error")
            return
        }
        if type == TYPE_EXPANSION_VIEW_TOP {
            expandShockAmplitude = self.expandAmplitude
            if CGRectGetMaxY(nonNilConvertRect) > CGRectGetHeight(self.view.frame) {
                //超出下面
                return
            }
        } else if (type == TYPE_EXPANSION_VIEW_BOTTOM) {
            expandShockAmplitude = -self.expandAmplitude
            if CGRectGetMinY(nonNilConvertRect) < 0 {
                //超出上面
                return
            }
        } else {
            print("ERROR: function shock parameter illegal")
            return
        }
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) { () -> Void in
            NSThread.sleepForTimeInterval(0.1)
            var snapPoint = view.center
            snapPoint.y += expandShockAmplitude
            var snapBehavior = UISnapBehavior(item: view, snapToPoint: snapPoint)
            snapBehavior.damping = 0.9
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.animator.addBehavior(snapBehavior)
            })
            
            NSThread.sleepForTimeInterval(0.1)
            
            snapPoint.y -= expandShockAmplitude
            snapBehavior = UISnapBehavior(item: view, snapToPoint: snapPoint)
            snapBehavior.damping = 0.9
            dispatch_async(dispatch_get_main_queue(), { () -> Void in
                self.animator.removeAllBehaviors()
                self.animator.addBehavior(snapBehavior)
            })
            
        }
    }
    
    func layoutTopView() {
        let contentView = thumbnailView.subviews.first
        let topView = createTopExpansionViewBlock()
        topView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.addSubview(topView)
        let views = ["contentView":contentView!, "topView":topView]
        
        //remove all constraints
        _ = thumbnailView.constraints.map { $0.active = false }
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[topView]-0-[contentView]|", options: .AlignAllCenterX, metrics: nil, views: views))
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[topView]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views))
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views))
        
        //update Frame
        topView.updateOriginY(-topView.bounds.height)
        UIView.animateWithDuration(0.201992, animations: { () -> Void in
            self.thumbnailView.updateHeight(self.thumbnailView.bounds.height + topView.bounds.height)
                contentView?.updateOriginY(topView.bounds.height)
                topView.updateOriginY(0)
            }) { (finish) -> Void in
                //Overflow screen
                self.handleOverFlowScreen(self.thumbnailView)
        }
        //shock
        shock(thumbnailView, type: TYPE_EXPANSION_VIEW_TOP)
    }
    
    func layoutBottomView() {
        let contentView = thumbnailView.subviews.first
        let bottomView = createBottomExpansionViewBlock()
        bottomView.translatesAutoresizingMaskIntoConstraints = false
        thumbnailView.addSubview(bottomView)
        let views = ["contentView":contentView!, "bottomView":bottomView]
        
        //remove all constraints
        _ = thumbnailView.constraints.map { $0.active = false }
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("V:|[contentView]-0-[bottomView]|", options: .AlignAllCenterX, metrics: nil, views: views))
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[bottomView]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views))
        thumbnailView.addConstraints(NSLayoutConstraint.constraintsWithVisualFormat("H:|[contentView]|", options: NSLayoutFormatOptions.AlignAllCenterY, metrics: nil, views: views))
        
        //update Frame
        UIView.animateWithDuration(0.201992, animations: { () -> Void in
            self.thumbnailView.updateHeight(self.thumbnailView.bounds.height + bottomView.bounds.height)
            self.thumbnailView.updateOriginY(self.thumbnailView.frame.origin.y - bottomView.bounds.height)
            }) { (finish) -> Void in
                //Overflow screen
                if self.thumbnailView.frame.origin.y < 0 {
                    UIView.animateWithDuration(0.201992, animations: { () -> Void in
                        self.thumbnailView.updateOriginY(0)
                    })
                }
        }
        //shock
        shock(thumbnailView, type: TYPE_EXPANSION_VIEW_BOTTOM)
    }
    
    func handleOverFlowScreen(handleView: UIView) {
        let keyWindow = UIApplication.sharedApplication().keyWindow
        let convertRect = handleView.superview?.convertRect(handleView.frame, toView: keyWindow)
        guard let nonNilConvertRect = convertRect else {
            print("ERROR: can not convert Rect error")
            return
        }
        let diff = CGRectGetMaxY(nonNilConvertRect) - CGRectGetMaxY(UIScreen.mainScreen().bounds)
        if diff > 0 {
            UIView.animateWithDuration(0.201992, animations: { () -> Void in
                handleView.updateOriginY(handleView.frame.origin.y - diff)
            })
        }
    }
    
    func movingPath(startPoint: CGPoint, keyPoints: CGPoint...) -> UIBezierPath {
        let path = UIBezierPath()
        path.moveToPoint(startPoint)
        for point in keyPoints {
            path.addLineToPoint(point)
        }
        return path
    }
    
    func applyBlurOnImage(image: UIImage, blurRadius: CGFloat) -> UIImage {
        var boxSize = UInt32(blurRadius * 100)
        boxSize -= (boxSize % 2) + 1
        
        let rawImage = image.CGImage
        
        var inBuffer = vImage_Buffer()
        var outBuffer = vImage_Buffer()
        var error = vImage_Error()
        var pixelBuffer = UnsafeMutablePointer<Void>()
        
        let inProvider = CGImageGetDataProvider(rawImage)! as CGDataProviderRef
        let inBitmapData = CGDataProviderCopyData(inProvider)
        
        inBuffer.width =  UInt(CGImageGetWidth(rawImage))
        inBuffer.height = UInt(CGImageGetHeight(rawImage))
        inBuffer.rowBytes = CGImageGetBytesPerRow(rawImage)
        inBuffer.data = UnsafeMutablePointer<Void>(CFDataGetBytePtr(inBitmapData))
        
        pixelBuffer = malloc(CGImageGetBytesPerRow(rawImage) * CGImageGetHeight(rawImage))
        
        outBuffer.data = pixelBuffer
        outBuffer.width = UInt(CGImageGetWidth(rawImage))
        outBuffer.height = UInt(CGImageGetHeight(rawImage))
        outBuffer.rowBytes = CGImageGetBytesPerRow(rawImage)
        
        
        let flags:vImage_Flags = UInt32(kvImageNoFlags)
        error = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, nil, 0, 0, boxSize, boxSize, nil, flags)
        
        if error != 0 {
            print("error from convolution \(error)")
        }
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let ctx = CGBitmapContextCreate(outBuffer.data, Int(outBuffer.width), Int(outBuffer.height), 8, outBuffer.rowBytes, colorSpace, CGImageGetBitmapInfo(rawImage).rawValue)
        
        let imageRef = CGBitmapContextCreateImage(ctx)
        let returnImage = UIImage(CGImage: imageRef!)
        
        //clean up
        free(pixelBuffer)
        
        return returnImage
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}


//MARK: UIView extension
extension UIView {
    func updateOriginX(originX: CGFloat) {
        self.frame = CGRectMake(originX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
    }
    
    func updateOriginY(originY: CGFloat) {
        self.frame = CGRectMake(self.frame.origin.x, originY, self.frame.size.width, self.frame.size.height);
    }
    
    func updateCenterX(centerX: CGFloat) {
        self.center = CGPointMake(centerX, self.center.y);
    }
    
    func updateCenterY(centerY: CGFloat) {
        self.center = CGPointMake(self.center.x, centerY);
    }
    
    func updateWidth(width: CGFloat) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, width, self.frame.size.height);
    }
    
    func updateHeight(height: CGFloat) {
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, height);
    }
    
    func screenShot() -> UIImage {
        UIGraphicsBeginImageContext(self.bounds.size)
        if self.respondsToSelector("drawViewHierarchyInRect:afterScreenUpdates:") {
            self.drawViewHierarchyInRect(self.bounds, afterScreenUpdates: false)
        } else {
            //着色
            self.layer.renderInContext(UIGraphicsGetCurrentContext()!)
        }
        
        var screenShotImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        //可以选择压缩下图片
        let imageData = UIImageJPEGRepresentation(screenShotImage, 0.7)
        screenShotImage = UIImage(data: imageData!)
        return screenShotImage
    }
    
}



