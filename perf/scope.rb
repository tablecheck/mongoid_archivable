require 'bundler/setup'
require 'mongoid'
require 'mongoid/archivable'
require 'benchmark'


Mongoid.configure do |config|
  config.connect_to('my_little_test')
end

class Model
  include Mongoid::Document
  field :text, type: String

  index({ text: "text" })
end

class ArchivableModel
  include Mongoid::Document
  include Mongoid::Archivable
  field :text, type: String

  index({ text: "text" })
end

class MetaArchivableModel
  include Mongoid::Document
  field :text, type: String
  field :archived_at, type: Time
  default_scope -> { where(archived_at: nil) }

  index({ text: "text" })
end

if ENV['FORCE']
  Mongoid.purge!
  ::Mongoid::Tasks::Database.create_indexes

  n = 50_000
  n.times {|i| Model.create(text: "text #{i}")}
  n.times {|i| ArchivableModel.create(text: "text #{i}")}
  n.times {|i| MetaArchivableModel.create(text: "text #{i}")}
end

n = 100

puts "text_search benchmark ***"
Benchmark.bm(20) do |x|
  x.report("without") { n.times { Model.text_search("text").execute } }
  x.report("with")    { n.times { ArchivableModel.text_search("text").execute } }
  x.report("meta")    { n.times { MetaArchivableModel.text_search("text").execute } }
  x.report("unscoped meta")    { n.times { MetaArchivableModel.unscoped.text_search("text").execute } }
  x.report("unscoped archivable")    { n.times { ArchivableModel.unscoped.text_search("text").execute } }
end

puts ""
puts "Pluck all ids benchmark ***"
Benchmark.bm(20) do |x|
  x.report("without") { n.times { Model.all.pluck(:id) } }
  x.report("with")    { n.times { ArchivableModel.all.pluck(:id) } }
  x.report("meta")    { n.times { MetaArchivableModel.all.pluck(:id) } }
  x.report("unscoped meta")    { n.times { MetaArchivableModel.unscoped.all.pluck(:id) } }
  x.report("unscoped archivable")    { n.times { ArchivableModel.unscoped.all.pluck(:id) } }
end
