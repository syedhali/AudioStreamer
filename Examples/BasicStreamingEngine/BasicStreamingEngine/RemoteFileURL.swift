//
//  RemoteFiles.swift
//  FileStreamerTests
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation

enum RemoteFileURL {
    case brokeForFree
    case claire
    case faithfulDog
    case theLastOnes
    
    var aac: URL {
        var urlString: String
        switch self {
        case .brokeForFree:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515264432/broke-for-free_chk6vl.aac"
        case .claire:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515263589/claire_ppq2pk.aac"
        case .faithfulDog:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515264432/faithful-dog_exlvpb.aac"
        case .theLastOnes:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515264432/the-last-ones_rglkft.aac"
        }
        return URL(string: urlString)!
    }
    
    var mp3: URL {
        var urlString: String
        switch self {
        case .brokeForFree:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515264427/broke-for-free_jpm3g9.mp3"
        case .claire:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515262774/claire_v3z4em.mp3"
        case .faithfulDog:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515264427/faithful-dog_ihawmp.mp3"
        case .theLastOnes:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515264427/the-last-ones_fc6omw.mp3"
//            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515363988/the-last-ones_siesju.mp3"
        }
        return URL(string: urlString)!
    }
    
    var wav: URL {
        var urlString: String
        switch self {
        case .brokeForFree:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515288411/broke-for-free_fzu5xw.wav"
        case .claire:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515288411/claire_lih3yt.wav"
        case .faithfulDog:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515288410/faithful-dog_cygtnr.wav"
        case .theLastOnes:
            urlString = "https://res.cloudinary.com/drvibcm45/video/upload/v1515288410/the-last-ones_tcqkl6.wav"
        }
        return URL(string: urlString)!
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
