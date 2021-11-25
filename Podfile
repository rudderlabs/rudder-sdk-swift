workspace 'Rudder.xcworkspace'
use_frameworks!
inhibit_all_warnings!

def shared_pods
    pod 'Rudder', :path => '.'
#    pod 'Rudder', :git => 'https://github.com/rudderlabs/rudder-sdk-cocoa.git', :commit => '4f886c3e2cee9d96d7b83e20d03540b527751636'
end

project 'Examples/RudderSampleAppObjC/RudderSampleAppObjC.xcodeproj'
project 'Examples/RudderSammpleAppSwift/RudderSammpleAppSwift.xcodeproj'
project 'Examples/RudderSampleApptvOSObjC/RudderSampleApptvOSObjC.xcodeproj'

target 'RudderSampleAppObjC' do
    project 'Examples/RudderSampleAppObjC/RudderSampleAppObjC.xcodeproj'
    platform :ios, '9.0'
    shared_pods
    pod 'Firebase/Analytics'
    pod 'Firebase/Messaging'
end

target 'RudderSampleAppSwift' do
    project 'Examples/RudderSampleAppSwift/RudderSampleAppSwift.xcodeproj'
    platform :ios, '9.0'
    shared_pods
end

target 'RudderSampleApptvOSObjC' do
    project 'Examples/RudderSampleApptvOSObjC/RudderSampleApptvOSObjC.xcodeproj'
    platform :tvos, '10.0'
    shared_pods
end
