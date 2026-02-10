#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint paylisher_flutter.podspec` to validate before publishing.
#

Pod::Spec.new do |s|
  s.name             = 'paylisher_flutter'
  s.version          = '1.0.0'
  s.summary          = 'The hassle-free way to add Paylisher to your Flutter app.'
  s.description      = <<-DESC
A Flutter plugin that provides bindings for the Paylisher iOS SDK.
  DESC

  s.homepage         = 'https://paylisher.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Paylisher' => 'info@paylisher.com' }
  s.source           = { :path => '.' }
  s.social_media_url = 'https://paylisher.com/'

  # Flutter classes
  s.source_files = 'Classes/**/*'
  s.resource_bundles = { "PaylisherFlutter" => "Resources/PrivacyInfo.xcprivacy" }

  # Flutter engine dependencies
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'
  
  # Paylisher iOS SDK
  s.ios.dependency 'Paylisher', '~> 1.7.1'

  s.ios.deployment_target = '13.0'
  s.osx.deployment_target = '10.15'

  # Flutter.framework does not contain an i386 slice.
  s.ios.pod_target_xcconfig = { 
    'DEFINES_MODULE' => 'YES', 
    'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' 
  }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }

  s.swift_version = '5.3'
end