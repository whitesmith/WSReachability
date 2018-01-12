Pod::Spec.new do |s|
  s.name             = "WSReachability"
  s.version          = "2.0.0"
  s.summary          = "An iOS network state monitor"
  s.homepage         = "https://github.com/whitesmith/WSReachability"
  s.license          = 'MIT'
  s.author           = { "Ricardo Pereira" => "m@ricardopereira.eu" }
  s.source           = { :git => "https://github.com/whitesmith/WSReachability.git", :tag => s.version.to_s }
  s.social_media_url = 'https://twitter.com/whitesmithco'

  s.platform     = :ios, '8.0'
  s.requires_arc = true

  s.source_files = 'WSReachability/*.{h}', 'Source/**/*.{h,swift}'
end
