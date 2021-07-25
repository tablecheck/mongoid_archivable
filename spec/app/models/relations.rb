class NormBase
  include Mongoid::Document

  has_one :norm_has_one, dependent: :destroy
  has_one :arch_has_one, dependent: :archive

  has_many :norm_has_many, dependent: :destroy
  has_many :arch_has_many, dependent: :archive

  has_many :norm_has_many_poly, dependent: :destroy
  has_many :arch_has_many_poly, dependent: :archive

  belongs_to :norm_belongs_to_one, dependent: :destroy
  belongs_to :arch_belongs_to_one, dependent: :archive

  belongs_to :norm_belongs_to, dependent: :destroy
  belongs_to :arch_belongs_to, dependent: :archive

  has_and_belongs_to_many :norm_habtm, dependent: :destroy
  has_and_belongs_to_many :arch_habtm, dependent: :archive

  embeds_one :norm_embeds_one
  embeds_one :arch_embeds_one

  embeds_many :norm_embeds_many
  embeds_many :arch_embeds_many

  embeds_many :norm_embeds_many_poly
  embeds_many :arch_embeds_many_poly
end

class ArchBase
  include Mongoid::Document
  include Mongoid::Archivable

  has_one :norm_has_one, dependent: :destroy
  has_one :arch_has_one, dependent: :archive

  has_many :norm_has_many, dependent: :destroy
  has_many :arch_has_many, dependent: :archive

  has_many :norm_has_many_poly, dependent: :destroy
  has_many :arch_has_many_poly, dependent: :archive

  belongs_to :norm_belongs_to_one, dependent: :destroy
  belongs_to :arch_belongs_to_one, dependent: :archive

  belongs_to :norm_belongs_to, dependent: :destroy
  belongs_to :arch_belongs_to, dependent: :archive

  has_and_belongs_to_many :norm_habtm, dependent: :destroy
  has_and_belongs_to_many :arch_habtm, dependent: :archive

  embeds_one :norm_embeds_one
  embeds_one :arch_embeds_one

  embeds_many :norm_embeds_many
  embeds_many :arch_embeds_many

  embeds_many :norm_embeds_many_poly
  embeds_many :arch_embeds_many_poly
end

class NormHasOne
  include Mongoid::Document

  belongs_to :norm_base
  belongs_to :arch_base

  has_one :norm_belongs_to, dependent: :destroy
  has_one :arch_belongs_to, dependent: :archive

  has_one :norm_habtm, dependent: :destroy
  has_one :norm_habtm, dependent: :destroy
end

class NormHasMany
  include Mongoid::Document

  belongs_to :norm_base
  belongs_to :arch_base

  has_many :norm_belongs_to, dependent: :destroy
  has_many :arch_belongs_to, dependent: :archive

  has_many :norm_habtm, dependent: :destroy
  has_many :norm_habtm, dependent: :destroy
end

class NormHasManyPoly
  include Mongoid::Document

  belongs_to :base, polymorphic: true
end

class NormBelongsToOne
  include Mongoid::Document

  has_one :norm_base
  has_one :arch_base
end

class NormBelongsTo
  include Mongoid::Document

  has_many :norm_base
  has_many :arch_base

  belongs_to :norm_has_one, dependent: :destroy
  belongs_to :arch_has_one, dependent: :archive

  belongs_to :norm_has_many, dependent: :destroy
  belongs_to :arch_has_many, dependent: :archive
end

class NormHabtm
  include Mongoid::Document

  has_and_belongs_to_many :norm_base
  has_and_belongs_to_many :arch_base

  belongs_to :norm_has_one, dependent: :destroy
  belongs_to :arch_has_one, dependent: :archive

  belongs_to :norm_has_many, dependent: :destroy
  belongs_to :arch_has_many, dependent: :archive

  has_and_belongs_to_many :recursive, class_name: 'NormHabtm', inverse_of: :recursive, dependent: :archive
  has_and_belongs_to_many :arch_habtm, dependent: :archive
end

class NormEmbedsOne
  include Mongoid::Document

  embedded_in :norm_base
  embedded_in :arch_base
end

class NormEmbedsMany
  include Mongoid::Document

  embedded_in :norm_base
  embedded_in :arch_base
end

class NormEmbedsManyPoly
  include Mongoid::Document

  embedded_in :base, polymorphic: true
end

class ArchHasOne
  include Mongoid::Document
  include Mongoid::Archivable

  belongs_to :norm_base
  belongs_to :arch_base

  has_one :norm_belongs_to, dependent: :destroy
  has_one :arch_belongs_to, dependent: :archive

  has_one :norm_habtm, dependent: :destroy
  has_one :norm_habtm, dependent: :destroy
end

class ArchHasMany
  include Mongoid::Document
  include Mongoid::Archivable

  belongs_to :norm_base
  belongs_to :arch_base

  has_many :norm_belongs_to, dependent: :destroy
  has_many :arch_belongs_to, dependent: :archive

  has_many :norm_habtm, dependent: :destroy
  has_many :norm_habtm, dependent: :destroy
end

class ArchHasManyPoly
  include Mongoid::Document
  include Mongoid::Archivable

  belongs_to :base, polymorphic: true
end

class ArchBelongsToOne
  include Mongoid::Document
  include Mongoid::Archivable

  has_one :norm_base
  has_one :arch_base
end

class ArchBelongsTo
  include Mongoid::Document
  include Mongoid::Archivable

  has_many :norm_base
  has_many :arch_base

  belongs_to :norm_has_one, dependent: :destroy
  belongs_to :arch_has_one, dependent: :archive

  belongs_to :norm_has_many, dependent: :destroy
  belongs_to :arch_has_many, dependent: :archive
end

class ArchHabtm
  include Mongoid::Document
  include Mongoid::Archivable

  has_and_belongs_to_many :norm_base
  has_and_belongs_to_many :arch_base

  belongs_to :norm_has_one, dependent: :destroy
  belongs_to :arch_has_one, dependent: :archive

  belongs_to :norm_has_many, dependent: :destroy
  belongs_to :arch_has_many, dependent: :archive

  has_and_belongs_to_many :norm_habtm, dependent: :destroy
  has_and_belongs_to_many :recursive, class_name: 'ArchHabtm', inverse_of: :recursive, dependent: :archive
end

class ArchEmbedsOne
  include Mongoid::Document
  include Mongoid::Archivable

  embedded_in :norm_base
  embedded_in :arch_base
end

class ArchEmbedsMany
  include Mongoid::Document
  include Mongoid::Archivable

  embedded_in :norm_base
  embedded_in :arch_base
end

class ArchEmbedsManyPoly
  include Mongoid::Document
  include Mongoid::Archivable

  embedded_in :base, polymorphic: true
end
