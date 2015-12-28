Pod::Spec.new do |s|
  s.name         = "ConfigoSDK"
  s.version      = "0.3.9"
  s.summary      = "The official Configo.io SDK, providing mobile apps with a continuous delivery and configuration platform."
  s.description  = <<-DESC
			Configo is a cloud platform that directly connects to your end users and propagates changes instantly.
			With a 5 minute integration of our SDK, toggling features, grouping users using any criteria and fine tuning your features can be easily done from the web dashboard.
		   DESC
  s.homepage     = "https://configo.io"
  s.license      = "Apache License, Version 2.0"

  s.author       = { "natanavra" => "natan@configo.io" }
  s.platform     = :ios, "7.0"
 
  s.source       = { :git => "https://github.com/configo-io/configo-ios-sdk.git", :tag => s.version, :submodules => true }

  s.source_files  = "ConfigoSDK/ConfigoSDK/**/*.{h,m}", "ConfigoSDK/ConfigoSDK/Classes/NNLibraries/**/*.{h,m}"
  s.public_header_files = "ConfigoSDK/ConfigoSDK/ConfigoSDK.h", "ConfigoSDK/ConfigoSDK/Classes/Configo.h", "ConfigoSDK/ConfigoSDK/Constants/CFGLogLevel.h"

  s.framework  = 'SystemConfiguration', 'CoreTelephony'
  s.requires_arc = true
  s.documentation_url  = "https://docs.configo.io/ios-sdk"
end
