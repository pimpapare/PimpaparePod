//
//  UIViewExtension.swift
//  Pimpapare
//
//  Created by pimpaporn chaichompoo on 3/1/2561 BE.
//  Copyright © 2561 pimpaporn chaichompoo. All rights reserved.
//

import UIKit

class UIViewExtension: UIView {
    
    public func fadeIn(withDuration duration: TimeInterval = 1.0,
                       withHandler handler: (() -> Void)? = nil) {
        
        let defaultAlpha = self.alpha
        self.alpha = 0
        
        UIView.animate(withDuration: duration, animations: {
            self.alpha = defaultAlpha
        }, completion: { (success) in
            guard let handler = handler else { return }
            handler()
        })
    }
    
    public func fadeOut(withDuration duration: TimeInterval = 1.0,
                        withHandler handler: (() -> Void)? = nil) {
        
        UIView.animate(withDuration: duration, animations: {
            self.alpha = 0.0
        }, completion: { (success) in
            guard let handler = handler else { return }
            handler()
        })
    }
    
    public func fadeAnimation(duration: TimeInterval = 0.5,
                              animation: @escaping (() -> Void),
                              completetion: ((Bool) -> Void)? = nil) {
        
        UIView.transition(with: self,
                          duration: duration,
                          options: .transitionCrossDissolve,
                          animations: animation,
                          completion: completetion)
    }
}
