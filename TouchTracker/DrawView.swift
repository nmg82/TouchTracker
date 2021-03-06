import UIKit

class DrawView: UIView {
  var currentLines = [NSValue:Line]()
  var finishedLines = [Line]()
  var selectedLineIndex: Int? {
    didSet {
      if selectedLineIndex == nil {
        UIMenuController.sharedMenuController().setMenuVisible(false, animated: true)
      }
    }
  }
  
  @IBInspectable var finishedLineColor: UIColor = .blackColor() {
    didSet {
      setNeedsDisplay()
    }
  }
  
  @IBInspectable var currentLineColor: UIColor = .redColor() {
    didSet {
      setNeedsDisplay()
    }
  }
  
  @IBInspectable var lineThickness: CGFloat = 10 {
    didSet {
      setNeedsDisplay()
    }
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
  
    let doubleTapRecognizer = UITapGestureRecognizer(target: self, action: #selector(doubleTap))
    doubleTapRecognizer.numberOfTapsRequired = 2
    doubleTapRecognizer.delaysTouchesBegan = true
    addGestureRecognizer(doubleTapRecognizer)
    
    let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tap))
    tapRecognizer.delaysTouchesBegan = true
    tapRecognizer.requireGestureRecognizerToFail(doubleTapRecognizer)
    addGestureRecognizer(tapRecognizer)
    
