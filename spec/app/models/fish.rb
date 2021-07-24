class Fish
  include Mongoid::Document
  include Mongoid::Archivable

  def self.fresh
    where(fresh: true)
  end
end
