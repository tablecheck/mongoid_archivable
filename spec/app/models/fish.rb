class Fish
  include Mongoid::Document
  include Mongoid::Archivable

  def self.fresh
    where(fresh: true)
  end

  belongs_to :post, class_name: 'ArchivablePost'
end
