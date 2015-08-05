import UIKit

let messageFontSize: CGFloat = 14
let toolBarMinHeight: CGFloat = 44
let textViewMaxHeight: (portrait: CGFloat, landscape: CGFloat) = (portrait: 272, landscape: 90)

class ReplViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UITextViewDelegate {
    
    let history: History
    var textInputView: UITextView!
    var textInputCell: UITableViewCell!
    var nextHistoryCell: HistoryTableViewCell!
    var tableView: UITableView!

    var evalButton: UIButton!
    var rotating = false
    var textFieldHeightLayoutConstraint: NSLayoutConstraint!
    var currentKeyboardHeight: CGFloat!
    var initialized = false;
    
    
    override var inputAccessoryView: UIView! {
        get {
            let edh = EDHInputAccessoryView(textView: textInputView)
            return edh
        }
    }
    
    func createTextView() -> UITextView {
        
            let textView = InputTextView(frame: CGRectMake(0, 0, view.bounds.width, toolBarMinHeight-0.5)) // CGRectZero)
            textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
            textView.font = UIFont(name: "Menlo", size: messageFontSize)
            textView.backgroundColor = UIColor(white: 250/255, alpha: 1)
            textView.font = UIFont(name: "Menlo", size: messageFontSize)
            textView.layer.borderColor = UIColor(red: 200/255, green: 200/255, blue: 205/255, alpha:1).CGColor
            textView.layer.borderWidth = 0.5
            textView.layer.cornerRadius = 5
            textView.autocorrectionType = UITextAutocorrectionType.No;
            textView.autocapitalizationType = UITextAutocapitalizationType.None;
            textView.delegate = self
            textView.keyboardType = .NumbersAndPunctuation

            textView.text = "(def hello \"Hello World\")"
            return textView
        }
//    }
    
    required init(coder aDecoder: NSCoder) {
        self.history = History()
        
        super.init(nibName: nil, bundle: nil)
        
        //hidesBottomBarWhenPushed = true
        self.currentKeyboardHeight = 0.0;
    }
    
    override func canBecomeFirstResponder() -> Bool {
        return true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        history.loadedMessages = [
        ]
        
        let whiteColor = UIColor.whiteColor()
        view.backgroundColor = whiteColor
        
        // view.bounds.height-80
        tableView = UITableView(frame: CGRect(x: 0, y: 20, width: view.bounds.width, height: view.bounds.height-20), style: .Plain)
        
        tableView.autoresizingMask = .FlexibleWidth | .FlexibleHeight
        tableView.backgroundColor = whiteColor
        let edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: toolBarMinHeight, right: 0)
        tableView.contentInset = edgeInsets
        tableView.dataSource = self
        tableView.delegate = self
        tableView.keyboardDismissMode = .Interactive
        tableView.estimatedRowHeight = 44
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.separatorStyle = .None
        view.addSubview(tableView)
        
