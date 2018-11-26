Pod::Spec.new do |s|
  s.name         = "AudioStreamer"
  s.version      = "1.4.0"
  s.summary      = "A Swift 4 framework for streaming remote audio with real-time effects using AVAudioEngine"
  s.homepage     = "https://github.com/syedhali/AudioStreamer"
  s.screenshots  = "https://res.cloudinary.com/fast-learner/image/upload/v1527455500/blog/22/banner/1d9b0d3b-0998-4ad7-854e-4fb854b9955e.jpg"
  s.license      = { :type => "MIT", :file => "LICENSE" }
  s.author             = { "Syed Haris Ali" => "haris@ausomeapps.com" }
  s.social_media_url   = "http://twitter.com/h4ris4li"
  s.ios.deployment_target = "10.0"
  s.osx.deployment_target = "10.12"
  s.source       = { :git => "https://github.com/syedhali/AudioStreamer.git", :tag => "v#{s.version}" }
  s.source_files  = "AudioStreamer/**/*.{swift}"
  s.osx.exclude_files = "AudioStreamer/UI/ProgressSlider.swift"
  s.swift_version = "4.2"
  s.frameworks = "AVFoundation", "AudioToolbox"
  s.requires_arc = true
end
