//
//  FaceTriggerEvaluators.swift
//  FaceTrigger
//
//  Created by Mike Peterson on 12/27/17.
//  Copyright © 2017 Blinkloop. All rights reserved.
//

import ARKit

protocol FaceTriggerEvaluatorProtocol {
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate)
}

class SmileEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        
        if let mouthSmileLeft = blendShapes[.mouthSmileLeft], let mouthSmileRight = blendShapes[.mouthSmileRight] {
            
            let newValue = ((mouthSmileLeft.floatValue + mouthSmileRight.floatValue) / 2.0) >= threshold
            if newValue != oldValue {
                delegate.onSmileDidChange?(smiling: newValue)
                if newValue {
                    delegate.onSmile?()
                }
            }
            oldValue = newValue
        }
    }
}

class BlinkEvaluator: BothEvaluator {

    static var onBoth: (FaceTriggerDelegate, Bool) -> Void = {  delegate, onBoth in
        delegate.onBlinkDidChange?(blinking: onBoth)
        if onBoth {
            delegate.onBlink?()
        }
    }

    static var onLeft: (FaceTriggerDelegate, Bool) -> Void = {  delegate, onBoth in
        delegate.onBlinkLeftDidChange?(blinkingLeft: onBoth)
        if onBoth {
            delegate.onBlinkLeft?()
        }
    }

    static var onRight: (FaceTriggerDelegate, Bool) -> Void = {  delegate, onBoth in
        delegate.onBlinkRightDidChange?(blinkingRight: onBoth)
        if onBoth {
            delegate.onBlinkRight?()
        }
    }

    init(threshold: Float) {
        super.init(threshold: threshold, leftKey: .eyeBlinkLeft, rightKey: .eyeBlinkRight, onBoth: BlinkEvaluator.onBoth, onLeft: BlinkEvaluator.onLeft, onRight: BlinkEvaluator.onRight)
    }
}

class BrowDownEvaluator: BothEvaluator {

    static var onBoth: (FaceTriggerDelegate, Bool) -> Void = {  delegate, onBoth in
        delegate.onBrowDownDidChange?(browDown: onBoth)
        if onBoth {
            delegate.onBrowDown?()
        }
    }

    static var onVoid: (FaceTriggerDelegate, Bool) -> Void =  { _, _ in }

    init(threshold: Float) {
        super.init(threshold: threshold, leftKey: .browDownLeft, rightKey: .browDownRight, onBoth: BlinkEvaluator.onBoth, onLeft: BrowDownEvaluator.onVoid, onRight: BrowDownEvaluator.onVoid)
    }
}

class BrowUpEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        
        if let browInnerUp = blendShapes[.browInnerUp] {
            
            let newValue = browInnerUp.floatValue >= threshold
            if newValue != oldValue {
                delegate.onBrowUpDidChange?(browUp: newValue)
                if newValue {
                    delegate.onBrowUp?()
                }
            }
            oldValue = newValue
        }
    }
}

class SquintEvaluator: BothEvaluator {

    static var onBoth: (FaceTriggerDelegate, Bool) -> Void = {  delegate, onBoth in
        delegate.onSquintDidChange?(squinting: onBoth)
        if onBoth {
            delegate.onSquint?()
        }
    }

    
    func onLeft(delegate: FaceTriggerDelegate, newLeft: Bool) {
    }
    
    func onRight(delegate: FaceTriggerDelegate, newRight: Bool) {
    }
    
    init(threshold: Float) {
        super.init(threshold: threshold, leftKey: .eyeSquintLeft, rightKey: .eyeSquintRight, onBoth: SquintEvaluator.onBoth, onLeft: BrowDownEvaluator.onVoid, onRight: BrowDownEvaluator.onVoid)
    }
}

class BothEvaluator: FaceTriggerEvaluatorProtocol {
    
    private let threshold: Float
    private let leftKey: ARFaceAnchor.BlendShapeLocation
    private let rightKey: ARFaceAnchor.BlendShapeLocation
    private let onBoth: (FaceTriggerDelegate, Bool) -> Void
    private let onLeft: (FaceTriggerDelegate, Bool) -> Void
    private let onRight: (FaceTriggerDelegate, Bool) -> Void

