//
//    Copyright (c) 2015 Max Sokolov https://twitter.com/max_sokolov
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy of
//    this software and associated documentation files (the "Software"), to deal in
//    the Software without restriction, including without limitation the rights to
//    use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
//    the Software, and to permit persons to whom the Software is furnished to do so,
//    subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
//    FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
//    COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
//    IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
//    CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

import UIKit
import Foundation

public typealias ReturnValue = AnyObject?

internal enum ActionHandler<I, C> {

    case actionBlock((data: ActionData<I, C>) -> Void)
    case actionReturnBlock((data: ActionData<I, C>) -> AnyObject?)
    
    func call(data: ActionData<I, C>) -> AnyObject? {

        switch (self) {
        case .actionBlock(let closure):
            closure(data: data)
            return true
        case .actionReturnBlock(let closure):
            return closure(data: data)
        }
    }
}

/**
    Responsible for building cells of given type and passing items to them.
*/
public class TableRowBuilder<I, C where C: UITableViewCell> : RowBuilder {

    private var actions = Dictionary<String, ActionHandler<I, C>>()
    private var items = [I]()

    public var reusableIdentifier: String
    public var estimatedRowHeight: CGFloat
    public var numberOfRows: Int {
        get {
            return items.count
        }
    }
    
    public init(item: I, id: String, estimatedRowHeight: CGFloat = UITableViewAutomaticDimension) {
        
        reusableIdentifier = id
        self.estimatedRowHeight = estimatedRowHeight
        items.append(item)
    }
    
    public init(items: [I]? = nil, id: String, estimatedRowHeight: CGFloat = UITableViewAutomaticDimension) {

        reusableIdentifier = id
        self.estimatedRowHeight = estimatedRowHeight
        
        if items != nil {
            self.items.appendContentsOf(items!)
        }
    }

    // MARK: Items manipulation
    
    public func appendItems(items: [I]) {
        
        self.items.appendContentsOf(items)
    }
    
    public func clear() {
        
        items.removeAll()
    }
    
    // MARK: Chaining actions

    public func action(key: String, closure: (data: ActionData<I, C>) -> Void) -> Self {

        actions[key] = .actionBlock(closure)
        return self
    }
    
    public func action(actionType: ActionType, closure: (data: ActionData<I, C>) -> Void) -> Self {

        actions[actionType.key] = .actionBlock(closure)
        return self
    }
    
    public func action(actionType: ActionType, closure: (data: ActionData<I, C>) -> ReturnValue) -> Self {

        actions[actionType.key] = .actionReturnBlock(closure)
        return self
    }
    
    // MARK: Triggers
    
    public func performAction(actionType: ActionType, cell: UITableViewCell?, indexPath: NSIndexPath, itemIndex: Int) -> AnyObject? {

        if let action = actions[actionType.key] {
            return action.call(ActionData(cell: cell as? C, indexPath: indexPath, item: items[itemIndex], itemIndex: itemIndex))
        }
        return nil
    }
}

/**
    Responsible for building configurable cells of given type and passing items to them.
*/
public class TableConfigurableRowBuilder<I, C: ConfigurableCell where C.Item == I, C: UITableViewCell> : TableRowBuilder<I, C>  {

    public init(item: I, estimatedRowHeight: CGFloat = UITableViewAutomaticDimension) {
        super.init(item: item, id: C.reusableIdentifier(), estimatedRowHeight: estimatedRowHeight)
    }

    public init(items: [I]? = nil, estimatedRowHeight: CGFloat = UITableViewAutomaticDimension) {
        super.init(items: items, id: C.reusableIdentifier(), estimatedRowHeight: estimatedRowHeight)
    }

    public override func performAction(actionType: ActionType, cell: UITableViewCell?, indexPath: NSIndexPath, itemIndex: Int) -> AnyObject? {

        switch actionType {
        case .configure:
            (cell as? C)?.configureWithItem(items[itemIndex])
        default: break
        }
        return super.performAction(actionType, cell: cell, indexPath: indexPath, itemIndex: itemIndex)
    }
}