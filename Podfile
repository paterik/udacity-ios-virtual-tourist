source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!

def dataLibs
    pod 'CoreStore', '~> 4.0'
    pod 'ObjectMapper', '~> 2.2'
end

def baseLibs
    pod 'BGTableViewRowActionWithImage'
    pod 'CryptoSwift'
    pod 'YNDropDownMenu'
    pod 'Kingfisher', '~> 3.0'
    pod 'SnapKit', '~> 3.2.0'
end

target 'VirtualTourist' do
    baseLibs
    dataLibs
end