        // createToolBar()
        textInputView = createTextView()
        let lastSection = 0
        tableView.beginUpdates()
        tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation: .Automatic)
        tableView.insertRowsAtIndexPaths([
            NSIndexPath(forRow: 0, inSection: 0)
            ], withRowAnimation: .Automatic)
        tableView.endUpdates()
        
        tableViewScrollToBottomAnimated(false)
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        notificationCenter.addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "keyboardDidShow:", name: UIKeyboardDidShowNotification, object: nil)
        notificationCenter.addObserver(self, selector: "menuControllerWillHide:", name: UIMenuControllerWillHideMenuNotification, object: nil) // #CopyMessage
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        
        appDelegate.setPrintCallback { (message: String!) -> Void in
            dispatch_async(dispatch_get_main_queue()) {
                self.loadMessage(true, text: message)
            }
        }

        NSLog("Initializing...");
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.initializeJavaScriptEnvironment()
            
            dispatch_async(dispatch_get_main_queue()) {
                // mark ready
                NSLog("Ready");
                self.initialized = true;
                // TODO andy
                // self.evalButton.enabled = self.textView.hasText()
            }
        }
        
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    override func viewDidAppear(animated: Bool)  {
        super.viewDidAppear(animated)
        //tableView.flashScrollIndicators()
    }
    
    override func viewWillDisappear(animated: Bool)  {
        super.viewWillDisappear(animated)
        //chat.draft = textView.text
    }
    
    // This gets called a lot. Perhaps there's a better way to know when `view.window` has been set?
   override func viewDidLayoutSubviews()  {
        super.viewDidLayoutSubviews()
        
        if true {
            //textView.text = chat.draft
            //chat.draft = ""
            textViewDidChange(textInputView)
            textInputView.becomeFirstResponder()
        }
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return history.loadedMessages.count + 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == history.loadedMessages.count {
            return 1 // TODO grow...
        }
        return history.loadedMessages[section].count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let section = indexPath.section
        let row = indexPath.row
        let isText = section == history.loadedMessages.count
        let isFirst = textInputCell == nil // && section == 0
        if isFirst {
            textInputCell = UITableViewCell(style: .Default, reuseIdentifier: "textInputCell*")
            textInputCell.addSubview(textInputView)
            // TODO
            
            return textInputCell
        }
        else if isText {
            return textInputCell
        }
        else { // if nextHistoryCell == nil {
            let cellIdentifier = NSStringFromClass(HistoryTableViewCell)
            nextHistoryCell = tableView.dequeueReusableCellWithIdentifier(cellIdentifier) as! HistoryTableViewCell!
            if nextHistoryCell == nil {
                nextHistoryCell = HistoryTableViewCell(style: .Default, reuseIdentifier: cellIdentifier)
                // Add gesture recognizers #CopyMessage
                let action: Selector = "messageShowMenuAction:"
                let doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: action)
                doubleTapGestureRecognizer.numberOfTapsRequired = 2
                nextHistoryCell.messageLabel.addGestureRecognizer(doubleTapGestureRecognizer)
                nextHistoryCell.messageLabel.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: action))
            }
            let message = history.loadedMessages[section][row]
            nextHistoryCell.configureWithMessage(message)
            return nextHistoryCell
        }
    }
    
    // Reserve row selection #CopyMessage
    func tableView(tableView: UITableView, willSelectRowAtIndexPath indexPath: NSIndexPath) -> NSIndexPath? {
        return nil
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func textView(textView: UITextView, shouldChangeTextInRange range: NSRange, replacementText text: String) -> Bool {
        if (text == "\n" && range.location == count(textView.text) && self.initialized) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            if (appDelegate.isReadable(textView.text)) {
                dispatch_async(dispatch_get_main_queue()) {
                  self.sendAction();
                }
                return false;
            }
        }
        return true;
    }
    
    func textViewDidChange(textView: UITextView) {
        self.tableView.beginUpdates()
        updateTextViewHeight()
        self.tableView.endUpdates()
        // evalButton.enabled = self.initialized && textView.hasText()
    }
    
    func keyboardWillShow(notification: NSNotification) {
        
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        let insetOld = tableView.contentInset
        let insetChange = insetNewBottom - insetOld.bottom
        let overflow = tableView.contentSize.height - (tableView.frame.height-insetOld.top-insetOld.bottom)
        
        let duration = (userInfo[UIKeyboardAnimationDurationUserInfoKey] as! NSNumber).doubleValue
        let animations: (() -> Void) = {
            if !(self.tableView.tracking || self.tableView.decelerating) {
                // Move content with keyboard
                if overflow > 0 {                   // scrollable before
                    self.tableView.contentOffset.y += insetChange
                    if self.tableView.contentOffset.y < -insetOld.top {
                        self.tableView.contentOffset.y = -insetOld.top
                    }
                } else if insetChange > -overflow { // scrollable after
                    self.tableView.contentOffset.y += insetChange + overflow
                }
            }
        }
        if duration > 0 {
            let options = UIViewAnimationOptions(UInt((userInfo[UIKeyboardAnimationCurveUserInfoKey] as! NSNumber).integerValue << 16)) // http://stackoverflow.com/a/18873820/242933
            UIView.animateWithDuration(duration, delay: 0, options: options, animations: animations, completion: nil)
        } else {
            animations()
        }
    }
    
    func keyboardDidShow(notification: NSNotification) {
        
        let userInfo = notification.userInfo as NSDictionary!
        let frameNew = (userInfo[UIKeyboardFrameEndUserInfoKey] as! NSValue).CGRectValue()
        let insetNewBottom = tableView.convertRect(frameNew, fromView: nil).height
        self.currentKeyboardHeight = frameNew.height
        
        // Inset `tableView` with keyboard
        let contentOffsetY = tableView.contentOffset.y
        tableView.contentInset.bottom = insetNewBottom
        tableView.scrollIndicatorInsets.bottom = insetNewBottom
        // Prevents jump after keyboard dismissal
        if self.tableView.tracking || self.tableView.decelerating {
            tableView.contentOffset.y = contentOffsetY
        }
    }
    
    func updateTextViewHeight() -> CGFloat {
        if false {
            return CGFloat(0)
        }
        let minHeight = CGFloat(44)
        let maxHeight = self.view.frame.height
            - self.topLayoutGuide.length
            - currentKeyboardHeight
            + textInputView.frame.height
            - textInputView.textContainerInset.top
            - textInputView.textContainerInset.bottom
            - 20
        /*
        if textFieldHeightLayoutConstraint != nil {
            if !(textFieldHeightLayoutConstraint.constant + heightChange > maxHeight){
                //ceil because of small irregularities in heightChange
                self.textFieldHeightLayoutConstraint.constant = ceil(heightChange + oldHeight)
                
                //In order to ensure correct placement of text inside the textfield:
                self.textInputView.setContentOffset(CGPoint.zeroPoint, animated: false)
                //To ensure update of placement happens immediately
                self.textInputView.layoutIfNeeded()
                
            }
            else{
                self.textFieldHeightLayoutConstraint.constant = maxHeight
            }
        } */
        let height = ceil(textInputView.contentSize.height) // ceil to avoid decimal
        let minHeightPlus5 = minHeight + 5
        if height < minHeightPlus5 {
            // min cap, + 5 to avoid tiny height difference at min height
            return minHeight
        }
        else if height - maxHeight > 0 { // max cap
            return maxHeight
        }
        return height
    }
    
    func loadMessage(incoming: Bool, text: String) {
        
        if (text != "\n") {
            // NSLog("load: %@", text);
            
            history.loadedMessages.append([Message(incoming: incoming, text: text)])
            
            let lastSection = tableView.numberOfSections() - 1
            tableView.beginUpdates()
            tableView.insertSections(NSIndexSet(index: lastSection), withRowAnimation: .Automatic)
            tableView.insertRowsAtIndexPaths([
                NSIndexPath(forRow: 0, inSection: lastSection)
                ], withRowAnimation: .Automatic)
            tableView.endUpdates()
            
            tableViewScrollToBottomAnimated(false)
        }
    }
    
    func sendAction() {
        // Autocomplete text before sending #hack
        //textView.resignFirstResponder()
        //textView.becomeFirstResponder()
        
        let textToEvaluate = textInputView.text
        
        loadMessage(false, text: textToEvaluate)
        
        textInputView.text = nil
        updateTextViewHeight()
        // evalButton.enabled = false
        
        // Dispatch to be evaluated
        
        let delayTime = dispatch_time(DISPATCH_TIME_NOW,
            Int64(50 * Double(NSEC_PER_MSEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            appDelegate.evaluate(textToEvaluate)
        }

    }
    
    func tableViewScrollToBottomAnimated(animated: Bool) {
        let numberOfSections = tableView.numberOfSections();
        let numberOfRows = tableView.numberOfRowsInSection(numberOfSections-1)
        if numberOfRows > 0 {
            tableView.scrollToRowAtIndexPath(NSIndexPath(forRow: numberOfRows-1, inSection: numberOfSections-1), atScrollPosition: .Bottom, animated: animated)
        }
    }
    
    // Handle actions #CopyMessage
    // 1. Select row and show "Copy" menu
    func messageShowMenuAction(gestureRecognizer: UITapGestureRecognizer) {
        let twoTaps = (gestureRecognizer.numberOfTapsRequired == 2)
        let doubleTap = (twoTaps && gestureRecognizer.state == .Ended)
        let longPress = (!twoTaps && gestureRecognizer.state == .Began)
        if doubleTap || longPress {
            let pressedIndexPath = tableView.indexPathForRowAtPoint(gestureRecognizer.locationInView(tableView))!
            tableView.selectRowAtIndexPath(pressedIndexPath, animated: false, scrollPosition: .None)
            
            let menuController = UIMenuController.sharedMenuController()
            let bubbleImageView = gestureRecognizer.view!
            menuController.setTargetRect(bubbleImageView.frame, inView: bubbleImageView.superview!)
            menuController.menuItems = [UIMenuItem(title: "Copy", action: "messageCopyTextAction:")]
            menuController.setMenuVisible(true, animated: true)
        }
    }
    // 2. Copy text to pasteboard
    func messageCopyTextAction(menuController: UIMenuController) {
        let selectedIndexPath = tableView.indexPathForSelectedRow()
        let selectedMessage = history.loadedMessages[selectedIndexPath!.section][selectedIndexPath!.row]
        UIPasteboard.generalPasteboard().string = selectedMessage.text
    }
    // 3. Deselect row
    func menuControllerWillHide(notification: NSNotification) {
        if let selectedIndexPath = tableView.indexPathForSelectedRow() {
            tableView.deselectRowAtIndexPath(selectedIndexPath, animated: false)
        }
        (notification.object as! UIMenuController).menuItems = nil
    }
    
    override var keyCommands: [AnyObject]? {
        get {
            let commandEnter = UIKeyCommand(input: "\r", modifierFlags: .Command, action: Selector("sendAction"))
            return [commandEnter]
        }
    }
}

// Only show "Copy" when editing `textView` #CopyMessage
class InputTextView: UITextView {
    override func canPerformAction(action: Selector, withSender sender: AnyObject!) -> Bool {
        if (delegate as! ReplViewController).tableView.indexPathForSelectedRow() != nil {
            return action == "messageCopyTextAction:"
        } else {
            return super.canPerformAction(action, withSender: sender)
        }
    }
    
    // More specific than implementing `nextResponder` to return `delegate`, which might cause side effects?
    func messageCopyTextAction(menuController: UIMenuController) {
        (delegate as! ReplViewController).messageCopyTextAction(menuController)
    }
}
