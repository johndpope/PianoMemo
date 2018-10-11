target 'Piano' do
  platform :ios, '11.0'
  use_frameworks!
  pod 'BiometricAuthentication'
  pod 'Differ', :git => 'https://github.com/tonyarnold/Differ', :branch => 'master'

  target 'Tests' do
    inherit! :search_paths
  end  
  
end

target 'PianoMac' do
  platform :osx, '10.9'
  use_frameworks!
  
  pod 'MASShortcut', :inhibit_warnings => true

end
