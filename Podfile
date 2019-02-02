target 'Piano' do
  platform :ios, '11.0'
  use_frameworks!
  pod 'Reveal-SDK', :configurations => ['Debug']
  pod 'DifferenceKit'   
  pod 'ReachabilitySwift'
  pod 'OpenSSL-Universal', :git => 'https://github.com/krzyzanowskim/OpenSSL.git', :branch => :master
  pod 'Firebase/Core'
  pod 'Fabric', '~> 1.9.0'
  pod 'Crashlytics', '~> 3.12.0'
  pod 'SwiftLint'
  pod 'Amplitude-iOS', '~> 4.0.4', :inhibit_warnings => true
  pod 'Result'
  pod 'Kuery'
  
  target 'Tests' do
    inherit! :search_paths
  end  
  
end

target 'PianoMac' do
  platform :osx, '10.9'
  use_frameworks!
  
  pod 'MASShortcut', :inhibit_warnings => true

end
