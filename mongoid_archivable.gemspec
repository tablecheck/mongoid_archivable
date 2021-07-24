# frozen_string_literal: true

$LOAD_PATH.push File.expand_path('lib', __dir__)
require 'mongoid/archivable/version'

Gem::Specification.new do |gem|
  gem.name          = 'mongoid_archivable'
  gem.version       = Mongoid::Archivable::VERSION
  gem.authors       = ['Durran Jordan', 'Josef Šimánek', 'Johnny Shields']
  gem.email         = ['durran@gmail.com', 'retro@ballgag.cz', 'info@tablecheck.com']
  gem.description   = 'Enables archiving (soft delete) of Mongoid documents.'
  gem.summary       = 'Archivable documents'
  gem.homepage      = 'https://github.com/tablecheck/mongoid_archivable'
  gem.license       = 'MIT'

  gem.files         = Dir.glob('lib/**/*') + %w[LICENSE README.md]
  gem.test_files    = Dir.glob('{perf,spec}/**/*')
  gem.require_paths = ['lib']

  gem.add_runtime_dependency 'mongoid', '~> 7.0'

  gem.add_development_dependency 'rubocop', '>= 1.8.1'
end