    private var oldLeft  = false
    private var oldRight  = false
    private var oldBoth  = false
    
    init(threshold: Float,
         leftKey: ARFaceAnchor.BlendShapeLocation ,
         rightKey: ARFaceAnchor.BlendShapeLocation,
         onBoth: @escaping (FaceTriggerDelegate, Bool) -> Void,
         onLeft: @escaping (FaceTriggerDelegate, Bool) -> Void,
         onRight: @escaping (FaceTriggerDelegate, Bool) -> Void) {
        
        self.threshold = threshold
        
        self.leftKey = leftKey
        self.rightKey = rightKey
        
        self.onBoth = onBoth
        self.onLeft = onLeft
        self.onRight = onRight
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        
        // note that "left" and "right" blend shapes are mirrored so they are opposite from what a user would consider "left" or "right"
        let left = blendShapes[rightKey]
        let right = blendShapes[leftKey]
        
        var newLeft = false
        if let left = left {
            newLeft = left.floatValue >= threshold
        }

        var newRight = false
        if let right = right {
            newRight = right.floatValue >= threshold
        }

        let newBoth = newLeft && newRight
        if newBoth != oldBoth {
            onBoth(delegate, newBoth)
        } else {
            
            if newLeft != oldLeft {
                onLeft(delegate, newLeft)
            } else if newRight != oldRight {
                onRight(delegate, newRight)
            }
        }
        
        oldBoth = newBoth
        oldLeft = newLeft
        oldRight = newRight
    }
}

class CheekPuffEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        
        if let cheekPuff = blendShapes[.cheekPuff] {
            
            let newValue = cheekPuff.floatValue >= threshold
            if newValue != oldValue {
                delegate.onCheekPuffDidChange?(cheekPuffing: newValue)
                if newValue {
                    delegate.onCheekPuff?()
                }
            }
            oldValue = newValue
        }
    }
}

class MouthPuckerEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        
        if let mouthPucker = blendShapes[.mouthPucker] {
            
            let newValue = mouthPucker.floatValue >= threshold
            if newValue != oldValue {
                delegate.onMouthPuckerDidChange?(mouthPuckering: newValue)
                if newValue {
                    delegate.onMouthPucker?()
                }
            }
            oldValue = newValue
        }
    }
}

class JawOpenEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        
        if let jawOpen = blendShapes[.jawOpen] {
            
            let newValue = jawOpen.floatValue >= threshold
            if newValue != oldValue {
                delegate.onJawOpenDidChange?(jawOpening: newValue)
                if newValue {
                    delegate.onJawOpen?()
                }
            }
            oldValue = newValue
        }
    }
}

class JawLeftEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        // note that "left" and "right" blend shapes are mirrored so they are opposite from what a user would consider "left" or "right"
        if let jawLeft = blendShapes[.jawRight] {
            
            let newValue = jawLeft.floatValue >= threshold
            if newValue != oldValue {
                delegate.onJawLeftDidChange?(jawLefting: newValue)
                if newValue {
                    delegate.onJawLeft?()
                }
            }
            oldValue = newValue
        }
    }
}

class JawRightEvaluator: FaceTriggerEvaluatorProtocol {
    
    private var oldValue  = false
    private let threshold: Float
    
    init(threshold: Float) {
        self.threshold = threshold
    }
    
    func evaluate(_ blendShapes: [ARFaceAnchor.BlendShapeLocation : NSNumber], forDelegate delegate: FaceTriggerDelegate) {
        // note that "left" and "right" blend shapes are mirrored so they are opposite from what a user would consider "left" or "right"
        if let jawRight = blendShapes[.jawLeft] {
            
            let newValue = jawRight.floatValue >= threshold
            if newValue != oldValue {
                delegate.onJawRightDidChange?(jawRighting: newValue)
                if newValue {
                    delegate.onJawRight?()
                }
            }
            oldValue = newValue
        }
    }
}
