class Title
  include Mongoid::Document
  belongs_to :archivable_post
end
