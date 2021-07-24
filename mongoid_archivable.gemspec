# -*- encoding: utf-8 -*-
$:.push File.expand_path('../lib', __FILE__)
require 'mongoid/archivable/version'

Gem::Specification.new do |gem|
  gem.name          = 'mongoid-archivable'
  gem.version       = Mongoid::Archivable::VERSION
  gem.authors       = ['Durran Jordan', 'Josef Šimánek', 'Johnny Shields']
  gem.email         = ['durran@gmail.com', 'retro@ballgag.cz']
  gem.description   = %q{There may be times when you don't want documents to actually get archived from the database, but "flagged" as archived. Mongoid provides a Archivable module to give you just that.}
  gem.summary       = %q{Archivable documents}
  gem.homepage      = 'https://github.com/tablecheck/mongoid-archivable'
  gem.license       = 'MIT'

  gem.files         = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  gem.test_files    = Dir.glob('{perf,spec}/**/*')
  gem.require_paths = ['lib']

  gem.add_dependency 'mongoid', '~> 7.0'
end