    let longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPress))
    addGestureRecognizer(longPressRecognizer)
    
    let moveRecognizer = UIPanGestureRecognizer(target: self, action: #selector(moveLine))
    moveRecognizer.cancelsTouchesInView = false
    moveRecognizer.delegate = self
    addGestureRecognizer(moveRecognizer)
    
    let swipeRecognizer = UISwipeGestureRecognizer(target: self, action: #selector(showColors))
    swipeRecognizer.numberOfTouchesRequired = 3
    swipeRecognizer.direction = .Up
    addGestureRecognizer(swipeRecognizer)
  }
  
  func doubleTap(gestureRecognizer: UIGestureRecognizer) {
    currentLines.removeAll(keepCapacity: false)
    finishedLines.removeAll(keepCapacity: false)
    selectedLineIndex = nil
    setNeedsDisplay()
  }
  
  func tap(gestureRecognizer: UIGestureRecognizer) {
    let point = gestureRecognizer.locationInView(self)
    selectedLineIndex = indexOfLineAtPoint(point)
    
    guard selectedLineIndex != nil else {
      setNeedsDisplay()
      return
    }
    
    becomeFirstResponder()
    
    let menu = UIMenuController.sharedMenuController()
    let deleteItem = UIMenuItem(title: "Delete", action: #selector(deleteLine))
    menu.menuItems = [deleteItem]
    menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
    menu.setMenuVisible(true, animated: true)
    
    setNeedsDisplay()
  }
  
  func deleteLine() {
    guard let index = selectedLineIndex else { return }
    
    finishedLines.removeAtIndex(index)
    selectedLineIndex = nil
    setNeedsDisplay()
  }
  
  override func canBecomeFirstResponder() -> Bool {
    return true
  }
  
  func longPress(gestureRecognizer: UIGestureRecognizer) {
    if gestureRecognizer.state == .Began {
      let point = gestureRecognizer.locationInView(self)
      selectedLineIndex = indexOfLineAtPoint(point)
      
      if selectedLineIndex != nil {
        currentLines.removeAll(keepCapacity: false)
      }
    } else if gestureRecognizer.state == .Ended {
      selectedLineIndex = nil
    }
    
    setNeedsDisplay()
  }
  
  func moveLine(gestureRecognizer: UIPanGestureRecognizer) {
    guard let index = selectedLineIndex where !UIMenuController.sharedMenuController().menuVisible else { return }
    
    if gestureRecognizer.state == .Changed {
      //how far has the pan moved?
      let translation = gestureRecognizer.translationInView(self)
      
      //add the translation to the current beginning and end point of the line
      finishedLines[index].begin.x += translation.x
      finishedLines[index].begin.y += translation.y
      finishedLines[index].end.x += translation.x
      finishedLines[index].end.y += translation.y
      
      gestureRecognizer.setTranslation(CGPoint.zero, inView: self)
      setNeedsDisplay()
    }
  }
  
  func showColors(gestureRecognizer: UIGestureRecognizer) {
    becomeFirstResponder()
    
    let menu = UIMenuController.sharedMenuController()
    let red = UIMenuItem(title: "Red", action: #selector(changeFinishedColorToRed))
    let green = UIMenuItem(title: "Green", action: #selector(changeFinishedColorToGreen))
    let blue = UIMenuItem(title: "Blue", action: #selector(changeFinishedColorToBlue))
    let yellow = UIMenuItem(title: "Yellow", action: #selector(changeFinishedColorToYellow))
    
    menu.menuItems = [red, green, blue, yellow]
    
    let point = gestureRecognizer.locationInView(self)
    menu.setTargetRect(CGRect(x: point.x, y: point.y, width: 2, height: 2), inView: self)
    menu.setMenuVisible(true, animated: true)
  }
  
  func changeFinishedColorToBlue() {
    finishedLineColor = .blueColor()
  }
  
  func changeFinishedColorToGreen() {
    finishedLineColor = .greenColor()
  }
  
  func changeFinishedColorToYellow() {
    finishedLineColor = .yellowColor()
  }

  func changeFinishedColorToRed(sender: UIMenuController) {
    finishedLineColor = .redColor()
  }
  
  override func drawRect(rect: CGRect) {
    for line in finishedLines {
      line.color.setStroke()
      strokeLine(line)
    }
    
    for (_, line) in currentLines {
      line.color.setStroke()
      strokeLine(line)
    }
    
    if let index = selectedLineIndex {
      UIColor.greenColor().setStroke()
      let selectedLine = finishedLines[index]
      strokeLine(selectedLine)
    }
  }
  
  func strokeLine(line: Line) {
    let path = UIBezierPath()
    path.lineWidth = lineThickness
    path.lineCapStyle = .Round
    
    path.moveToPoint(line.begin)
    path.addLineToPoint(line.end)
    path.stroke()
  }
  
  func indexOfLineAtPoint(point: CGPoint) -> Int? {
    for (index, line) in finishedLines.enumerate() {
      let begin = line.begin
      let end = line.end
      
      // check a few points on the line
      for t in CGFloat(0).stride(to: 1.0, by: 0.05) {
        let x = begin.x + ((end.x - begin.x) * t)
        let y = begin.y + ((end.y - begin.y) * t)
        
        // if the tapped point is within 20 points, lets return this line
        if hypot(x - point.x, y - point.y) < 20.0 {
          return index
        }
      }
    }
    
    // if nothing is close enough to the tapped point, then we did not select a line
    return nil
  }
  
  override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in touches {
      let location = touch.locationInView(self)
      let newLine = Line(begin: location, end: location, color: currentLineColor)
      let key = NSValue(nonretainedObject: touch)
      currentLines[key] = newLine
    }
    
    setNeedsDisplay()
  }
  
  override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in touches {
      let key = NSValue(nonretainedObject: touch)
      currentLines[key]?.end = touch.locationInView(self)
    }
    
    setNeedsDisplay()
  }
  
  override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    for touch in touches {
      let key = NSValue(nonretainedObject: touch)
      if var line = currentLines[key] {
        line.end = touch.locationInView(self)
        line.color = finishedLineColor
        finishedLines.append(line)
        currentLines.removeValueForKey(key)
      }
      
    }
    setNeedsDisplay()
  }
  
  override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    currentLines.removeAll()
    setNeedsDisplay()
  }
}

extension DrawView: UIGestureRecognizerDelegate {
  func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWithGestureRecognizer otherGestureRecognizer: UIGestureRecognizer) -> Bool {
    return true
  }
}
