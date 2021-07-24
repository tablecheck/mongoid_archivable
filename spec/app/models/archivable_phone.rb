class ArchivablePhone
  include Mongoid::Document
  include Mongoid::Archivable

  attr_accessor :after_archive_called, :before_archive_called

  field :number, type: String

  embedded_in :person

  before_archive :before_archive_stub, :halt_me
  after_archive :after_archive_stub

  def before_archive_stub
    self.before_archive_called = true
  end

  def after_archive_stub
    self.after_archive_called = true
  end

  def halt_me
    throw :abort if person.age == 42
  end
end
