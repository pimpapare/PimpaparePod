#
#  Be sure to run `pod spec lint Pimpapare.podspec' to ensure this is a
#  valid spec and to remove all comments including this before submitting the spec.
#
#  To learn more about Podspec attributes see http://docs.cocoapods.org/specification.html
#  To see working Podspecs in the CocoaPods repo see https://github.com/CocoaPods/Specs/
#

Pod::Spec.new do |s|

  s.name          = 'Pimpapare'
  s.version       = '0.0.1'
  s.summary       = 'Pimpapare Private Pod'

  s.homepage      = 'https://github.com/pimpapare/PimpaparePod.git'
  s.license       = 'MIT'
  s.author             = { "pimpaporn chaichompoo" => "p.pimpapare@gmail.com" }

  s.source        = { :git => 'https://github.com/pimpapare/PimpaparePod.git', :tag => s.version.to_s}
  s.source_files  = 'Pimpapare/**/*.{swift}'
  s.resources     = 'Pimpapare/**/*.{xcassets,storyboard,xib,xcdatamodeld,lproj}'

end
