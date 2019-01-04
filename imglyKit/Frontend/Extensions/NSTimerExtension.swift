//
//  NSTimerExtension.swift
//  imglyKit
//
//  Created by Sascha Schwabbauer on 13/05/15.
//  Copyright (c) 2015 9elements GmbH. All rights reserved.
//

import Foundation

// Taken from https://github.com/radex/SwiftyTimer

private class NSTimerActor {
    var block: () -> ()
    
    init(_ block: @escaping () -> ()) {
        self.block = block
    }
    
    @objc func fire() {
        block()
    }
}

extension Timer {
    class func new(after interval: TimeInterval, _ block: @escaping () -> ()) -> Timer {
        return new(after: interval, repeats: false, block)
    }
    
    class func new(after interval: TimeInterval, repeats: Bool, _ block: @escaping () -> ()) -> Timer {
        let actor = NSTimerActor(block)
        return self.init(timeInterval: interval, target: actor, selector: #selector(NSTimerActor.fire), userInfo: nil, repeats: repeats)
    }
    
    class func after(_ interval: TimeInterval, _ block: @escaping () -> ()) -> Timer {
        let timer = Timer.new(after: interval, block)
        RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        return timer
    }
    
    class func after(_ interval: TimeInterval, repeats: Bool, _ block: @escaping () -> ()) -> Timer {
        let timer = Timer.new(after: interval, repeats: repeats, block)
        RunLoop.current.add(timer, forMode: RunLoopMode.defaultRunLoopMode)
        return timer
    }
}
