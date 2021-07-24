class Person
  include Mongoid::Document

  field :age, type: Integer, default: "100"
  field :score, type: Integer

  attr_reader :rescored

  embeds_many :phone_numbers, class_name: "Phone", validate: false
  embeds_many :phones, store_as: :mobile_phones, validate: false
  embeds_many :addresses, as: :addressable, validate: false

  embeds_many :appointments, validate: false
  embeds_many :archivable_phones, validate: false

  has_many :archivable_posts, validate: false
  belongs_to :archivable_post

  accepts_nested_attributes_for :addresses
  accepts_nested_attributes_for :archivable_phones
end
