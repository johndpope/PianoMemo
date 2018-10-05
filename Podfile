target 'Piano' do
  platform :ios, '11.0'
  use_frameworks!

  # Pods for Piano
  pod 'Differ', :git => 'https://github.com/tonyarnold/Differ', :branch => 'master'
  pod 'lottie-ios'
  pod 'DifferenceKit', :git => 'https://github.com/ra1028/DifferenceKit', :branch => 'master'
  pod 'BiometricAuthentication'

  target 'PianoTests' do
    inherit! :search_paths
    # Pods for testing
  end
  
end

target 'PianoMac' do
  platform :osx, '10.9'
  use_frameworks!

  # Pods for PianoMac
  pod 'MASShortcut', :inhibit_warnings => true
   
end
