class ArchivablePost
  include Mongoid::Document
  include Mongoid::Archivable

  field :title, type: String

  attr_accessor :after_archive_called, :before_archive_called,
                :after_restore_called, :before_restore_called,
                :after_archive_called, :before_archive_called,
                :around_before_restore_called, :around_after_restore_called

  belongs_to :person

  has_and_belongs_to_many :tags
  has_many :authors, dependent: :delete_all, inverse_of: :post
  has_many :titles, dependent: :restrict_with_error
  has_one :fish, dependent: :archive

  scope :recent, -> { where(created_at: { '$lt' => Time.now, '$gt' => 30.days.ago }) }

  before_archive :before_archive_stub
  after_archive  :after_archive_stub

  before_archive :before_archive_stub
  after_archive  :after_archive_stub

  before_restore :before_restore_stub
  after_restore  :after_restore_stub
  around_restore :around_restore_stub

  def before_archive_stub
    self.before_archive_called = true
  end

  def after_archive_stub
    self.after_archive_called = true
  end

  def before_archive_stub
    self.before_archive_called = true
  end

  def after_archive_stub
    self.after_archive_called = true
  end

  def before_restore_stub
    self.before_restore_called = true
  end

  def after_restore_stub
    self.after_restore_called = true
  end

  def around_restore_stub
    self.around_before_restore_called = true
    yield
    self.around_after_restore_called = true
  end

  class << self
    def old
      where(created_at: { '$lt' => 30.days.ago })
    end
  end
end
