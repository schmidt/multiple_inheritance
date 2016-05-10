Gem::Specification.new do |s|
  s.name       = 'multiple_inheritance'
  s.version    = '0.2.0'
  s.author     = 'Gregor Schmidt'
  s.email      = 'schmidt@nach-vorne.eu'
  s.homepage   = 'http://github.com/schmidt/multiple_inheritance'
  s.summary    = 'Implementing multiple inheritance in plain Ruby'
  s.license    = 'MIT'
  s.files      = Dir['**/*'].reject{ |f| f.include?('git') }
  s.test_files = Dir['test/*.rb']

  s.rdoc_options = ['--charset=UTF-8']
  s.extra_rdoc_files = ['README.rdoc']

  s.add_development_dependency "rake"
  s.add_development_dependency "rspec"

  s.description = %Q{
    Proof-of-concept implementation for class based multiple inheritance in
    Ruby. This is not meant to be used in anything else than example code.
  }
end
