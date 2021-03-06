//
//  ConnectionManager.swift
//  CardsAgainst
//
//  Created by JP Simard on 11/2/14.
//  Copyright (c) 2014 JP Simard. All rights reserved.
//

import Foundation
import PeerKit
import MultipeerConnectivity


protocol MPCSerializable {
    
    var mpcSerialized: Data { get }
    init(mpcSerialized: Data)
}
enum Event: String {
    case send = "send",
    frame = "frame",
    scale = "scale",
    nav = "hideNav",
    orientation = "isLandscape"
}

struct ConnectionManager {

    // MARK: Properties

     static var peers: [MCPeerID] {
        return PeerKit.session?.connectedPeers as [MCPeerID]? ?? []
    }
    // MARK: Start

    static func start() {
        PeerKit.transceive(serviceType: "video-stream")
    }

    // MARK: Event Handling

    static func onConnect(_ run: PeerBlock?) {
        PeerKit.onConnect = run
    }

    static func onDisconnect(_ run: PeerBlock?) {
        PeerKit.onDisconnect = run
    
    }

    // thid method called to a recieve the data
    static func onEvent(_ event: Event, run: ObjectBlock?) {
        if let run = run {
            PeerKit.eventBlocks[event.rawValue] = run
        } else {
            PeerKit.eventBlocks.removeValue(forKey: event.rawValue)
        }
    }

    // MARK: Sending event to connected device

    static func sendEvent(_ event: Event, object: [String: MPCSerializable]? = nil, toPeers peers: [MCPeerID]? = PeerKit.session?.connectedPeers as [MCPeerID]?) {
        var anyObject: [String: Data]?
        if let object = object {
            anyObject = [String: Data]()
            for (key, value) in object {
                anyObject![key] = value.mpcSerialized
            }
        }
        PeerKit.sendEvent(event.rawValue, object: anyObject as AnyObject?, toPeers: peers)
    }
    
    static func sendEventForEach(_ event: Event, objectBlock: () -> ([String: MPCSerializable])) {
        for peer in ConnectionManager.peers {
            ConnectionManager.sendEvent(event, object: objectBlock(), toPeers: [peer])
        }
    }

}
