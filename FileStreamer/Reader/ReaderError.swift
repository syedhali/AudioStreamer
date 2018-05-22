//
//  ReaderError.swift
//  FileStreamer
//
//  Created by Syed Haris Ali on 1/6/18.
//  Copyright © 2018 Ausome Apps LLC. All rights reserved.
//

import Foundation
import AudioToolbox

public enum ReaderError: LocalizedError {
    case converterFailed(OSStatus)
    case failedToCreateDestinationFormat
    case failedToCreatePCMBuffer
    case parserMissingDataFormat
    case readFailed(OSStatus)
    case unableToCreateConverter(OSStatus)
    
    public var localizedDescription: String {
        switch self {
        case .converterFailed(let status):
            return localizedDescriptionFromConverterError(status)
        case .failedToCreateDestinationFormat:
            return "Failed to create a destination (processing) format"
        case .failedToCreatePCMBuffer:
            return "Failed to create PCM buffer for reading data"
        case .parserMissingDataFormat:
            return "Parser is missing a valid data format"
        case .readFailed(let status):
            return localizedDescriptionFromReaderError(status)
        case .unableToCreateConverter(let status):
            return localizedDescriptionFromConverterError(status)
        }
    }
    
    func localizedDescriptionFromConverterError(_ status: OSStatus) -> String {
        switch status {
        case kAudioConverterErr_FormatNotSupported:
            return "Format not supported"
        case kAudioConverterErr_OperationNotSupported:
            return "Operation not supported"
        case kAudioConverterErr_PropertyNotSupported:
            return "Property not supported"
        case kAudioConverterErr_InvalidInputSize:
            return "Invalid input size"
        case kAudioConverterErr_InvalidOutputSize:
            return "Invalid output size"
        case kAudioConverterErr_BadPropertySizeError:
            return "Bad property size error"
        case kAudioConverterErr_RequiresPacketDescriptionsError:
            return "Requires packet descriptions"
        case kAudioConverterErr_InputSampleRateOutOfRange:
            return "Input sample rate out of range"
        case kAudioConverterErr_OutputSampleRateOutOfRange:
            return "Output sample rate out of range"
        case kAudioConverterErr_HardwareInUse:
            return "Hardware is in use"
        case kAudioConverterErr_NoHardwarePermission:
            return "No hardware permission"
        default:
            return "Unspecified error"
        }
    }
    
    func localizedDescriptionFromReaderError(_ status: OSStatus) -> String {
        switch status {
        case ReaderNotEnoughDataError:
            return "Reader does not have enough data"
        case ReaderReachedEndOfDataError:
            return "Reader reached the end of the file"
        case ReaderPartialConversionError:
            return "Reader could only partially convert the requested buffer of audio"
        default:
            return "Unspecified reader error"
        }
    }
}
