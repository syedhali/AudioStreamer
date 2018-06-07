//
//  RemoteFiles.swift
//  AudioStreamerTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//
import Foundation

/// These files are for testing the various parts of the streamer. Note they sound terrible because I downsampled and compressed these to hell to save bandwidth since these are just for testing.
enum RemoteFileURL {
    case brokeForFree
    case claire
    case faithfulDog
    case theLastOnes
    
    private var hostname: String {
        return "cdn.fastlearner.media"
    }
    
    var filename: String {
        switch self {
        case .brokeForFree:
            return "broke-for-free"
        case .claire:
            return "claire"
        case .faithfulDog:
            return "faithful-dog"
        case .theLastOnes:
            return "the-last-ones"
        }
    }
    
    func resourcePathFor(_ fileExtension: String) -> URL {
        let path = "https://\(hostname)/\(filename).\(fileExtension)"
        return URL(string: path)!
    }
    
    var aac: URL {
        return resourcePathFor("aac")
    }
    
    var mp3: URL {
        return resourcePathFor("mp3")
    }
    
    var flac: URL {
        return resourcePathFor("flac")
    }
    
    var wav: URL {
        return resourcePathFor("wav")
    }
    
    enum LicenseType {
        case creativeCommons
    }
    
    var license: LicenseType {
        return .creativeCommons
    }
    
    enum Source {
        case freeMusicArchive(songHomepageURL: URL)
        
        var songHomepageURL: URL {
            var url: URL
            switch self {
            case .freeMusicArchive(let songHomepageURL):
                url = songHomepageURL
            }
            return url
        }
    }
    
    var source: Source {
        var urlString: String
        switch self {
        case .brokeForFree:
            urlString = "https://freemusicarchive.org/music/Broke_For_Free/Something_EP/Broke_For_Free_-_Something_EP_-_05_Something_Elated"
        case .claire:
            urlString = "https://freemusicarchive.org/music/Podington_Bear/Clair_De_Lune_Variations/Clair_De_Lune_Felt_Piano_Rhodes_and_Drum_Machine_Arr"
        case .faithfulDog:
            urlString = "https://freemusicarchive.org/music/The_Kyoto_Connection/Wake_Up_1957/09_Hachiko_The_Faithtful_Dog"
        case .theLastOnes:
            urlString = "https://freemusicarchive.org/music/Jahzzar/Smoke_Factory/The_last_ones"
        }
        let songHomepageURL = URL(string: urlString)!
        return .freeMusicArchive(songHomepageURL: songHomepageURL)
    }
}
