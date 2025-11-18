#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint paylisher_flutter.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'paylisher_flutter'
  s.version          = '0.0.1'
  s.summary          = 'The hassle-free way to add paylisher to your Flutter app.'
  s.description      = <<-DESC
Paylisher flutter plugin
                       DESC
  s.homepage         = 'https://paylisher.com/'
  s.license          = { :file => '../LICENSE' }
  s.author           = { 'Paylisher' => 'info@paylisher.com' }
  s.source           = { :path => '.' }
  s.social_media_url = 'https://paylisher.com/'

  s.source_files = 'Classes/**/*'
  s.resource_bundles = { "PaylisherFlutter" => "Resources/PrivacyInfo.xcprivacy" }
  
  s.ios.dependency 'Flutter'
  s.osx.dependency 'FlutterMacOS'

  # ~> Version 3.32.0 up to, but not including, 4.0.0
  s.dependency 'Paylisher', '>= 3.32.0', '< 4.0.0' //

  s.ios.deployment_target = '13.0'
  # Paylisher iOS SDK 3.0.0 requires >= 10.15
  s.osx.deployment_target = '10.15'

  # Flutter.framework does not contain a i386 slice.
  s.ios.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.osx.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES' }
  s.swift_version = '5.3'
end
