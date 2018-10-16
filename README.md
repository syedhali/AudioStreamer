![streaming-audio-avaudioengine-banner-w-phone-image](https://cdn.fastlearner.media/streaming-audio-avaudioengine-banner-w-phone@2x.jpg)

# AudioStreamer

[![Apache License](https://img.shields.io/badge/license-Apache%202-lightgrey.svg?style=flat)](https://github.com/syedhali/AudioStreamer/blob/master/LICENSE)

A Swift 4 framework for streaming remote audio with real-time effects using `AVAudioEngine`. Read the full article 

# Blog Post Preview

## <a name="buildingavaudioenginestreamer"></a>Building our *AVAudioEngine* streamer

Because the `AVAudioEngine` works like a hybrid between the **Audio Queue Services** and **Audio Unit Processing Graph Services** we can combine what we know about each to create a streamer that schedules audio like a queue, but supports real-time effects like an audio graph. 

At a high-level here's what we'd like to achieve:

![Streamer overview diagram](https://cdn.fastlearner.media/streamer-overview-diagram.svg)

Here's a breakdown of the streamer's components:

1. **Download** the audio data from the internet. We know we need to pull raw audio data from somewhere. How we implement the downloader doesn't matter as long as we're receiving audio data in its binary format (i.e. `Data` in Swift 4). 
2. **Parse** the binary audio data into audio packets. To do this we will use the often confusing, but very awesome [Audio File Stream Services](https://developer.apple.com/documentation/audiotoolbox/audio_file_stream_services) API.
3. **Read** the parsed audio packets into LPCM audio packets. To handle any format conversion required (specifically compressed to uncompressed) we'll be using the [Audio Converter Services](https://developer.apple.com/documentation/audiotoolbox/audio_converter_services) API.
4. **Stream** (i.e. playback) the LPCM audio packets using an `AVAudioEngine` by scheduling them onto the `AVAudioPlayerNode` at the head of the engine.

In the following sections we're going to dive into the implementation of each of these components. We're going to use a protocol-based approach to define the functionality we'd expect from each component and then do a concrete implementation. For instance, for the **Download** component we're going to define a `Downloadable` protocol and perform a concrete implementation of the protocol using the `URLSession` in the `Downloader` class...[read more](fastlearner.io/blog/streaming-audio-with-effects-using-avaudioengine)
