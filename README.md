![streaming-audio-avaudioengine-banner-w-phone-image](https://cdn.fastlearner.media/streaming-audio-avaudioengine-banner-w-phone@2x.jpg)

# AudioStreamer

[![Apache License](https://img.shields.io/badge/license-Apache%202-lightgrey.svg?style=flat)](https://github.com/syedhali/AudioStreamer/blob/master/LICENSE)

A Swift 4 framework for streaming remote audio with real-time effects using `AVAudioEngine`. Read the full article [here](https://fastlearner.io/blog/streaming-audio-with-effects-using-avaudioengine)!

## Examples

This repo contains two example projects, one for iOS and one for macOS, in the `TimePitchStreamer.xcodeproj` found in the Examples folder. 

![device-examples](https://res.cloudinary.com/drvibcm45/image/upload/v1548541073/preview_aizb6d.png)

# Blog Post

In this article we're going to use `AVAudioEngine` to build an audio streamer that allows adjusting the time and pitch of a song downloaded from the internet in realtime. Why would we possibly want to do such a thing? Read on!

## Table of Content

- [Our Final App](#ourfinalapp)
- [How the web does it](#howwebdoesit)
- [Working with the *Audio Queue Services*](#workingwithaqs)
  * [Decoding Compressed Formats (MP3, AAC, etc.)](#decodingcompressedformats)
  * [Limitations of the *Audio Queue Services*](#limitationsoftheaudioqueueservices)
- [Working with the *Audio Unit Processing Graph Services (i.e. AUGraph)*](#workingwithauppgs)
  * [AUGraph](#augraph)
  * [Audio Unit](#audiounit)
    + [Built-in Audio Units](#builtinaudiounits)
    + [The anatomy of an Audio Unit](#anatomyofaudiounit)
    + [AUGraph (Example)](#augraphexample)
    + [Limitations of the *AUGraph*](#augraphlimitations)
    + [AUGraph deprecated](#augraphdeprecated)
- [Working with *AVAudioEngine*](#workingwithavaudioengine)
    + [AVAudioEngine vs AUGraph](#avaudioenginevsaugraph)
- [Building our *AVAudioEngine* streamer](#buildingavaudioenginestreamer)
  * [The *Downloading* protocol](#downloadingprotocol)
    + [The *DownloadingDelegate*](#downloadingdelegate)
    + [The *DownloadingState*](#downloadingstate)
  * [The *Downloader*](#downloader)
  * [The *Parsing* protocol](#parsingprotocol)
  * [The *Parser*](#parser)
    + [The *ParserPropertyChangeCallback*](#parserpropertychangecallback)
    + [The *ParserPacketCallback*](#parserpacketcallback)
  * [The *Reading* protocol](#readingprotocol)
  * [The *Reader*](#reader)
    + [The *ReaderConverterCallback*](#readerconvertercallback)
  * [The *Streaming* protocol](#streamingprotocol)
    + [The *StreamingDelegate*](#streamingdelegate)
    + [The *StreamingState*](#streamingstate)
  * [The *Streamer*](#streamer)
    + [Implementing The *DownloadingDelegate* protocol](#implementdownloadingdelegate)
      - [Scheduling Buffers](#schedulingbuffers)
    + [Playback Methods](#playbackmethods)
      - [Play](#implementingplay)
      - [Pause](#implementingpause)
      - [Stop](#implementingstop)
      - [Seek](#implementingseek)
- [Building our *TimePitchStreamer*](#buildingourtimepitchstreamer)
- [Building our UI](#buildingourui)
  * [Implementing the *ProgressSlider*](#implementingtheprogressslider)
  * [Implementing the mm:ss formatter](#implementingmmssformatter)
  * [Implementing the ViewController](#implementingtheviewcontroller)
    + [Implementing the *StreamingDelegate*](#implementingthestreamingdelegate)
  * [Implementing the Storyboard](#implementingthestoryboard)
- [Conclusion](#conclusion)
- [Credits](#credits)

## <a name="ourfinalapp"></a>Our Final App

We're going to be streaming the song [Rumble](https://www.bensound.com/royalty-free-music/track/rumble") by [Ben Sound](https://www.bensound.com). The remote URL for Rumble hosted by Fast Learner is:

```bash
https://cdn.fastlearner.media/bensound-rumble.mp3
```

I say remote because this file is living on the internet, not locally. Below we have a video demonstrating the time/pitch shifting iOS app we'll build in this article. You'll learn how this app downloads, parses (i.e. decodes), and plays back [Rumble](#song-link). Much like any standard audio player, we have the usual functionality including play, pause, volume control, and position seek. In addition to those controls, however, we've added two sliders at the top that allow adjusting the pitch and playback rate (time) of the song. 

[![Example Video Picture](https://res.cloudinary.com/drvibcm45/image/upload/v1566832031/Screen_Shot_2019-08-26_at_10.06.36_AM_a75zmo.png)](https://player.vimeo.com/video/291278554)

Notice how we're able to change the pitch and playback rate in realtime. This would not be possible (at least in a sane way) without the `AVAudioEngine`! Before we dive into the implementation let's take a look at what we're trying to achieve conceptually. Since we're looking to stream an audio file that's living on the internet it'd be helpful to understand how the web does it since our iOS player will borrow those same concepts to  download, enqueue, and stream the same audio data.

## <a name="howwebdoesit"></a>How the web does it

On the web we have an HTML5 `<audio>` element that allows us to stream an audio file from a URL using just a few lines of code. For instance, to play [Rumble](#song-link) all we need to write is:

```html
<audio controls>
  <source src="https://cdn.fastlearner.media/bensound-rumble.mp3" type="audio/mpeg">
  Your browser does not support the audio element.
</audio> 
```

This is super convenient for basic playback, but what if we wanted to add an effect? You'd need to use the [Web Audio Javascript API](https://developer.mozilla.org/en-US/docs/Web/API/Web_Audio_API), which involves wrapping the audio element as a node in an audio graph. Here's an example of how we could add a lowpass filter using Web Audio:

```
// Grab the audio element from the DOM
const audioNode = document.querySelector("audio");

// Use Web Audio to create an audio graph that uses the stream from the audio element
const audioCtx = new (window.AudioContext || window.webkitAudioContext)();
const sourceNode = audioCtx.createMediaElementSource(audioNode);

// Create the lowpass filter
const lowpassNode = audioCtx.createBiquadFilter();

// Connect the source to the lowpass filter
sourceNode.connect(lowpassNode);

// Connect the lowpass filter to the output (speaker)
lowpassNode.connect(audioCtx.destination);
```

Pretty convenient right? The audio graph in Web Audio allows us to chain together the audio stream to the low pass effect and the speaker like a guitarist would with a guitar, effect pedal, and an amp. 

Similar to how HTML5 provides  us the `<audio>` tag, Apple provides us the `AVPlayer` from the `AVFoundation` framework to perform basic file streaming. For instance, we could use the `AVPlayer` to play the same song as before like so:

```swift
if let url = URL(string: "https://cdn.fastlearner.media/bensound-rumble.mp3") {
    let player = AVPlayer(url: url)
    player.play()
}    
```

Just like the `<audio>` tag, this would be perfect if we just needed to play the audio without applying any effects or visualizing it. However, if we wanted more flexibility then we'd need something similar to Web Audio's audio graph on iOS...

![](https://i.imgflip.com/2jtwjx.jpg)

Though there is a little magic the `<audio>` tag handles on the web that we'll need to handle ourselves if we plan on using the `AVAudioEngine`, our final [TimePitchStreamer](https://github.com/syedhali/AudioStreamer/blob/master/Examples/TimePitchStreamer/TimePitchStreamer/TimePitchStreamer.swift) will look similar to the Web Audio implementation you saw above used to setup a graph and form connections between nodes. Note that until just a few years ago we'd have to achieve this using either the [Audio Queue Services](https://developer.apple.com/documentation/audiotoolbox/audio_queue_services) or [Audio Unit Processing Graph Services](https://developer.apple.com/documentation/audiotoolbox/audio_unit_processing_graph_services). Since the `AVAudioEngine` is a hybrid of these two approaches let's quickly review the two. 

## <a name="workingwithaqs"></a>Working with the *Audio Queue Services*

The **Audio Queue Services** provide an API for playing and recording audio data coming from an arbitrary source. For instance, consider a walkie-talkie app where you had a peer-to-peer connection between two iOS devices and wanted to stream audio from one phone to another. 

![Walkie-talkie queue example](https://cdn.fastlearner.media/audio-queue-diagram.svg)

You wouldn't be able to use a file reference (i.e. `AudioFileID` or `AVAudioFile`) from the receiving phone because nothing is written to disk. Instead, you'd likely be using the **MultipeerConnectivity** framework to send data from one phone to another, packet by packet. 

In this case, since we can't create a file reference we wouldn't be able to use an `AVPlayer` to play back the audio. Instead, we could make use of the **Audio Queue Services** to enqueue each buffer of audio data for playback as it is being received like so:

![Queue services diagram](https://cdn.fastlearner.media/queue-services-diagram.svg)

In this case, as we're receiving audio data on the device we'd like to perform playback with we'd be **pushing** those buffers onto a queue that would take care of scheduling each for playback to the speakers on a first-in first-out (FIFO) basis. For an example implementation of a streamer using the **Audio Queue Services** check out [this mini-player open source project](https://github.com/Beats-Music/mac-miniplayer/blob/master/MiniPlayer/DSYRTMPPlayer.m) I did for Beats Music (now [Apple Music](https://www.apple.com/music/)) a few years ago. 

### <a name="decodingcompressedformats"></a>Decoding Compressed Formats (MP3, AAC, etc.)

On the modern web most media resources are compressed to save storage space and bandwidth on servers and content delivery networks (CDN). An extremely handy feature of the **Audio Queue Services** is that it automatically handles decoding compressed formats like MP3 and AAC. As you'll see later, when using an `AUGraph` or `AVAudioEngine` you must take care of decoding any compressed audio data into a linear pulse code modulated format (LPCM, i.e. uncompressed) yourself in order to schedule it on a graph.

### <a name="limitationsoftheaudioqueueservices"></a>Limitations of the *Audio Queue Services*

As cool as the **Audio Queue Services** are, unfortunately, adding in realtime effects such as the time-pitch shifter in our example app would still be rather complicated and involve the use of an **Audio Unit**, which we’ll discuss in detail in the next section. For now, let's move on from the **Audio Queue Services** and take a look at the **Audio Unit Processing Graph Services**.

## <a name="workingwithauppgs"></a>Working with the *Audio Unit Processing Graph Services (i.e. AUGraph)*

The **Audio Unit Processing Graph Services** provide a graph-based API for playing uncompressed, LPCM audio data using nodes that are connected to each other. You can think of an audio graph working much like musicians in a rock band would setup their sound for a live show. The musicians would each connect their instruments to a series of effects and into to a mixer that would combine the different audio streams into single stream to play out the speakers. We can visualize this setup like so:

![Rock band graphic](https://res.cloudinary.com/fast-learner/image/upload/v1527044394/rock-band-graphic_bawp3c.svg)

1. Each musician starts producing audio using their instrument
2. The guitar player needs to use a distortion effect so she connects her guitar to an effect pedal before connecting to the mixer
3. The mixer takes an input from each musician and produces a single output to the speakers
4. The speakers play out to the audience

Using the **Audio Unit Processing Graph Services** we could model the setup from above like so:

![Rock band audio graph graphic](https://cdn.fastlearner.media/rock-band-graphic-audio-units.svg)

Notice how the output in this case **pulls** audio from each of the previous nodes. That is, the arrows flow right to left rather than left to right as in the rock band diagram above. We'll explore in detail in the next section. 

### <a name="augraph"></a>AUGraph

Specifically, when we’re working with the **Audio Unit Processing Graph Services** we’re dealing with the `AUGraph` interface, which has historically been the primary audio graph implementation in Apple's `CoreAudio` (specifically `AudioToolbox`) framework. Before the `AVAudioEngine` was introduced in 2014 this was the closest thing we had to the Web Audio graph implementation for writing iOS and macOS apps. The `AUGraph` provides the ability to manage an array of nodes and their connections. Think of it a wrapper around the nodes we used to represent the rock band earlier.

![Rock band AUGraph graphic](https://cdn.fastlearner.media/rock-band-graphic-augraph.svg)

As noted above, audio graphs work on a **pull** model - that is, the last node of an audio graph pulls data from its previously connected node, which then pulls data from its previously connected until it reaches the first node. For our guitar player above the flow of audio would go something like this - note the direction of the arrows:

![Simple AUGraph graphic](https://cdn.fastlearner.media/simple-augraph-pull-diagram.svg)

Each render cycle of the audio graph would cause the output to pull audio data from the mixer, which would pull audio data from the distortion effect, which would then pull audio from the guitar. If the guitar at the head of the chain wasn't producing any sweet riffs it'd still be in charge of providing a silent buffer of audio for the rest of the graph to use. The head of  an audio graph (i.e. the component most to the left) is referred to as a **generator**. 

Each of the nodes in an `AUGraph` handles a specific function whether it be generating, modifying, or outputting sound. In an `AUGraph` a node is referred to as an `AUNode` and wraps what is called an [AudioUnit](https://developer.apple.com/documentation/audiounit). 

The `AudioUnit` is an incredibly important component of Core Audio. Each of the Audio Units contain implementations for generating and modifying streams of audio and providing I/O to the sound hardware on  iOS/macOS/tvOS. 

### <a name="audiounit"></a>Audio Unit

Think back to our guitar player using the distortion effect to modify the sound of her guitar. In the context of an `AUGraph` we’d use a distortion Audio Unit to handle processing that effect.

Audio Units, however, can do more than just apply an effect. Core Audio actually has specific Audio Units for providing **input** access from the mic or any connected instruments and **output** to the speakers and offline rendering. Hence, each Audio Unit has a `type`, such as `kAudioUnitType_Output` or `kAudioUnitType_Effect`, and `subtype`, such as `kAudioUnitSubType_RemoteIO` or `kAudioUnitSubType_Distortion`. 

#### <a name="builtinaudiounits"></a>Built-in Audio Units

**CoreAudio** provides a bunch of super useful built-in Audio Units. These are described in an `AudioComponentDescription` using *types* and *subtypes*. A **type** is a high-level description of what the Audio Unit does. Is it a generator? A mixer? Each serves a different function in the context of a graph and has rules how it can be used. As of iOS 12 we have the following types:

| Types |
|------------------------------|
| kAudioUnitType_Effect        |
| kAudioUnitType_Mixer         |
| kAudioUnitType_Output        |
| kAudioUnitType_Panner        |
| kAudioUnitType_Generator     |
| kAudioUnitType_MusicDevice   |
| kAudioUnitType_MusicEffect   |
| kAudioUnitType_RemoteEffect  |
| kAudioUnitType_MIDIProcessor |

A **subtype** is a low-level description of what an Audio Unit specifically does. Is it a time/pitch shifting effect? Is it an input that uses hardware-enabled voice processing? Is it a MIDI synth?

| Subtypes |
|----------------------------------------|
| kAudioUnitSubType_NewTimePitch         |
| kAudioUnitSubType_MIDISynth            |
| kAudioUnitSubType_Varispeed            |
| kAudioUnitSubType_AUiPodTime           |
| kAudioUnitSubType_Distortion           |
| kAudioUnitSubType_MatrixMixer          |
| kAudioUnitSubType_PeakLimiter          |
| kAudioUnitSubType_SampleDelay          |
| kAudioUnitSubType_ParametricEQ         |
| kAudioUnitSubType_RoundTripAAC         |
| kAudioUnitSubType_SpatialMixer         |
| kAudioUnitSubType_GenericOutput        |
| kAudioUnitSubType_LowPassFilter        |
| kAudioUnitSubType_MultiSplitter        |
| kAudioUnitSubType_BandPassFilter       |
| kAudioUnitSubType_HighPassFilter       |
| kAudioUnitSubType_LowShelfFilter       |
| kAudioUnitSubType_AudioFilePlayer      |
| kAudioUnitSubType_AUiPodTimeOther      |
| kAudioUnitSubType_HighShelfFilter      |
| kAudioUnitSubType_DeferredRenderer     |
| kAudioUnitSubType_DynamicsProcessor    |
| kAudioUnitSubType_MultiChannelMixer    |
| kAudioUnitSubType_VoiceProcessingIO    |
| kAudioUnitSubType_ScheduledSoundPlayer |

You may have noticed the time-pitch shift effect above (`kAudioUnitSubType_NewTimePitch`). We *may* be able to use something similar to this for our streamer! 

Please note that this list is constantly getting updated with every new version of iOS and changes depending on whether you're targeting iOS, macOS, or tvOS so the best way to know what you have available is to check Apple's docs. 

#### <a name="anatomyofaudiounit"></a>The anatomy of an Audio Unit

For this article we're not going to be directly using Audio Units in our streamer, but understanding the anatomy of one will help us get familiar with the terminology used in the `AVAudioEngine`.  Let's analyze Apple's diagram of an Audio Unit:

![](https://cdn.fastlearner.media/audio-unit.jpeg)

Let’s break down what you’re seeing above:
- An Audio Unit contains 3 different “scopes”. The left side where the audio is flowing in is the **Input** scope, while the right side where the audio is flowing out is the **Output** scope. The **Global** scope refers to the global state of the Audio Unit.
- Each scope of an Audio Unit has a stream description describing the format of the audio data (in the form of a `AudioStreamBasicDescription`).
- For each scope of an Audio Unit there can be n-channels where the Audio Unit’s implementation will specify the maximum number of channels it supports. You can query how many channels an Audio Unit supports for its input and output scopes. 
- The main logic for occurs in its DSP block shown in the center. Different types of units will either generate or process sound. 
- Audio Units can use a *Render Callback*, which is a function you can implement to either provide your own data (in the form of an `AudioBufferList` to the **Input** scope) to an Audio Unit or process data from an Audio Unit after the processing has been performed using the **Output** scope. When providing your own data to a render callback it is essential that its stream format matches the stream format of the **Input** scope.

#### <a name="augraphexample"></a>AUGraph (Example)

You can see a real-world implementation of an `AUGraph` in the [EZOutput](https://github.com/syedhali/EZAudio/blob/master/EZAudio/EZOutput.m#L199-L349) class of the [EZAudio](https://www.github.com/syedhali/EZAudio) framework I wrote a little while back.

#### <a name="augraphlimitations"></a>Limitations of the *AUGraph*

The **Audio Unit Processing Graph Services** require the audio data flowing through each node to be in a LPCM format and does not automatically perform any decoding like we'd get using the **Audio Queue Services**. If we’d like to use an `AUGraph` for streaming and support formats like MP3 or AAC we’d have to perform the decoding ourselves and then pass the LPCM data into the graph. 

It should be noted that using a node configured with the `kAudioUnitSubType_AUConverter` subtype does not handle compressed format conversions so we’d still need to use the **Audio Converter Services** to do that conversion on the fly. 

#### <a name="augraphdeprecated"></a>AUGraph deprecated

At WWDC 2017 Apple announced the `AUGraph` would be deprecated in 2018 in favor of the `AVAudioEngine`. We can see this is indeed the case by browsing the [AUGraph documentation](https://developer.apple.com/documentation/audiotoolbox/audio_unit_processing_graph_services) and looking at all the deprecation warnings. 

![AUGraph Deprecation in WWDC 2017 What's New in Core Audio Talk](https://cdn.fastlearner.media/augraph-deprecation-optimized.jpg)

Since teaching you how to write an audio streamer using deprecated technology would've killed the whole vibe of Fast Learner we'll move on to our implementation using the `AVAudioEngine`.

## <a name="workingwithavaudioengine"></a>Working with *AVAudioEngine*

You can think of the `AVAudioEngine` as something between a queue and a graph that serves as the missing link between the `AVPlayer` and the **Audio Queue Services** and **Audio Unit Processing Graph Services**. Whereas the **Audio Queue Services** and **Audio Unit Processing Graph Services** were originally C-based APIs, the `AVAudioEngine` was introduced in 2014 using a higher-level Objective-C/Swift interface. 

To create an instance of the `AVAudioEngine` in Swift (4.2) all we need to do is write:

```swift
let engine = AVAudioEngine()
```

Next we can create and connect generators, effects, and mixer nodes similar to how we did using an `AUGraph`. For instance, if we wanted to play a local audio file with a delay effect we could use the `AVAudioPlayerNode` and the `AVAudioUnitDelay`:

```swift
// Create the nodes (1)
let playerNode = AVAudioPlayerNode()
let delayNode = AVAudioUnitDelay()

// Attach the nodes (2)
engine.attach(playerNode)
engine.attach(delayNode)

// Connect the nodes (3)
engine.connect(playerNode, to: delayNode, format: nil)
engine.connect(delayNode, to: engine.mainMixerNode, format: nil)

// Prepare the engine (4)
engine.prepare()

// Schedule file (5)
do {
	// Local files only
	let url = URL(fileURLWithPath: "path_to_your_local_file")!
	let file = try AVAudioFile(forReading: url)
	playerNode.scheduleFile(file, at: nil, completionHandler: nil)
} catch {
	print("Failed to create file: \(error.localizedDescription)")
	return
}

// Setup delay parameters (6)
delayNode.delayTime = 0.8
delayNode.feedback = 80
delayNode.wetDryMix = 50

// Start the engine and player node (7)
do {
	try engine.start()
	playerNode.play()
} catch {
	print("Failed to start engine: \(error.localizedDescription)")
}
```

Here's a breakdown of what we just did: 

1. Created nodes for the file player and delay effect. The delay's class, `AVAudioUnitDelay`, is a subclass of `AVAudioUnitEffect`, which is the ***AVFoundation** wrapper for an Audio Unit. In the previous section we went into detail about Audio Units so this should hopefully be familiar!
2. We then attached the player and delay nodes to the engine. This is similar to the `AUGraphAddNode` method for `AUGraph` and works in a similar way (the engine now *owns* these nodes). 
3. Next we connected the nodes. First the player node into the delay node and then the delay node into the engine's output mixer node. This is similar to the `AUGraphConnectNodeInput` method for `AUGraph` and can be thought of like the guitar player's setup from earlier (*guitar* -> *pedal* -> *mixer* is now *player* -> *delay* -> *mixer*), where we're using the player node instead of a guitar as a generator. 
4. We then prepared the engine for playback. It is at this point the engine preallocates all the resources it needs for playback. This is similar to the `AUGraphInitialize` method for `AUGraph`.
5. Next we created a file for reading and scheduled it onto the player node. The file is an `AVAudioFile`, which is provided by `AVFoundation` for generic audio reading/writing. The player node has a handy method for efficiently scheduling audio from an `AVAudioFile`, but also supports scheduling individual buffers of audio as well in the form of `AVAudioPCMBuffer`.  Note this would only work for local files only (nothing on the internet)!
6. Set the default values on the delay node so we can hear the delay effect. 
7. Finally we started the engine and the player node. Once the engine is running we can start the player node at any time, but we'll started it immediately in this example.

#### <a name="avaudioenginevsaugraph"></a>AVAudioEngine vs AUGraph

A key difference between the `AVAudioEngine` and the `AUGraph` is in how we provide the audio data. `AUGraph` works on a **pull** model where we provide audio buffers in the form of `AudioBufferList` in a render callback whenever the graph needs it. 

![AUGraph Pull](https://cdn.fastlearner.media/augraph-push.svg)

`AVAudioEngine`, on the other hand, works on a **push** model similar to the **Audio Queue Services**. We schedule files or audio buffers in the form of `AVAudioFile` or `AVAudioPCMBuffer` onto the player node. The player node then internally handles providing the data for the engine to consume at runtime.

![AUGraph Pull](https://cdn.fastlearner.media/avaudioengine-push.svg)

We'll keep the **push** model in mind as we move into the next section. 

## <a name="buildingavaudioenginestreamer"></a>Building our *AVAudioEngine* streamer

Because the `AVAudioEngine` works like a hybrid between the **Audio Queue Services** and **Audio Unit Processing Graph Services** we can combine what we know about each to create a streamer that schedules audio like a queue, but supports real-time effects like an audio graph. 

At a high-level here's what we'd like to achieve:

![Streamer overview diagram](https://cdn.fastlearner.media/streamer-overview-diagram.svg)

Here's a breakdown of the streamer's components:

1. **Download** the audio data from the internet. We know we need to pull raw audio data from somewhere. How we implement the downloader doesn't matter as long as we're receiving audio data in its binary format (i.e. `Data` in Swift 4). 
2. **Parse** the binary audio data into audio packets. To do this we will use the often confusing, but very awesome [Audio File Stream Services](https://developer.apple.com/documentation/audiotoolbox/audio_file_stream_services) API.
3. **Read** the parsed audio packets into LPCM audio packets. To handle any format conversion required (specifically compressed to uncompressed) we'll be using the [Audio Converter Services](https://developer.apple.com/documentation/audiotoolbox/audio_converter_services) API.
4. **Stream** (i.e. playback) the LPCM audio packets using an `AVAudioEngine` by scheduling them onto the `AVAudioPlayerNode` at the head of the engine.

In the following sections we're going to dive into the implementation of each of these components. We're going to use a protocol-based approach to define the functionality we'd expect from each component and then do a concrete implementation. For instance, for the **Download** component we're going to define a `Downloading` protocol and perform a concrete implementation of the protocol using the `URLSession` in the `Downloader` class. 

### <a name="downloadingprotocol"></a>The *Downloading* protocol

Let's start by defining a `Downloading` protocol that we can use to fetch our audio data.

```swift
public protocol Downloading: class {
    
    // MARK: - Properties
    
    /// A receiver implementing the `DownloadingDelegate` to receive state change, completion, and progress events from the `Downloading` instance.
    var delegate: DownloadingDelegate? { get set }
    
    /// The current progress of the downloader. Ranges from 0.0 - 1.0, default is 0.0.
    var progress: Float { get }
    
    /// The current state of the downloader. See `DownloadingState` for the different possible states.
    var state: DownloadingState { get }
    
    /// A `URL` representing the current URL the downloader is fetching. This is an optional because this protocol is designed to allow classes implementing the `Downloading` protocol to be used as singletons for many different URLS so a common cache can be used to redownloading the same resources.
    var url: URL? { get set }
    
    // MARK: - Methods
    
    /// Starts the downloader
    func start()
    
    /// Pauses the downloader
    func pause()
    
    /// Stops and/or aborts the downloader. This should invalidate all cached data under the hood.
    func stop()
    
}
```

At a high level we expect to have a delegate (defined below) to receive the binary audio data as it is received, a progress value for how much of the total data has been downloaded, as well as a state (defined below) to define whether the download has started, stopped, or paused. 

#### <a name="downloadingdelegate"></a>The *DownloadingDelegate*

```swift
public protocol DownloadingDelegate: class {
    func download(_ download: Downloading, changedState state: DownloadingState)
    func download(_ download: Downloading, completedWithError error: Error?)
    func download(_ download: Downloading, didReceiveData data: Data, progress: Float)
}
```

#### <a name="downloadingstate"></a>The *DownloadingState*

```swift
public enum DownloadingState: String {
    case completed
    case started
    case paused
    case notStarted
    case stopped
}
```

### <a name="downloader"></a>The *Downloader*

Our `Downloader` class is going to be the concrete implementation of the `Downloading` protocol and use the `URLSession` to perform the networking request. Let's start by implementing the properties for the `Downloading` protocol. 

```swift
public class Downloader: NSObject, Downloading {

    public var delegate: DownloadingDelegate?
    public var progress: Float = 0
    public var state: DownloadingState = .notStarted {
        didSet {
            delegate?.download(self, changedState: state)
        }
    }
    public var totalBytesReceived: Int64 = 0
    public var totalBytesCount: Int64 = 0
    public var url: URL? {
        didSet {
            if state == .started {
                stop()
            }
            
            if let url = url {
                progress = 0.0
                state = .notStarted
                totalBytesCount = 0
                totalBytesReceived = 0
                task = session.dataTask(with: url)
            } else {
                task = nil
            }
        }
    }
    
}
```

Next we're going to define our `URLSession` related properties.

```swift
public class Downloader: NSObject, Downloading {
    
    ...Downloading properties

    /// The `URLSession` currently being used as the HTTP/HTTPS implementation for the downloader.
    fileprivate lazy var session: URLSession = {
        return URLSession(configuration: .default, delegate: self, delegateQueue: nil)
    }()
    
    /// A `URLSessionDataTask` representing the data operation for the current `URL`.
    fileprivate var task: URLSessionDataTask?
    
    /// A `Int64` representing the total amount of bytes received
    var totalBytesReceived: Int64 = 0
    
    /// A `Int64` representing the total amount of bytes for the entire file
    var totalBytesCount: Int64 = 0
    
}
```

Now we'll implement the `Downloading` protocol's methods for `start()`, `pause()`, and `stop()`. 

```swift
public class Downloader: NSObject, Downloading {

    ...Properties
    
    public func start() {
        guard let task = task else {
            return
        }
        
        switch state {
        case .completed, .started:
            return
        default:
            state = .started
            task.resume()
        }
    }
    
    public func pause() {
        guard let task = task else {
            return
        }
        
        guard state == .started else {
            return
        }
        
        state = .paused
        task.suspend()
    }
    
    public func stop() {
        guard let task = task else {
            return
        }
        
        guard state == .started else {
            return
        }
        
        state = .stopped
        task.cancel()
    }
}
```

Finally, we go ahead and implement the `URLSessionDataDelegate` methods on the `Downloader` to receive the data from the `URLSession`.

```swift
extension Downloader: URLSessionDataDelegate {

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        totalBytesCount = response.expectedContentLength
        completionHandler(.allow)
    }

    public func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        totalBytesReceived += Int64(data.count)
        progress = Float(totalBytesReceived) / Float(totalBytesCount)
        delegate?.download(self, didReceiveData: data, progress: progress)
        progressHandler?(data, progress)
    }
    
    public func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        state = .completed
        delegate?.download(self, completedWithError: error)
        completionHandler?(error)
    }
    
}
```

Nice! Our `Downloader` is now complete and is ready to to download a song from the internet using a URL. As the song is downloading and we receive each chunk of binary audio data we will report it to a receiver via the delegate's `download(_:, didReceiveData:,progress:)` method. 

### <a name="parsingprotocol"></a>The *Parsing* protocol

To handle converting the audio data from a `Downloading` into audio packets let's go ahead and implement a `Parsing` protocol.

```swift
import AVFoundation

public protocol Parsing: class {
    
    // MARK: - Properties
        
    /// (1)
    var dataFormat: AVAudioFormat? { get }
    
    /// (2)
    var duration: TimeInterval? { get }
    
    /// (3)
    var isParsingComplete: Bool { get }
    
    /// (4)
    var packets: [(Data, AudioStreamPacketDescription?)] { get }
    
    /// (5)
    var totalFrameCount: AVAudioFrameCount? { get }
    
    /// (6)
    var totalPacketCount: AVAudioPacketCount? { get }
    
    // MARK: - Methods
    
    /// (7)
    func parse(data: Data) throws
    
    /// (8)
    func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition?
    
    /// (9)
    func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount?
    
    /// (10)
    func timeOffset(forFrame frame: AVAudioFrameCount) -> TimeInterval?
    
}
```

In a `Parsing` we'd expect it to have a couple important properties:

1. A `dataFormat` property that describes the format of the audio packets. 
2. A `duration` property that describes the total duration of the file in seconds.
3. An `isParsingComplete` property indicating whether all the packets have been parsed. This will always be evaluated as the count of the `packets` property being equal to the `totalPacketCount` property. We'll do a default implementation of this in the next section.
4. A `packets` property that holds an array of duples. Each duple contains a chunk of binary audio data (`Data`) and an optional packet description (`AudioStreamPacketDescription`) if it is a compressed format.
5. A `totalFrameCount` property that describes the total amount of frames in the entire audio file.
6. A `totalPacketCount` property that describes the total amount of packets in the entire audio file.

In addition, we define a few methods that will allow us to parse and seek through the audio packets.

7. A `parse(data:)` method that takes in binary audio data and progressively parses it to provide us the properties listed above.
8. A `frameOffset(forTime:)` method that provides a frame offset given a time in seconds. _This method and the next two are needed for handling seek operations._
9. A `packetOffset(forFrame:)` method that provides a packet offset given a frame. 
10. A `timeOffset(forFrame:)` method that provides a time offset given a frame.

Luckily, since we're likely to find ourselves writing the same code to define the `duration`, `totalFrameCount`, and `isParsingComplete` properties as well as the `frameOffset(forTime:)`, `packetOffset(forFrame:)`, and `timeOffset(forFrame:)` methods we can add an extension directly on the `Parsing` protocol to provide a default implementation of these.

```swift
extension Parsing {
    
    public var duration: TimeInterval? {
        guard let sampleRate = dataFormat?.sampleRate else {
            return nil
        }
        
        guard let totalFrameCount = totalFrameCount else {
            return nil
        }
        
        return TimeInterval(totalFrameCount) / TimeInterval(sampleRate)
    }
    
    public var totalFrameCount: AVAudioFrameCount? {
        guard let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else {
            return nil
        }
        
        guard let totalPacketCount = totalPacketCount else {
            return nil
        }
        
        return AVAudioFrameCount(totalPacketCount) * AVAudioFrameCount(framesPerPacket)
    }
    
    public var isParsingComplete: Bool {
        guard let totalPacketCount = totalPacketCount else {
            return false
        }
        
        return packets.count == totalPacketCount
    }
    
    public func frameOffset(forTime time: TimeInterval) -> AVAudioFramePosition? {
        guard let _ = dataFormat?.streamDescription.pointee,
            let frameCount = totalFrameCount,
            let duration = duration else {
                return nil
        }
        
        let ratio = time / duration
        return AVAudioFramePosition(Double(frameCount) * ratio)
    }
    
    public func packetOffset(forFrame frame: AVAudioFramePosition) -> AVAudioPacketCount? {
        guard let framesPerPacket = dataFormat?.streamDescription.pointee.mFramesPerPacket else {
            return nil
        }
        
        return AVAudioPacketCount(frame) / AVAudioPacketCount(framesPerPacket)
    }
    
    public func timeOffset(forFrame frame: AVAudioFrameCount) -> TimeInterval? {
        guard let _ = dataFormat?.streamDescription.pointee,
            let frameCount = totalFrameCount,
            let duration = duration else {
                return nil
        }
        
        return TimeInterval(frame) / TimeInterval(frameCount) * duration
    }
    
}
```

### <a name="parser"></a>The *Parser*

Our `Parser` class is going to be a concrete implementation of the `Parsing` protocol and use the [Audio File Stream Services](https://developer.apple.com/documentation/audiotoolbox/audio_file_stream_services) API to to convert the binary audio into audio packets. Let's start by implementing the properties for the `Parsing` protocol:

```swift
import AVFoundation

public class Parser: Parsing {

    public internal(set) var dataFormat: AVAudioFormat?
    public internal(set) var packets = [(Data, AudioStreamPacketDescription?)]()
	
	// (1)
    public var totalPacketCount: AVAudioPacketCount? {
        guard let _ = dataFormat else {
            return nil
        }
        
        return max(AVAudioPacketCount(packetCount), AVAudioPacketCount(packets.count))
    }
    
}
```

1. Note that we're determining the total packet count to be the maximum of either the `packetCount` property that is a one-time parsed value from the **Audio File Stream Services** or the total number of packets received so far (the `packets.count`).

Next we're going to define our **Audio File Stream Services** related properties. 

```swift
public class Parser: Parsing {

    ...Parsing properties

	/// A `UInt64` corresponding to the total frame count parsed by the Audio File Stream Services
    public internal(set) var frameCount: UInt64 = 0
    
    /// A `UInt64` corresponding to the total packet count parsed by the Audio File Stream Services
    public internal(set) var packetCount: UInt64 = 0
    
    /// The `AudioFileStreamID` used by the Audio File Stream Services for converting the binary data into audio packets
    fileprivate var streamID: AudioFileStreamID?
 
}
```
Next we're going to define a default initializer that will create a new `streamID` that is required before we can use the **Audio File Stream Services** to parse any audio data.

```swift
public class Parser: Parsing {

    ...Properties

    public init() throws {
        // (1)
        let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
        
        // (2)
        guard AudioFileStreamOpen(context, ParserPropertyChangeCallback, ParserPacketCallback, kAudioFileMP3Type, &streamID) == noErr else {
            throw ParserError.streamCouldNotOpen
        }
    }
 
}
```

1. We're creating a context object that we can pass into the `AudioFileStreamOpen` method that will allow us to access our `Parser` class instance within static C methods. 
2. We initialize the Audio File Stream by called the `AudioFileStreamOpen()` method and passing our context object and callback methods that we can use to be notified anytime there is new data that was parsed. 

The two callback methods for the **Audio File Stream Services** we'll used are defined below. 

- `ParserPropertyChangeCallback`: This is triggered when the **Audio File Stream Services** has enough data to provide a property such as the total packet count or data format.
- `ParserPacketCallback`: This is triggered when the **Audio File Stream Services** has enough data to provide audio packets and, if it's a compressed format such as MP3 or AAC, audio packet descriptions.

Note the use of the `unsafeBitCast` method above used to create an `UnsafeMutableRawPointer` representation of the `Parser` instance to pass into the callbacks.  In Core Audio we're typically dealing with C-based APIs and these callbacks are actually static C functions that are defined outside of the Obj-C/Swift class interfaces so the only way we can grab the instance of the `Parser` is by passing it in as a `context` object (in C this would be a `void *`). This will make more sense when we define our callbacks.

Before that, however, let's define our `parse(data:)` method from the `Parsing` protocol.

```swift
public class Parser: Parsing {

    ...Properties

    ...Init

    public func parse(data: Data) throws {
        let streamID = self.streamID!
        let count = data.count
        _ = try data.withUnsafeBytes { (bytes: UnsafePointer<UInt8>) in
            let result = AudioFileStreamParseBytes(streamID, UInt32(count), bytes, [])
            guard result == noErr else {
                throw ParserError.failedToParseBytes(result)
            }
        }
    }
 
}
```

Since the **Audio File Stream Services** is a C-based API we need to extract a pointer to the binary audio data from the `Data` object. We do this using the `withUnsafeBytes` method on `Data` and pass those bytes to the `AudioFileStreamParseBytes` method that will invoke either the `ParserPropertyChangeCallback` or `ParserPacketCallback` if it has enough audio data.

#### <a name="parserpropertychangecallback"></a>The *ParserPropertyChangeCallback*

As we pass audio data to the **Audio File Stream Services** via our `parse(data:)` method it will first call the property listener callback to indicate the various properties have been extracted. These include:

| Audio File Stream Properties |
|------------------------------------------------|
| kAudioFileStreamProperty_ReadyToProducePackets |
| kAudioFileStreamProperty_FileFormat            |
| kAudioFileStreamProperty_DataFormat            |
| kAudioFileStreamProperty_AudioDataByteCount    |
| kAudioFileStreamProperty_AudioDataPacketCount  |
| kAudioFileStreamProperty_DataOffset            |
| kAudioFileStreamProperty_BitRate               |
| kAudioFileStreamProperty_FormatList            |
| kAudioFileStreamProperty_MagicCookieData       |
| kAudioFileStreamProperty_MaximumPacketSize     |
| kAudioFileStreamProperty_ChannelLayout         |
| kAudioFileStreamProperty_PacketToFrame         |
| kAudioFileStreamProperty_FrameToPacket         |
| kAudioFileStreamProperty_PacketToByte          |
| kAudioFileStreamProperty_ByteToPacket          |
| kAudioFileStreamProperty_PacketTableInfo       |
| kAudioFileStreamProperty_PacketSizeUpperBound  |
| kAudioFileStreamProperty_AverageBytesPerPacket |
| kAudioFileStreamProperty_InfoDictionary        |

For the purposes of our `Parser` we only care about the `kAudioFileStreamProperty_DataFormat` and the `kAudioFileStreamProperty_AudioDataPacketCount`. Let's define our callback:

```swift
func ParserPropertyChangeCallback(_ context: UnsafeMutableRawPointer, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID, _ flags: UnsafeMutablePointer<AudioFileStreamPropertyFlags>) {
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
    
    /// Parse the various properties
    switch propertyID {
    case kAudioFileStreamProperty_DataFormat:
        var format = AudioStreamBasicDescription()
        GetPropertyValue(&format, streamID, propertyID)
        parser.dataFormat = AVAudioFormat(streamDescription: &format)
        
    case kAudioFileStreamProperty_AudioDataPacketCount:
        GetPropertyValue(&parser.packetCount, streamID, propertyID)

    default:
        break
    }
}
```

Note that we're able to obtain the instance of our `Parser` using the `Unmanaged` interface to cast the `context` pointer back to the appropriate class instance. Since our parser callbacks are [not happening on a realtime audio thread](http://atastypixel.com/blog/four-common-mistakes-in-audio-development/) this type of casting is ok. 

Also note that we're using a generic helper method called `GetPropertyValue(_:_:_:)` to get the actual property values from the `streamID`. We can define that method like so:

```swift
func GetPropertyValue<T>(_ value: inout T, _ streamID: AudioFileStreamID, _ propertyID: AudioFileStreamPropertyID) {
    var propSize: UInt32 = 0
    guard AudioFileStreamGetPropertyInfo(streamID, propertyID, &propSize, nil) == noErr else {
        return
    }
    
    guard AudioFileStreamGetProperty(streamID, propertyID, &propSize, &value) == noErr else {
        return
    }
}
```

Here we're wrapping the **Audio File Stream Services** C-based API for getting the property values. Like many other Core Audio APIs we first need to get the size of the property and then pass in that size as well as a variable to hold the actual value. Because of this we make the value itself generic and use the `inout` decoration to indicate the method is going to write back a value to the argument passed in instead of outputting a new value. 

#### <a name="parserpacketcallback"></a>The *ParserPacketCallback*

Next, once enough audio data has been passed to the **Audio File Stream Services** and the property parser is complete it will be ready to produce packets and continuously trigger the `ParserPacketCallback` as it can create more and more audio packets. Let's define our packet callback:

```swift
func ParserPacketCallback(_ context: UnsafeMutableRawPointer, _ byteCount: UInt32, _ packetCount: UInt32, _ data: UnsafeRawPointer, _ packetDescriptions: UnsafeMutablePointer<AudioStreamPacketDescription>) {
    // (1)
    let parser = Unmanaged<Parser>.fromOpaque(context).takeUnretainedValue()
 
    // (2)
    let packetDescriptionsOrNil: UnsafeMutablePointer<AudioStreamPacketDescription>? = packetDescriptions
    let isCompressed = packetDescriptionsOrNil != nil
    
    // (3)
    guard let dataFormat = parser.dataFormat else {
        return
    }
    
    // (4)
    if isCompressed {
        for i in 0 ..< Int(packetCount) {
            let packetDescription = packetDescriptions[i]
            let packetStart = Int(packetDescription.mStartOffset)
            let packetSize = Int(packetDescription.mDataByteSize)
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, packetDescription))
        }
    } else {
        let format = dataFormat.streamDescription.pointee
        let bytesPerPacket = Int(format.mBytesPerPacket)
        for i in 0 ..< Int(packetCount) {
            let packetStart = i * bytesPerPacket
            let packetSize = bytesPerPacket
            let packetData = Data(bytes: data.advanced(by: packetStart), count: packetSize)
            parser.packets.append((packetData, nil))
        }
    }
}
```

Let's go through what's happening here: 

1. We cast the `context` pointer back to our `Parser` instance. 
2. We then need to check if we're dealing with a compressed format (like MP3, AAC) or not. We actually have to cast the `packetDescriptions` argument back into an optional and check if it's nil. This is a bug with the **Audio File Stream Services** where the Swift interface generated from the original C-interface should have an optional argument for `packetDescriptions`. If you're reading this and are in the Core Audio team please fix this! :D
3. Next, we check if the `dataFormat` of the `Parser` is defined so we know how many bytes correspond to one packet of audio data.
4. Finally, we iterate through the number of packets produced and create a duple corresponding to a single packet of audio data and include the packet description if we're dealing with a compressed format. Note the use of the `advanced(by:)` method on the `data` argument to make sure we're obtaining the audio data at the right byte offset. For uncompressed formats like **WAV** and **FLAC** we don't need any packet descriptions so we just set it to `nil`.

![](https://staticdelivery.nexusmods.com/mods/1151/images/thumbnails/2140-0-1448218648.jpg)

We've successfully completed writing our `Parser`, a concrete implementation of the `Parsing` protocol that can handle converting binary audio provided by a `Downloading` into audio packets thanks to the **Audio File Stream Services**. Note that these parsed audio packets are **not** guaranteed to be LPCM so if we're dealing with a compressed format like MP3 or AAC we still can't play these packets in an `AVAudioEngine`. In the next section we'll define a `Reading` protocol that will use a `Parsing` to get audio packets that we will then convert into a LPCM audio packets for our `AVAudioEngine` to play.

### <a name="readingprotocol"></a>The *Reading* protocol

To handle converting the audio packets from a `Parsing` into LPCM audio packets for our `AVAudioEngine` to read let's define a `Reading` protocol. 

```swift
public protocol Reading {
    
    // MARK: - Properties
    
    /// (1)
    var currentPacket: AVAudioPacketCount { get }

    /// (2)
    var parser: Parsing { get }    

    /// (3)
    var readFormat: AVAudioFormat { get }
	
	// MARK: - Initializers    

    /// (4)
    init(parser: Parsing, readFormat: AVAudioFormat) throws

	// MARK: - Methods    

    /// (5)
    func read(_ frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer
    
    /// (6)
    func seek(_ packet: AVAudioPacketCount) throws
}
```

In a `Reading` interface we'd expect the following properties: 

1. A `currentPacket` property representing the last read packet index. All future reads should start from here.
2. A `parser` property representing a `Parsing` that should be used to read the source audio packets from.
3. A `readFormat` property representing the LPCM audio format that the audio packets from a `Parsing` should be converted to. This LPCM format will be playable by the `AVAudioEngine`.

In addition, we specify an initializer: 

4. An `init(parser:,readFormat:)` method that takes in a `Parsing` to provide the source audio packets as well as an `AVAudioFormat` that will be the format the source audio packets are converted to.  

And finally, we define the two important methods:

5. A `read(_:)` method that provides an `AVAudioPCMBuffer` containing the LPCM audio data corresponding to the number of frames specified. This data will be obtained by pulling the audio packets from the `Parsing` and converting them into the LPCM format specified by the `readFormat` property.
6. A `seek(_:)` method that provides the ability to safely change the packet index specified by the `currentPacket` property. Specifically, when doing a seek operation we want to ensure we're not in the middle of a **read** operation.

### <a name="reader"></a>The *Reader*

Our `Reader` class is going to be a concrete implementation of the `Reading` protocol and use the [Audio Converter Services](https://developer.apple.com/documentation/audiotoolbox/audio_converter_services) API to convert the parsed audio packets into LPCM audio packets suitable for playback. Let's start by implementing the properties for the `Reading` protocol:

```swift
import AVFoundation

public class Reader: Reading {
    public internal(set) var currentPacket: AVAudioPacketCount = 0
    public let parser: Parsing
    public let readFormat: AVAudioFormat
}
```

Next we're going to define our converter and a queue to use to make sure our operations are thread-safe.

```swift
public class Reader: Reading {
     
    ...Reading properties

    /// An `AudioConverterRef` used to do the conversion from the source format of the `parser` (i.e. the `sourceFormat`) to the read destination (i.e. the `destinationFormat`). This is provided by the Audio Conversion Services (I prefer it to the `AVAudioConverter`)
    var converter: AudioConverterRef? = nil

    /// A `DispatchQueue` used to ensure any operations we do changing the current packet index is thread-safe
    private  let queue = DispatchQueue(label: "com.fastlearner.streamer")        

}
```

Next we're going to define the required initializer from the `Reading` protocol:

```swift
public class Reader: Reading {
   
    ...Properties
    
    public required init(parser: Parsing, readFormat: AVAudioFormat) throws {
        self.parser = parser
        
        guard let dataFormat = parser.dataFormat else {
            throw ReaderError.parserMissingDataFormat
        }

        let sourceFormat = dataFormat.streamDescription
        let commonFormat = readFormat.streamDescription
        let result = AudioConverterNew(sourceFormat, commonFormat, &converter)
        guard result == noErr else {
            throw ReaderError.unableToCreateConverter(result)
        }
        self.readFormat = readFormat
    }
    
    // Make sure we dispose the converter when this class is deallocated
    deinit {
        guard AudioConverterDispose(converter!) == noErr else {
            return
        }
    }
    
}
```

Note that when we try to create a new converter using `AudioConverterNew` we check it was created successfully. If not, then we throw an error to prevent a reader being created without a proper converter. We'll define the `ReaderError` values below:

```swift
public enum ReaderError: LocalizedError {
    case cannotLockQueue
    case converterFailed(OSStatus)
    case failedToCreateDestinationFormat
    case failedToCreatePCMBuffer
    case notEnoughData
    case parserMissingDataFormat
    case reachedEndOfFile
    case unableToCreateConverter(OSStatus)
}
```

Now we're ready to define our `read` method:

```swift
public class Reader: Reading {
   
    ...Properties

    ...Initializer
    
    public func read(_ frames: AVAudioFrameCount) throws -> AVAudioPCMBuffer {
        let framesPerPacket = readFormat.streamDescription.pointee.mFramesPerPacket
        var packets = frames / framesPerPacket
        
        /// (1)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: readFormat, frameCapacity: frames) else {
            throw ReaderError.failedToCreatePCMBuffer
        }
        buffer.frameLength = frames
        
        // (2)
        try queue.sync {
            let context = unsafeBitCast(self, to: UnsafeMutableRawPointer.self)
            let status = AudioConverterFillComplexBuffer(converter!, ReaderConverterCallback, context, &packets, buffer.mutableAudioBufferList, nil)
            guard status == noErr else {
                switch status {
                case ReaderMissingSourceFormatError:
                    throw ReaderError.parserMissingDataFormat
                case ReaderReachedEndOfDataError:
                    throw ReaderError.reachedEndOfFile
                case ReaderNotEnoughDataError:
                    throw ReaderError.notEnoughData
                default:
                    throw ReaderError.converterFailed(status)
                }
            }
        }
        return buffer
    }

}
```

This may look like a lot, but let's break it down. 

1. First we allocate an `AVAudioPCMBuffer` to hold the target audio data in the read format.
2. Next we use the `AudioConverterFillComplexBuffer()` method to fill the buffer allocated in step (1) with the requested number of frames. Similar to how we did with the `Parser`, we'll define a static C method called `ReaderConverterCallback` for providing the source audio packets needed in the LPCM conversion. We'll define the converter callback method soon, but note that we wrap the conversion operation with a synchronous queue to ensure thread-safely since we will be modifying the `currentPacket` property within the converter callback.

Finally let's define the seek method:

```swift
public class Reader: Reading {

    ...Properties

    ...Initializer

    ...Read

    public func seek(_ packet: AVAudioPacketCount) throws {
        queue.sync {
            currentPacket = packet
        }
    }
    
}
```

Short and sweet! All we do is set the current packet to the one specified, but wrap it in a synchronous queue to make it thread-safe.

Now we're ready to define our converter callback `ReaderConverterCallback`:

#### <a name="readerconvertercallback"></a>The *ReaderConverterCallback*

```swift
func ReaderConverterCallback(_ converter: AudioConverterRef,
                             _ packetCount: UnsafeMutablePointer<UInt32>,
                             _ ioData: UnsafeMutablePointer<AudioBufferList>,
                             _ outPacketDescriptions: UnsafeMutablePointer<UnsafeMutablePointer<AudioStreamPacketDescription>?>?,
                             _ context: UnsafeMutableRawPointer?) -> OSStatus {
    let reader = Unmanaged<Reader>.fromOpaque(context!).takeUnretainedValue()
    
    // (1)
    guard let sourceFormat = reader.parser.dataFormat else {
        return ReaderMissingSourceFormatError
    }
    
    // (2)
    let packetIndex = Int(reader.currentPacket)
    let packets = reader.parser.packets
    let isEndOfData = packetIndex >= packets.count - 1
    if isEndOfData {
        if reader.parser.isParsingComplete {
            packetCount.pointee = 0
            return ReaderReachedEndOfDataError
        } else {
            return ReaderNotEnoughDataError
        }
    }
    
    // (3)
    let packet = packets[packetIndex]
    var data = packet.0
    let dataCount = data.count
    ioData.pointee.mNumberBuffers = 1
    ioData.pointee.mBuffers.mData = UnsafeMutableRawPointer.allocate(byteCount: dataCount, alignment: 0)
    _ = data.withUnsafeMutableBytes { (bytes: UnsafeMutablePointer<UInt8>) in
        memcpy((ioData.pointee.mBuffers.mData?.assumingMemoryBound(to: UInt8.self))!, bytes, dataCount)
    }
    ioData.pointee.mBuffers.mDataByteSize = UInt32(dataCount)
    
    // (4)
    let sourceFormatDescription = sourceFormat.streamDescription.pointee
    if sourceFormatDescription.mFormatID != kAudioFormatLinearPCM {
        if outPacketDescriptions?.pointee == nil {
            outPacketDescriptions?.pointee = UnsafeMutablePointer<AudioStreamPacketDescription>.allocate(capacity: 1)
        }
        outPacketDescriptions?.pointee?.pointee.mDataByteSize = UInt32(dataCount)
        outPacketDescriptions?.pointee?.pointee.mStartOffset = 0
        outPacketDescriptions?.pointee?.pointee.mVariableFramesInPacket = 0
    }
    packetCount.pointee = 1
    reader.currentPacket = reader.currentPacket + 1
    
    return noErr;
}
```

1. Make sure we have a valid source format so we know the data format of the parser's audio packets
2. We check to make sure we haven't reached the end of the data we have available in the parser. The two scenarios where this could occur is if we've reached the end of the file or we've reached the end of the data we currently have downloaded, but not the entire file. 
3. We grab the packet available at the current packet index and fill in the `ioData` object with the contents of that packet. Note that we're providing the packet data 1 packet at a time.
4. If we're dealing with a compressed format then we also must provide the packet descriptions so the **Audio Converter Services** can use it to appropriate convert those samples to LPCM. 

That wraps up our `Reader` implementation. At this point we've implemented the logic we need to download a file and get LPCM audio that we can feed into an `AVAudioEngine`. Let's move on to our `Streaming` interface. 

### <a name="streamingprotocol"></a>The *Streaming* protocol

The `Streaming` protocol will perform playback an `AVAudioEngine` via a `AVAudioPlayerNode`, and handle the flow of data between a `Downloading`, `Parsing`, and `Reading`. 

```swift
public protocol Streaming: class {
    
    // MARK: - Properties
    
    /// (1)
    var currentTime: TimeInterval? { get }
    
    /// (2)
    var delegate: StreamingDelegate? { get set }
    
    /// (3)
    var duration: TimeInterval? { get }
    
    /// (4)
    var downloader: Downloading { get }
    
    /// (5)
    var parser: Parsing? { get }
    
    /// (6)
    var reader: Reading? { get }
    
    /// (7)
    var engine: AVAudioEngine { get }
    
    /// (8)
    var playerNode: AVAudioPlayerNode { get }
    
    /// (9)
    var readBufferSize: AVAudioFrameCount { get }
    
    /// (10)
    var readFormat: AVAudioFormat { get }
    
    /// (11)
    var state: StreamingState { get }
    
    /// (12)
    var url: URL? { get }
    
    /// (13)
    var volume: Float { get set }
    
    // MARK: - Methods
    
    /// (14)
    func play()
    
    /// (15)
    func pause()
    
    /// (16)
    func stop()
    
    /// (17)
    func seek(to time: TimeInterval) throws
    
}
```

There's a lot going on above so let's break down what's going on starting with the properties:

1. A `currentTime` property representing the current play time in seconds.
2. A `delegate` property that allows another class to respond to changes to the streamer. See the `StreamingDelegate` interface below.
3. A `duration` property representing the current duration time in seconds.
4. A `downloader` property that represents the `Downloading` instance used to pull the binary audio data.
5. A `parser` property that represents the `Parsing` instance used to convert the binary audio data from the `downloader` into audio packets.
6. A `reader` property that represents the `Reading` instance used to convert the parsed audio packets from the `parser` into LPCM audio packets for playback.
7. An `engine` property that represents the `AVAudioEngine` we're using to actually perform the playback.
8. A `playerNode` property that represents the `AVAudioPlayerNode` that we will use to schedule the LPCM audio packets from the `reader` for playback into the `engine`.
9. A `readBufferSize` property representing how many frames of LPCM audio should be scheduled onto the `playerNode`.
10. A `readFormat`  property representing a LPCM audio format that will be used by the `engine` and `playerNode`. This is the target format the `reader` will convert the audio packets coming from the `parser` to.
11. A `state` property that represents the current state of the streamer. The `StreamingState` is defined below.
12. A `url` property representing the URL (i.e. internet link) of the current audio file being streamed.
13. A `volume` property representing the current volume of the `engine`. Our demo app doesn't expose a UI for this, but if you wanted a user interface that allowed adjusting the volume you'd want this.

Phew! So those are all the properties we needed to define our `Streaming` protocol. Next we need to define the four most common audio player properties you're likely to find. 

14. A `play()` method that will begin audio playback.
15. A `pause()` method that will be used to pause the audio playback. 
16. A `stop()` method that will be used to stop the audio playback (go back to the beginning and deallocate all scheduled buffers in the `playerNode`).
17. A `seek(to:)` method that will allow us to seek to different portions of the audio file. 

Let's quickly define the `StreamingDelegate` and the `StreamingState` we mentioned above. 

#### <a name="streamingdelegate"></a>The *StreamingDelegate*

```swift
public protocol StreamingDelegate: class {
    func streamer(_ streamer: Streaming, failedDownloadWithError error: Error, forURL url: URL)
    func streamer(_ streamer: Streaming, updatedDownloadProgress progress: Float, forURL url: URL)
    func streamer(_ streamer: Streaming, changedState state: StreamingState)
    func streamer(_ streamer: Streaming, updatedCurrentTime currentTime: TimeInterval)
    func streamer(_ streamer: Streaming, updatedDuration duration: TimeInterval)   
}
```

#### <a name="streamingstate"></a>The *StreamingState*

```swift
public enum StreamingState: String {
    case stopped
    case paused
    case playing
}
```

Finally, we can create an extension on the `Streaming` protocol to define a default `readBufferSize` and `readFormat` that should work most of the time. 

```swift
extension Streaming {
    
    public var readBufferSize: AVAudioFrameCount {
        return 8192
    }
    
    public var readFormat: AVAudioFormat {
        return AVAudioFormat(commonFormat: .pcmFormatFloat32, sampleRate: 44100, channels: 2, interleaved: false)!
    }
    
}
```

### <a name="streamer"></a>The *Streamer*

Now that we've defined the `Streaming` protocol, as well as concrete classes implementing the `Downloading`, `Parsing`, and `Reading` protocols (the `Downloader`, `Parser`, and `Reader`, respectively), we're now ready to implement our `AVAudioEngine`-based streamer! Like we've done before, let's start by defining the `Streaming` properties:

```swift
/// (1)
open class Streamer: Streaming {

	/// (2)
    public var currentTime: TimeInterval? {
        guard let nodeTime = playerNode.lastRenderTime,
            let playerTime = playerNode.playerTime(forNodeTime: nodeTime) else {
            return nil
        }
        let currentTime = TimeInterval(playerTime.sampleTime) / playerTime.sampleRate
        return currentTime + currentTimeOffset
    }
    
    public var delegate: StreamingDelegate?
    public internal(set) var duration: TimeInterval?
    public lazy var downloader: Downloading = {
        let downloader = Downloader()
        downloader.delegate = self
        return downloader
    }()
    public internal(set) var parser: Parsing?
    public internal(set) var reader: Reading?
    public let engine = AVAudioEngine()
    public let playerNode = AVAudioPlayerNode()
    public internal(set) var state: StreamingState = .stopped {
        didSet {
            delegate?.streamer(self, changedState: state)
        }
    }
    
    /// (3)
    public var url: URL? {
        didSet {
            reset()

            if let url = url {
                downloader.url = url
                downloader.start()
            }
        }
    }
    
    // (4)
    public var volume: Float {
        get {
            return engine.mainMixerNode.outputVolume
        }
        set {
            engine.mainMixerNode.outputVolume = newValue
        }
    }
    
}
```

Above we define quite a few properties. Specifically I wanted to touch on a few things that are important to note at this point. 

1. Instead of being a `public` class we're making the `Streamer` an `open` class. This is because we intend on subclassing it later and only want the base implementation to worry about setting up the essentials for our `engine` and coordinating the `downloader`, `parser`, and `reader`. . In order to implement the time-pitch shifting (or any other combination of effects) streamer we will later subclass the `Streamer` and override a few methods to attach and connect different effect nodes.
2. The `currentTime` is calculated using the `sampleTime` of the `playerNode`. When a `seek` operation is performed the player node's sample time actually gets reset to 0 because we call the `stop()` method on it so we need to store another variable that has our current time offset. We will define that offset as `currentTimeOffset`
3. Whenever a new `url` is set on the `Streamer` we're going to define a `reset()` method that will allow us to reset the playback state and deallocate all resources relating to the current `url`.
4. We provide get/set access to the volume by setting the volume property of the main mixer node of the `AVAudioEngine`. 

Now let's define the rest of the properties we will need inside the `Streamer`.

```swift
open class Streamer: Streaming {

    ...Streaming Properties

    /// A `TimeInterval` used to calculate the current play time relative to a seek operation.
    var currentTimeOffset: TimeInterval = 0
    
    /// A `Bool` indicating whether the file has been completely scheduled into the player node.
    var isFileSchedulingComplete = false
    
}
```

Before we implement the methods from the `Streaming` protocol let's first define a default initializer as well as some helpful setup methods.

```swift
open class Streamer: Streaming {

    ...Properties

    public init() {        
        setupAudioEngine()
    }
    
    func setupAudioEngine() {
        // (1)
        attachNodes()

        // (2)
        connectNodes()

        // (3)
        engine.prepare()

        /// (4)
        let interval = 1 / (readFormat.sampleRate / Double(readBufferSize))
        Timer.scheduledTimer(withTimeInterval: interval / 2, repeats: true) {
            [weak self] _ in
            
            // (5)
            self?.scheduleNextBuffer()
            
            // (6)
            self?.handleTimeUpdate()
            
            // (7)
            self?.notifyTimeUpdated()
            
        }
    }

    open func attachNodes() {
        engine.attach(playerNode)
    }
    
    open func connectNodes() {
        engine.connect(playerNode, to: engine.mainMixerNode, format: readFormat)
    }
    
	func handleTimeUpdate() {
        guard let currentTime = currentTime, let duration = duration else {
            return
        }

        if currentTime >= duration {
            try? seek(to: 0)
            stop()
        }
    }

    func notifyTimeUpdated() {
        guard engine.isRunning, playerNode.isPlaying else {
            return
        }

        guard let currentTime = currentTime else {
            return
        }

        delegate?.streamer(self, updatedCurrentTime: currentTime)
    }
    
}
```

When we initialize our `Streamer` we begin by attaching and connecting the nodes we need within the `AVAudioEngine`. Here's a breakdown of the steps:

1. We attach the nodes we intend on using within the engine. In our basic `Streamer` this is just the `playerNode` that we will use to schedule the LPCM audio buffers from the `reader`. Since our time-pitch subclass will need to attach more nodes we'll mark this method as `open` so our subclass can override it.
2. We connect the nodes we've attach to the `engine`. Right now all we do is attach the `playerNode` to the main mixer node of the `engine`. Since our time-pitch subclass will need to connect the nodes a little differently so we'll also mark this method as `open` so our subclass can override it.
3. We prepare the `engine`. This step preallocates all resources needed by the `engine` to immediately start playback. 
4. We create a scheduled timer that will give us a runloop to periodically keep scheduling buffers onto the `playerNode` and update the current time. 
5. Every time the timer fires we should schedule a new buffer onto the `playerNode`. We will define this method in the next section after we implement the `DownloadingDelegate` methods. 
6. Every time the timer fires we check if the whole audio file has played by comparing the `currentTime` to the `duration`. If so, then we seek to the beginning of the data and stop playback.
7. We notify the current playback time has updated using the `streamer(_:, updatedCurrentTime:)` method on the `delegate`. 

Next we're going to define a `reset()` method to allow us to reset the state of the `Streamer`. We'll need this anytime we load a new `url`.

```swift
open class Streamer: Streaming {

    ...Properties

    ...Initializer + Setup

    func reset() {
    
        // (1)
        stop()
		
		// (2)
        duration = nil
        reader = nil
        isFileSchedulingComplete = false
        state = .stopped
        
        // (3)
        do {
            parser = try Parser()
        } catch {
			print("Failed to create parser: \(error.localizedDescription)")
        }
    }
    
}
```

Here's a quick recap of what's happening here:

1. We stop playback completely.
2. We reset all values used that were related to the current file.
3. We create a new `parser` in anticipation of new audio data coming from the `downloader`. There is exactly one `parser` per audio file because it progressively produces audio packets that are related to the data format of the audio it initially started parsing. 

Now that we have our setup and reset methods defined, let's go ahead and implement the required methods from the `DownloadingDelegate` protocol since the `downloader` property of the `Streamer` sets its delegate equal to the `Streamer` instance.

#### <a name="implementdownloadingdelegate"></a>Implementing The *DownloadingDelegate* protocol

```swift
extension Streamer: DownloadingDelegate {
    
    public func download(_ download: Downloading, completedWithError error: Error?) {
    
        // (1)
        if let error = error, let url = download.url {
            delegate?.streamer(self, failedDownloadWithError: error, forURL: url)
        }
        
    }
    
    public func download(_ download: Downloading, changedState downloadState: DownloadingState) {
        // Nothing for now
    }
    
    public func download(_ download: Downloading, didReceiveData data: Data, progress: Float) {
    
        // (2)
        guard let parser = parser else {
            return
        }
        
        // (3)
        do {
            try parser.parse(data: data)
        } catch {
            print("Parser failed to parse: \(error.localizedDescription)")
        }
        
        // (4)
        if reader == nil, let _ = parser.dataFormat {
            do {
                reader = try Reader(parser: parser, readFormat: readFormat)
            } catch {
                print("Failed to create reader: \(error.localizedDescription)")
            }
        }
        
        /// Update the progress UI
        DispatchQueue.main.async {
            [weak self] in
            
            // (5)
            self?.notifyDownloadProgress(progress)
            
            // (6)
            self?.handleDurationUpdate()
        }
    }
    
    func notifyDownloadProgress(_ progress: Float) {
        guard let url = url else {
            return
        }
        delegate?.streamer(self, updatedDownloadProgress: progress, forURL: url)
    }

    func handleDurationUpdate() {

        // (7)        
        if let newDuration = parser?.duration {
            var shouldUpdate = false
            if duration == nil {
                shouldUpdate = true
            } else if let oldDuration = duration, oldDuration < newDuration {
                shouldUpdate = true
            }
            
            // (8)
            if shouldUpdate {
                self.duration = newDuration
                notifyDurationUpdate(newDuration)
            }
        }
        
    }

    func notifyDurationUpdate(_ duration: TimeInterval) {
        guard let _ = url else {
            return
        }
        delegate?.streamer(self, updatedDuration: duration)
    }
}
```

The majority of our focus in this section is in the `download(_:,didReceiveData:progress:)`, but let's do a quick recap of the main points above:

1. When the download completes we check if it failed and, if so, we call the `streamer(_:,failedDownloadWithError:forURL:)` on the `delegate` property.
2. As we're receiving data we first check if we have a non-nil `parser`. Note that every time we set a new `url` our `reset()` method gets called, which defines a new `parser` instance to use. 
3. We attempt to parse the binary audio data into audio packets using the `parser`.
4. If the `reader` property is nil we check if the `parser` has parsed enough data to have a `dataFormat` defined. Note that the `Parser` class we've defined earlier uses the **Audio File Stream Services**, which progressively parses the binary audio data into properties first and then audio packets. Once we have a valid `dataFormat` on the `parser` we can create an instance of the `reader` by passing in the `parser` and the `readFormat` we previously defined in the `Streaming` protocol. As mentioned before, the `readFormat` must be the LPCM format we expect to use in the `playerNode`.
5. We notify the download progress has updated using the `streamer(_:, updatedDownloadProgress:,forURL:)` method on the `delegate`. 
6. We check if the value of the duration has changed. If so then we notify the delegate using the `streamer(_:updatedDuration:)` method.
7. We check if the `parser` has its `duration` property defined. Since the `parser` is progressively parsing more and more audio data its `duration` property may keep increasing (such as when we're dealing with live streams). 
8. If the new duration value is greater than the previous duration value we notify the `delegate` of the `Streamer` using the `streamer(_,updatedDuration:)` method.

That completes our implementation of the `DownloadingDelegate`. Using our `downloader` we're able to pull the binary audio data corresponding to the `url` property and parse it using the `parser`. When our `parser` has enough data to define a `dataFormat` we create a `reader` we can then use for scheduling buffers onto the `playerNode`. 

Let's go ahead and define the `scheduleNextBuffer()` method we used earlier in the `Timer` of the  `setupAudioEngine()` method.

##### <a name="schedulingbuffers"></a>Scheduling Buffers

```swift
open class Streamer: Streaming {

    ...Properties

    ...Initializer + Setup

    ...Reset
    
    func scheduleNextBuffer() {
        
        // (1)
        guard let reader = reader else {
            return
        }
        
        // (2)
        guard !isFileSchedulingComplete else {
            return
        }

        do {
            
            // (3)
            let nextScheduledBuffer = try reader.read(readBufferSize)
            
            // (4)
            playerNode.scheduleBuffer(nextScheduledBuffer)
            
        } catch ReaderError.reachedEndOfFile {
        
            // (5)
            isFileSchedulingComplete = true
            
        } catch {
            print("Reader failed to read: \(error.localizedDescription)")
        }
        
    }

}
```

Let's break this down:

1. We first check the `reader` is not `nil`. Remember the `reader` is only initialized when the `parser` has parsed enough of the downloaded audio data to have a valid `dataFormat` property.
2. We check our `isFileSchedulingComplete` property to see if we've already scheduled the entire file. If so, all the buffers for the file have been scheduled onto the `playerNode` and our work is complete.
3. We obtain the next buffer of LPCM audio from the `reader` by passing in the `readBufferSize` property we defined in the `Streaming` protocol. This is the step where the `reader` will attempt to read the number of audio frames using the audio packets from the `parser` and convert them into LPCM audio packets to return a `AVAudioPCMBuffer`.
4. We schedule the next buffer of LPCM audio data (i.e. the `AVAudioPCMBuffer` returned from the `reader`'s `read()` method) onto the `playerNode`. 
5. If the `reader` throws a `ReaderError.reachedEndOfFile` error then we set the `isFileSchedulingComplete` property to true so we know we shouldn't attempt to read anymore buffers from the `reader`.

Great! At the point we've implemented all the logic we need for scheduling the audio data specified by the `url` property onto our `playerNode` in the correct LPCM format. As a result, if the audio file at the `url` specified is in an MP3 or AAC compressed format our `reader` will properly handle the format conversion required to read the compressed packets on the fly. 

#### <a name="playbackmethods"></a>Playback Methods

We're now ready to implement the playback methods from the `Streaming` protocol. As we implement these methods we'll go one-by-one to make sure we handle all edge cases. Let's start with `play()`:

##### <a name="implementingplay"></a>Play

```swift
open class Streamer: Streaming {

    ...Properties

    ...Initializer + Setup

    ...Reset

    ...Schedule Buffers
    
	public func play() {
	
        // (1)
        guard !playerNode.isPlaying else {
            return
        }
        
        // (2)
        if !engine.isRunning {
            do {
                try engine.start()
            } catch {
                print("Engine failed to start: \(error.localizedDescription)")
                return
            }
        }
        
        // (3)
        playerNode.play()
        
        // (4)
        state = .playing
        
    }	
	
}
```

Here's a recap of our `play()` method:

1. We check if the `playerNode` is already playing and, if so, we are already done.
2. We check if the `engine` is running and if it's not then we'll start it up. Since we called `engine.prepare()` in our `setupAudioEngine` method above this call should be instant.
3. We tell the `playerNode` to `play()`, which begins playing out any LPCM audio buffers that have been scheduled onto it.
4. We update the state to `playing` (this will trigger the `streamer(_,changedState:)` method in the `delegate`).

##### <a name="implementingpause"></a>Pause

Next we'll implement the `pause` method. 

```swift
open class Streamer: Streaming {

    ...Properties

    ...Initializer + Setup

    ...Reset
    
    ...Schedule Buffers
    
	...Play

    public func pause() {

        // (1)
        guard playerNode.isPlaying else {
            return
        }
        
        // (2)
        playerNode.pause()
        engine.pause()
        
        // (3)
        state = .paused
        
    }
	
}
```

Nothing crazy here, here's the recap:

1. We check that the `playerNode` is not playing and, if so, we're already done.
2. We pause both the `playerNode` as well as the `engine`. When we pause the `playerNode` we're also pausing its `sampleTime`, which allows us to have an accurate `currentTime` property.
3. We update the state to `paused` (this will trigger the `streamer(_,changedState:)` method in the `delegate`).

##### <a name="implementingstop"></a>Stop

Next let's implement the `stop()` method:

```swift
open class Streamer: Streaming {

    ...Properties

    ...Initializer + Setup

    ...Reset

    ...Schedule Buffers
    
	...Play

    ...Pause

    public func stop() {
    
        // (1)
        downloader.stop()

		// (2)
        playerNode.stop()
        engine.stop()
        
        // (3)
        state = .stopped
        
    }	

}
```

Again, we're not doing anything crazy here, but it's good we understand why each step is necessary.

1. We stop the `downloader`, which may currently be downloading audio data. 
2. We stop the `playerNode` and the `engine`. By doing this the `playerNode` will release all scheduled buffers and change its `sampleTime` to 0. Calling `stop` on the `engine` releases any resources allocated in the `engine.prepare()` method.
3. 3. We update the state to `stopped` (this will trigger the `streamer(_,changedState:)` method in the `delegate`).

##### <a name="implementingseek"></a>Seek

Next let's implement our `seek(to:)` method. This will allow us to skip around to different parts of the file.

```swift
open class Streamer: Streaming {

    ...Properties

    ...Initializer + Setup

    ...Reset

    ...Schedule Buffers
    
	...Play

    ...Pause

    ...Stop

	public func seek(to time: TimeInterval) throws {
	        
        // (1)
        guard let parser = parser, let reader = reader else {
            return
        }
        
        // (2)
        guard let frameOffset = parser.frameOffset(forTime: time),
            let packetOffset = parser.packetOffset(forFrame: frameOffset) else {
                return
        }

		// (3)
        currentTimeOffset = time

		// (4)
        isFileSchedulingComplete = false
        
        // (5)
        let isPlaying = playerNode.isPlaying
        
        // (6)
        playerNode.stop()
        
        // (7)
        do {
            try reader.seek(packetOffset)
        } catch {
            // Log error
            return
        }
        
        // (8)
        if isPlaying {
            playerNode.play()
        }
        
        // (9)
        delegate?.streamer(self, updatedCurrentTime: time)
        
    }

}
```

There's a little bit more going on here, but let's break it down:

1. We make sure we have a `parser` and `reader` because we'll need both to convert and set the new current time value to a proper packet offset. 
2. We get the packet offset from the new current time value specified. We do this by first getting the frame offset using the `frameOffset(forTime:)` method on the parser. Then we use the `packetOffset(forFrame:)` to get the packet from the frame offset. We could've created a `packetOffset(forTime:)` method in the `Parsing` protocol, but I wanted to use this as a chance to demonstrate the conversion to frame and packets we typically need to perform to do a seek operation from seconds.
3. We store the new current time value as an offset to make sure our `currentTime` property has the proper offset from the beginning of the file. We do this because we're going to stop the `playerNode`, which causes its `sampleTime` to reset to 0 and we want to be sure we're reporting the `currentTime` after seek operations relative to the whole file. 
4. We reset the `isFileSchedulingComplete` property to false to make sure our `scheduleNextBuffer()` method starts scheduling audio buffers again relative to the new start position. Remember that when we call `stop` on the `playerNode` it releases all internally scheduled buffers. 
5. We check if the `playerNode` is currently playing to make sure we properly restart playback again once the `seek` operation is complete.
6. We call the `stop` method on the `playerNode` to release all schedule buffers and reset its `sampleTime`.
7. We call the `seek(_:)` method on the `reader` to make it sets the `currentPacket` property to the new packet offset. This will ensure that all future calls to its `read(_:)` method are done at the proper packet offset.
8. If the `playerNode` was previously playing we immediately resume playback.
9. We trigger the `streamer(_,updatedCurrentTime:)` method on the `delegate` to notify our receiver of the new current time value. 

That completes our `Streamer` class! [Click here](https://github.com/syedhali/AudioStreamer/tree/master/AudioStreamer/Streamer) to see the full source for the `Streamer` class and any extensions and custom enums we used above.

In the next section we're going to create a subclass of the `Streamer` that adds the time-pitch effect we promised in the example app. 

## <a name="buildingourtimepitchstreamer"></a>Building our *TimePitchStreamer*

In the previous section we demonstrated how to download, parse, and read back an audio file  for playback in an `AVAudioEngine`. We created the `Streamer` class to coordinate the `Downloader`, `Parser`, and `Reader` classes so we could go from downloading binary audio data, to making audio packets from that data, to converting those audio packets into LPCM audio packets on the fly so we could schedule it onto an `AVAudioPlayerNode`. In general, those are the typical steps we'd have to implement to playback an audio file without any added effects.

Now, let's go ahead and take it one step further. Here's how we'd implement a subclass of the `Streamer` to include the time-pitch effect in our demo application.

```swift
// (1)
final class TimePitchStreamer: Streamer {
    
    /// (2)
    let timePitchNode = AVAudioUnitTimePitch()
    
    /// (3)
    var pitch: Float {
        get {
            return timePitchNode.pitch
        }
        set {
            timePitchNode.pitch = newValue
        }
    }
    
    /// (4)
    var rate: Float {
        get {
            return timePitchNode.rate
        }
        set {
            timePitchNode.rate = newValue
        }
    }
    
    // (5)
    override func attachNodes() {
        super.attachNodes()
        engine.attach(timePitchNode)
    }
    
    // (6)
    override func connectNodes() {
        engine.connect(playerNode, to: timePitchNode, format: readFormat)
        engine.connect(timePitchNode, to: engine.mainMixerNode, format: readFormat)
    }
    
}
```

Here's what we've done:

1. First we create a `final` subclass of the `Streamer` called `TimePitchStreamer`. We mark the `TimePitchStreamer` as final because we don't want any other class to subclass it.
2. To perform the time-pitch shifting effect we're going to utilize the `AVAudioUnitTimePitch` node. This effect node's role is analogous to that of the Audio Unit in the `AUGraph` we discussed earlier. As a matter of fact, the `AVAudioUnitTimePitch` node sounds exactly like the `kAudioUnitSubType_NewTimePitch` Audio Unit effect subtype.
3. We expose a `pitch` property to provide a higher level way of adjusting the pitch of the `timePitchNode`. This is optional since this value can be set directly on the `timePitchNode` instance, but will be convenient in our UI. 
4. We expose a `rate` property to provide a higher level way of adjusting the playback rate of the `timePitchNode`. This is also optional since this value can be set directly on the `timePitchNode` instance, but will be convenient in our UI. 
5. We override the `attachNodes()` method from the `Streamer` to attach the `timePitchNode` to the `engine`. Notice we call super to make sure the `playerNode` is attached like in the `Streamer` superclass.
6. We override the `connectNodes()` method from the `Streamer` to connect the `playerNode` to the `timePitchNode` and then the `timePitchNode` to the `mainMixerNode` of the `engine`. In this case we don't call super because we don't want any of the connections from the `Streamer` superclass.

## <a name="buildingourui"></a>Building our UI

Now that we're done writing our pitch-shifting audio streamer we can move on to building out the user interface (UI) for our demo application. 

### <a name="implementingtheprogressslider"></a>Implementing the *ProgressSlider*

In our app we're mostly going to be using the standard controls included with `UIKit`, but since we'd like to give some visual feedback of what portion of the audio file has been downloaded and is playable/seekable we'll create a custom `UISlider` subclass called `ProgressSlider` that uses a `UIProgressView` subview to display the download progress as displayed below: 

![Progress slider](https://cdn.fastlearner.media/streaming-audio-progress-slider.gif)

Here's our implementation:

```swift
public class ProgressSlider: UISlider {
    
	// (1)
    private let progressView = UIProgressView(progressViewStyle: .default)
    
    /// (2)
    @IBInspectable public var progress: Float {
        get {
            return progressView.progress
        }
        set {
            progressView.progress = newValue
        }
    }
    
    /// (3)
    @IBInspectable public var progressTrackTintColor: UIColor {
        get {
            return progressView.trackTintColor ?? .white
        }
        set {
            progressView.trackTintColor = newValue
        }
    }
    
    /// (4)
    @IBInspectable public var progressProgressTintColor: UIColor {
        get {
            return progressView.progressTintColor ?? .blue
        }
        set {
            progressView.progressTintColor = newValue
        }
    }
    
    /// Setup / Drawing
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }
    
    // (5)
    func setup() {
        insertSubview(progressView, at: 0)
        
        let trackFrame = super.trackRect(forBounds: bounds)
        var center = CGPoint(x: 0, y: 0)
        center.y = floor(frame.height / 2 + progressView.frame.height / 2)
        progressView.center = center
        progressView.frame.origin.x = 2
        progressView.frame.size.width = trackFrame.width - 4
        progressView.autoresizingMask = [.flexibleWidth]
        progressView.clipsToBounds = true
        progressView.layer.cornerRadius = 2
    }
    
    // (6)
    public override func trackRect(forBounds bounds: CGRect) -> CGRect {
        var result = super.trackRect(forBounds: bounds)
        result.size.height = 0.01
        return result
    }

    // (7)
    public func setProgress(_ progress: Float, animated: Bool) {
        progressView.setProgress(progress, animated: animated)
    }
    
}
```

1. To display the download progress we're going to use a `UIProgressView`. We start by initializing a default instance of it.
2. We expose a `progress` property to provide a high level way of getting and setting the value of the `progressView`. By making it an `IBInspectable` property we allow setting this value from interface builder.
3. We expose a `progressTrackTintColor` property to provide a high level way of getting and setting the background tint color of the `progressView`. By making it an `IBInspectable` property we allow setting this value from interface builder.
4. We expose a `progressProgressTintColor` property to provide a high level way of getting and setting the foreground tint color of the `progressView`. By making it an `IBInspectable` property we allow setting this value from interface builder.
5. We implement a `setup()` method to add the `progressView` as a subview of the slider and adjust its bounds to match that of the slider's progress bar. 
6. We override the `trackRect(forBounds:)` method to return a `CGRect` with a near zero height because we want our `progressView` to display in front of the default bar of the `UISlider`.
7. We implement a `setProgress(_:,animated:)` method to allow programmatically setting the progress value of the `progressView` without giving direct access to the `progressView`. 

You can check out the full source code for the `ProgressSlider` class [here](https://github.com/syedhali/AudioStreamer/blob/master/AudioStreamer/UI/ProgressSlider.swift).

### <a name="implementingmmssformatter"></a>Implementing the mm:ss formatter

In audio players we frequently display time in a *mm:ss* format. For instance, two minutes and thirty seconds would be displayed as *02:30*. To do this in our app we'll write a quick helper extension on `TimeInterval` to convert seconds to a *mm:ss* `String`. 

```swift
extension TimeInterval {
    public func toMMSS() -> String {
        let ts = Int(self)
        let s = ts % 60
        let m = (ts / 60) % 60
        return String(format: "%02d:%02d", m, s)
    }
}
```

Here we're extracting the second and minute components and passing them into a formatted `String` that will always display two digits for each value. You'd be amazed how handy this method is in audio applications. The full source for this extension can be found [here](https://github.com/syedhali/AudioStreamer/blob/master/AudioStreamer/UI/TimeInterval%2BMMSS.swift). 

Another approach is to use the `DateComponentsFormatter` that will automatically handle padding zeros, hour components, etc. For instance, we could implement an HHMMSS (hours, minutes, seconds) format like:

```swift
extension TimeInterval {
    public func toHHMMSS() -> String {
		let formatter = DateComponentsFormatter()
		formatter.allowedUnits = [.hour, .minute, .second]
		formatter.unitsStyle = .positional
		formatter.zeroFormattingBehavior = .pad
		return formatter.string(from: self)!
    }
}
```

### <a name="implementingtheviewController"></a>Implementing the ViewController

We're now ready to implement the main UI for our time-pitch shifting app! Here's what you can expect to see when we're done:

![](https://cdn.fastlearner.media/streaming-audio-app-screenshot-smaller-v2.png)

If you haven't already go into Xcode and create a **Single View App**. In the Github repo for this project I've organized the code into two separate projects. The first is a framework called `AudioStreamer` that holds everything we've done so far related to the audio streaming logic and `ProgressSlider`. You can view the **AudioStreamer** framework's Xcode project [here](https://github.com/syedhali/AudioStreamer). 

The second is the actual demo project called **TimePitchStreamer** that uses the `AudioStreamer` framework as a subproject. You can view the **TimePitchStreamer** demo project [here](https://github.com/syedhali/AudioStreamer/tree/master/Examples/TimePitchStreamer). In Xcode this is what that looks like:

![](https://cdn.fastlearner.media/streaming-audio-directory-structure.png)

Next we're going to go ahead and implement the logic we need in our `ViewController` to bind the UI components to our audio streaming logic. Let's begin with the properties:

```swift
import UIKit
import AVFoundation
import AudioStreamer
import os.log

class ViewController: UIViewController {
    
    // (1)
    @IBOutlet weak var currentTimeLabel: UILabel!

	// (2)
    @IBOutlet weak var durationTimeLabel: UILabel!

    // (3)
    @IBOutlet weak var rateLabel: UILabel!
    
    // (4)
    @IBOutlet weak var rateSlider: UISlider!

    // (5)
    @IBOutlet weak var pitchLabel: UILabel!

    // (6)
    @IBOutlet weak var pitchSlider: UISlider!

    // (7)
    @IBOutlet weak var playButton: UIButton!

    // (8)
    @IBOutlet weak var progressSlider: ProgressSlider!
    
    // (9)
    lazy var streamer: TimePitchStreamer = {
        let streamer = TimePitchStreamer()
        streamer.delegate = self
        return streamer
    }()
    
    // (10)
    var isSeeking = false    

}
```

1. A label we'll use for displaying the current time of the streamer. 
2. A label we'll use for displaying the total duration of the file.
3. A label we'll use for displaying the rate of the streamer. This will correspond to the `rate` property of the `TimePitchStreamer` class we defined above.
4. A slider we'll use to change the rate of the streamer. As in (3) this will correspond to the `rate` property of the `TimePitchStreamer` class we defined above.
5. A label we'll use for displaying the pitch of the streamer. This will correspond to the `pitch` property of the `TimePitchStreamer` class we defined above.
6. A slider we'll use to change the pitch of the streamer. As in (5) this will correspond to the `pitch` property of the `TimePitchStreamer` class we defined above.
7. A button we'll use to toggle between play/pause.
8. A slider we'll use to change the seek position in the file. In addition, we'll use it to display the current time and the download progress of the file since we're using the `ProgressSlider` class we defined above. 
9. An instance of the `TimePitchStreamer` we're going to use to perform the audio streaming. 
10. A flag we'll use to determine if the slider is currently seeking so we can seek once when the user lifts their finger, but still update the current time label continuously. We'll use the touch down event on the `ProgressSlider` to set this to true and then set it back to false using the touch up event. 

Let's now implement the logic to setup the `ViewController`:

```swift
class ViewController: UIViewController {
    
    ...Properties
  
    // (1)
    override func viewDidLoad() {
        super.viewDidLoad()

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playback, mode: .default, policy: .default, options: [.allowBluetoothA2DP,.defaultToSpeaker])
            try session.setActive(true)
        } catch {
            print("Failed to activate audio session: \(error.localizedDescription)")
        }
        
        resetPitch(self)
        resetRate(self)
        
        let url = URL(string: "https://cdn.fastlearner.media/bensound-rumble.mp3")!
        streamer.url = url
    }

    // (2)
    @IBAction func resetPitch(_ sender: Any) {
        let pitch: Float = 0
        streamer.pitch = pitch
        pitchSlider.value = pitch
        pitchLabel.text = String(format: "%i cents", Int(pitch))
    }
    
    // (3)
    @IBAction func resetRate(_ sender: Any) {
        let rate: Float = 1
        streamer.rate = rate
        rateSlider.value = rate
        rateLabel.text = String(format: "%.2fx", rate)
    }
    
}
```

1. In our `viewDidLoad` method we setup the `AVAudioSession` first using the `AVAudioSessionCategoryPlayback` category and setting it active. Next we reset the pitch and rate UI by calling the respective `resetPitch` and `resetRate` methods. Last we set the URL of Rumble onto the `TimePitchStreamer` instance so it can begin downloading and decoding that file's data using its internal `Downloader` and `Parser`. 
2. We set the value of the pitch on the streamer, the pitch slider, and pitch label to 0 (no change). 
3. We set the value of the rate on the streamer, the rate slider, and rate label to 1 (normal playback). 

Now we're ready to implement the rest of our `IBAction` methods we'll need for our UI components. 

```swift
class ViewController: UIViewController {
    
    ...Properties

    ...Setup And Reset Methods
  
    // (1)
    @IBAction func togglePlayback(_ sender: UIButton) {
        if streamer.state == .playing {
            streamer.pause()
        } else {
            streamer.play()
        }
    }
    
    // (2)
    @IBAction func seek(_ sender: UISlider) {
        do {
            let time = TimeInterval(progressSlider.value)
            try streamer.seek(to: time)
        } catch {
            print("Failed to seek: \(error.localizedDescription)")
        }
    }
    
    // (3)
    @IBAction func progressSliderTouchedDown(_ sender: UISlider) {
        isSeeking = true
    }

    // (4)    
    @IBAction func progressSliderValueChanged(_ sender: UISlider) {
        let currentTime = TimeInterval(progressSlider.value)
        currentTimeLabel.text = currentTime.toMMSS()
    }
    
    // (5)
    @IBAction func progressSliderTouchedUp(_ sender: UISlider) {
        seek(sender)
        isSeeking = false
    }
    
    // (6)
    @IBAction func changePitch(_ sender: UISlider) {
        let step: Float = 100
        var pitch = roundf(pitchSlider.value)
        let newStep = roundf(pitch / step)
        pitch = newStep * step
        streamer.pitch = pitch
        pitchSlider.value = pitch
        pitchLabel.text = String(format: "%i cents", Int(pitch))
    }
    
    // (7)
    @IBAction func changeRate(_ sender: UISlider) {
        let step: Float = 0.25
        var rate = rateSlider.value
        let newStep = roundf(rate / step)
        rate = newStep * step
        streamer.rate = rate
        rateSlider.value = rate
        rateLabel.text = String(format: "%.2fx", rate)
    }
    
}
```

1. Depending on whether the streamer is currently playing or paused we'll toggle the opposite state. 
2. We perform a seek operation using the current time from the progress slider. 
3. When the progress slider is first touched down we set the `isSeeking` flag to `true`. 
4. As the value of the progress slider changes we update the value of the current time label. This makes sure the current time label is in sync with the slider so we can see the exact time value we're attempting to set before actually performing the seek operation. 
5. When the progress slider is touched up we perform the seek operation and set the `isSeeking` flag to `false`.
6. When we change the pitch we're going to round it to 100 cent (i.e. a half step) intervals to make it more musical. If we were a singer adjusting the pitch to our range this would be the expected behavior of a pitch shifter.
7. When we change the rate we're going to round it to 0.25 step intervals to make it reflect typical playback rates seen in various music and podcast apps.   

#### <a name="implementingthestreamingdelegate"></a>Implementing the *StreamingDelegate*

Note that earlier we set the `ViewController` as the delegate of the `TimePitchStreamer`. Let's go ahead and implement the methods of the `StreamingDelegate` now:

```swift
extension ViewController: StreamingDelegate {
    
    // (1)
    func streamer(_ streamer: Streaming, failedDownloadWithError error: Error, forURL url: URL) {
        let alert = UIAlertController(title: "Download Failed", message: error.localizedDescription, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            alert.dismiss(animated: true, completion: nil)
        }))
        show(alert, sender: self)
    }
    
    // (2)
    func streamer(_ streamer: Streaming, updatedDownloadProgress progress: Float, forURL url: URL) {
        progressSlider.progress = progress
    }
    
    // (3)
    func streamer(_ streamer: Streaming, changedState state: StreamingState) {
        switch state {
        case .playing:
            playButton.setImage(#imageLiteral(resourceName: "pause"), for: .normal)
        case .paused, .stopped:
            playButton.setImage(#imageLiteral(resourceName: "play"), for: .normal)
        }
    }
    
    // (4)
    func streamer(_ streamer: Streaming, updatedCurrentTime currentTime: TimeInterval) {
        if !isSeeking {
            progressSlider.value = Float(currentTime)
            currentTimeLabel.text = currentTime.toMMSS()
        }
    }
    
    // (5)
    func streamer(_ streamer: Streaming, updatedDuration duration: TimeInterval) {
        let formattedDuration = duration.toMMSS()
        durationTimeLabel.text = formattedDuration
        durationTimeLabel.isEnabled = true
        playButton.isEnabled = true
        progressSlider.isEnabled = true
        progressSlider.minimumValue = 0.0
        progressSlider.maximumValue = Float(duration)
    }
    
}
```

1. If the streamer fails to download the file we'll display a generic iOS alert. In our app this shouldn't happen unless your internet is disconnected, but occasionally you may find a URL you try to use is broken so check the URL is valid before trying to use it in the streamer.
2. As the streamer downloads more data we'll update the progress value of the progress slider. Note that we're using the custom `ProgressSlider` here that we implemented above that contains an embedded `UIProgressView` that will display the progress value. 
3. When the streamer changes state we'll switch between the play and pause icon on the play button. 
4. When the streamer updates its current time we'll update the value of the progress slider and current time label to reflect that. We use the `isSeeking` flag here to make sure the user isn't manually performing a seek, in which case we'd give preference to the user interaction.
5. When the streamer updates its duration value we're going to update the duration label, enable the play button, and reset the progress slider's min and max values. 

That wraps up our `ViewController` implementation. The last thing we have left to do for our app is add the UI components to the `Main.storyboard` and hook them up to the `IBAction` methods we defined  in this section.   

### <a name="implementingthestoryboard"></a>Implementing the Storyboard

Laying out each component in interface builder is a bit beyond the scope of this article, but here's what the structure of the `Main.storyboard` looks like. Note we're making use of the `UIStackView` to evenly space each section (pitch, rate, playback). 

![](https://user-images.githubusercontent.com/1275640/46567370-99f13800-c8f7-11e8-9af4-e314bb88d73b.png)

I encourage you to download the **TimePitchStreamer** Xcode project and explore the `Main.storyboard` file for the layout and constraints, but here's a gif demonstrating how we hooked up the controls to the properties and methods we just implemented in the `ViewController`:

![](https://cdn.fastlearner.media/avaudioengine-effects-ui-connections.gif)

Once this is complete you should be able to run the app and stream Rumble while changing the rate and pitch using the sliders in the UI. Once it's working try changing the URL to different files you or others may have hosted. 

## <a name="conclusion"></a>Conclusion

![huzzah](https://cdn.fastlearner.media/futurama-professor.gif)

Huzzah! You've now successfully created a time and pitch shifting audio streaming app!

I hope over the course of this article you learned all you wanted to (and maybe a little more) about modern iOS audio programming and streaming. The full source for this article can be found [here](https://github.com/syedhali/AudioStreamer). 

This article was originally written using **Objective-C** and an `AUGraph`-based approach for streaming and was updated to **Swift 4.2** and an `AVAudioEngine`-based approach after the `AUGraph` was deprecated in WWDC 2017.  I hope you all enjoyed it as much as I did writing it. 

## <a name="credits"></a>Credits

- <span>Icons: <a href="https://www.flaticon.com/authors/roundicons" title="Roundicons">Roundicons</a> from <a href="https://www.flaticon.com/" title="Flaticon">www.flaticon.com</a> is licensed by <a href="http://creativecommons.org/licenses/by/3.0/" title="Creative Commons BY 3.0" target="_blank">CC 3.0 BY</a></span>
- Music: [www.bensound.com](https://www.bensound.com/)
