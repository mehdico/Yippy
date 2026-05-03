# Uncomment the next line to define a global platform for your project
platform :osx, '13'


project 'Yippy', {
  'Debug' => :debug,
  'Release' => :release,
  'Beta Debug' => :debug,
  'Beta Release' => :release,
  'XCTest' => :debug
}

target 'Yippy' do
    # Comment the next line if you don't want to use dynamic frameworks
    use_frameworks!

    # Pods for Yippy
    pod 'Default'
    pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
    pod 'RxSwift', '~> 6.8.0'
    pod 'RxCocoa', '~> 6.8.0'

    target 'YippyTests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 6.8.0'
        pod 'RxTest', '~> 6.8.0'
        pod 'Default'
        pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
        pod 'RxSwift', '~> 6.8.0'
        pod 'RxCocoa', '~> 6.8.0'
    end

    target 'YippyUITests' do
        inherit! :search_paths
        # Pods for testing
        pod 'RxBlocking', '~> 6.8.0'
        pod 'RxTest', '~> 6.8.0'
        pod 'Default'
        pod 'LoginServiceKit', :git => 'https://github.com/Clipy/LoginServiceKit.git'
        pod 'RxSwift', '~> 6.8.0'
        pod 'RxCocoa', '~> 6.8.0'
    end
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        target.build_configurations.each do |config|
            config.build_settings['CLANG_WARN_QUOTED_INCLUDE_IN_FRAMEWORK_HEADER'] = 'NO'
            config.build_settings['MACOSX_DEPLOYMENT_TARGET'] = '13.0'
        end
    end
end
