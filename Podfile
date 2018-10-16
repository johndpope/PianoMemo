target 'Piano' do
  platform :ios, '11.0'
  use_frameworks!
  pod 'BiometricAuthentication'
  pod 'Reveal-SDK', :configurations => ['Debug']

  target 'Tests' do
    inherit! :search_paths
  end  
  
end

target 'PianoMac' do
  platform :osx, '10.9'
  use_frameworks!
  
  pod 'MASShortcut', :inhibit_warnings => true

end
