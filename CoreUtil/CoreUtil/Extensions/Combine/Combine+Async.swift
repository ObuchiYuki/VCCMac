//
//  Combine+Async.swift
//  CoreUtil
//
//  Created by yuki on 2023/01/01.
//

import Combine

extension Publisher where Self.Failure == Never {
    public func sinkAsync(_ block: @escaping (Output) async -> ()) -> AnyCancellable {
        self.sink(receiveValue: { output in
            Task{ await block(output) }
        })
    }
}
