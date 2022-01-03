#
#  Be sure to run `pod spec lint CheckLocalizedStrings.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see https://guides.cocoapods.org/syntax/podspec.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |spec|

  spec.name             = "CheckLocalizedStrings"
  spec.version          = "1.0.2"
  spec.summary          = "A swift script that verifies your Localizable.strings files"

  #spec.description     = <<-DESC
  #                 DESC

  spec.homepage         = "https://github.com/mikaelbo/CheckLocalizedStrings"

  spec.license          = { :type => "MIT", :file => "LICENSE" }

  spec.author             = { "mikaelbo" => "mbo@mbo42.com" }

  spec.platform         = :ios, "9.0"
  spec.swift_versions   = "5.0"

  spec.source           = { :http => "#{spec.homepage}/releases/download/#{spec.version}/portable_checklocalizedstrings.zip" }

  spec.preserve_path     = "*"
  # spec.source_files     = "*"

end
