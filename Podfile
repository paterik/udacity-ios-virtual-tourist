source 'https://github.com/CocoaPods/Specs.git'

platform :ios, '10.0'
use_frameworks!

def uiLibs
    pod 'BGTableViewRowActionWithImage'
    pod 'YNDropDownMenu'
    pod 'SnapKit', '~> 3.2.0'
end

def baseLibs
    pod 'CryptoSwift'
    pod 'Kingfisher', '~> 3.0'
end

def dataLibs
    pod 'CoreStore', '~> 4.0'
end

target 'VirtualTourist' do
    uiLibs
    baseLibs
    dataLibs
end
