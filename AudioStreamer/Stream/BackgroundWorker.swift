//
//  BackgroundWorker.swift
//  AudioStreamer
//
//  Created by Yacine Salhi on 22/07/2021.
//

import Foundation

class BackgroundWorker: NSObject {
    private var thread: Thread!
    private var block: (()->Void)!

    @objc
    internal func runBlock() { block() }
    
    internal func start(_ block: @escaping () -> Void) {
        self.block = block
        
        let threadName = String(describing: self).components(separatedBy: ".")[1]
        
        thread = Thread { [weak self] in
            while (self != nil && !self!.thread.isCancelled) {
                RunLoop.current.run(
                    mode: .default,
                    before: Date.distantFuture)
            }
            Thread.exit()
        }
        thread.name = "\(threadName)-\(UUID().uuidString)"
        thread.start()
        
        perform(#selector(runBlock),
                on: thread,
                with: nil,
                waitUntilDone: false,
                modes: [RunLoop.Mode.default.rawValue])
    }
    
    public func stop() {
        thread.cancel()
    }
}
