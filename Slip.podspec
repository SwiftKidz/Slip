Pod::Spec.new do |s|
 s.name = 'Slip'
 s.version = '0.0.1'
 s.license = { :type => "MIT", :file => "LICENSE" }
 s.summary = 'Control the execution flow of your code using steps'
 s.homepage = 'https://github.com/SwiftKidz'
 s.social_media_url = 'https://twitter.com/_JARMourato'
 s.authors = { "João Mourato" => "joao.armourato@gmail.com", "Diogo Antunes" => "diogo.antunes@gmail.com" }
 s.source = { :git => "https://github.com/SwiftKidz/Slip.git", :tag => "v"+s.version.to_s }
 s.platforms     = { :ios => "8.0", :osx => "10.10", :tvos => "9.0", :watchos => "2.0" }
 s.requires_arc = true
 s.source_files  = "Sources/*.swift"
 s.module_name = 'Slip'
end
