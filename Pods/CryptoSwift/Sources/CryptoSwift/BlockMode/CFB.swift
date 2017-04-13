//
//  CFB.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/03/16.
//  Copyright © 2016 Marcin Krzyzanowski. All rights reserved.
//
//  Cipher feedback (CFB)
//

struct CFBModeWorker: BlockModeWorker {
    typealias Element = Array<UInt8>

    let cipherOperation: CipherOperationOnBlock
    private let iv: Element
    private var prev: Element?

    init(iv: Array<UInt8>, cipherOperation: @escaping CipherOperationOnBlock) {
        self.iv = iv
        self.cipherOperation = cipherOperation
    }

    mutating func encrypt(_ plaintext: ArraySlice<UInt8>) -> Array<UInt8> {
        guard let ciphertext = cipherOperation(prev ?? iv) else {
            return Array(plaintext)
        }
        prev = xor(plaintext, ciphertext)
        return prev ?? []
    }

    mutating func decrypt(_ ciphertext: ArraySlice<UInt8>) -> Array<UInt8> {
        guard let plaintext = cipherOperation(prev ?? iv) else {
            return Array(ciphertext)
        }
        let result = xor(plaintext, ciphertext)
        self.prev = Array(ciphertext)
        return result
    }
}
