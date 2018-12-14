target 'Piano' do
  platform :ios, '11.0'
  use_frameworks!
  pod 'BiometricAuthentication', :inhibit_warnings => true
  pod 'Reveal-SDK', :configurations => ['Debug']
  pod 'DifferenceKit'   
  pod 'ReachabilitySwift'
  pod 'Branch'
  pod 'OpenSSL-Universal', :git => 'https://github.com/krzyzanowskim/OpenSSL.git', :branch => :master
  pod 'Fabric'
  pod 'Crashlytics'
  pod 'Firebase/Core'
  # pod 'lottie-ios'
  
  target 'Tests' do
    inherit! :search_paths
  end  
  
end

target 'PianoMac' do
  platform :osx, '10.9'
  use_frameworks!
  
  pod 'MASShortcut', :inhibit_warnings => true

end
