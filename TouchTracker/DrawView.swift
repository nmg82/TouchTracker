import UIKit

class DrawView: UIView {
  var currentLine: Line?
  var finishedLines = [Line]()
  
  func strokeLine(line: Line) {
    let path = UIBezierPath()
    path.lineWidth = 10
    path.lineCapStyle = .Round
    
    path.moveToPoint(line.begin)
    path.addLineToPoint(line.end)
    path.stroke()
  }
  
  override func drawRect(rect: CGRect) {
    UIColor.blackColor().setStroke()
    
    for line in finishedLines {
      strokeLine(line)
    }
    
    if let line = currentLine {
      UIColor.redColor().setStroke()
      strokeLine(line)
    }
  }
}
