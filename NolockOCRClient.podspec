Pod::Spec.new do |s|
  s.name = 'NolockOCRClient'
  s.ios.deployment_target = '11.0'
  s.osx.deployment_target = '10.13'
  s.tvos.deployment_target = '11.0'
  s.watchos.deployment_target = '4.0'
  s.version = '1.6.1'
  s.source = { :git => 'https://github.com/o2alexanderfedin/nolock-ocr-swift-client.git', :tag => 'v1.6.1' }
  s.authors = 'OpenAPI Generator'
  s.license = 'Proprietary'
  s.homepage = 'https://github.com/OpenAPITools/openapi-generator'
  s.summary = 'NolockOCRClient Swift SDK'
  s.source_files = 'NolockOCRClient/**/*.swift'
  s.dependency 'AnyCodable-FlightSchool', '~> 0.6'
end
