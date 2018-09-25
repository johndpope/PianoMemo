target 'Piano' do
  platform :ios, '11.0'
  use_frameworks!

  # Pods for Piano
  pod 'Differ', :git => 'https://github.com/tonyarnold/Differ', :branch => 'master'
  pod 'lottie-ios'
  target 'PianoTests' do
    inherit! :search_paths
    # Pods for testing
  end

  target 'PianoUITests' do
    inherit! :search_paths
    # Pods for testing
  end
  
end

target 'PianoMac' do
  platform :osx, '10.9'
  use_frameworks!

  # Pods for PianoMac
  pod 'MASShortcut', :inhibit_warnings => true

  target 'PianoMacTests' do
    inherit! :search_paths
    # Pods for testing
  end
  
end
