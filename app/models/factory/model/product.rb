module Factory
  module Model::Product
    extend ActiveSupport::Concern

    included do
      attribute :name, :string
      attribute :description, :string
      attribute :qr_prefix, :string
      attribute :sku, :string, index: true
      attribute :published, :boolean, default: true
      attribute :specialty, :boolean, default: false
      attribute :base_price, :decimal
      attribute :order_items_count, :integer, default: 0
      attribute :productions_count, :integer, default: 0
      attribute :product_parts_count, :integer, default: 0
      attribute :fits_count, :integer, default: 0
      attribute :position, :integer
      attribute :profit_margin, :decimal, precision: 4, scale: 2, default: 0
      attribute :min_price, :decimal
      attribute :max_price, :decimal

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      belongs_to :unifier, optional: true
      belongs_to :factory_taxon, optional: true
      belongs_to :taxon, counter_cache: true, optional: true
      belongs_to :brand, counter_cache: true, optional: true

      has_one :production, -> { where(default: true) }
      has_many :productions, dependent: :destroy_async
      has_many :production_provides, primary_key: [:taxon_id, :id], foreign_key: [:taxon_id, :product_id], dependent: :destroy_async
      has_many :components, ->(o){ where(product_id: [o.id, nil]) }, primary_key: :taxon_id, foreign_key: :taxon_id
      has_many :product_components
      has_many :product_provides
      has_many :taxon_components, primary_key: :taxon_id, foreign_key: :taxon_id
      has_many :component_parts, through: :components
      has_many :parts, through: :component_parts
      has_many :part_products, class_name: 'ComponentPart', foreign_key: :part_id, dependent: :destroy_async
      has_many :production_carts, dependent: :destroy_async
      has_many :carts, through: :production_carts
      has_many :fits, dependent: :destroy_async
      has_many :production_plans

      accepts_nested_attributes_for :product_components, reject_if: :all_blank, allow_destroy: true
      accepts_nested_attributes_for :productions

      has_one_attached :logo do |attachable|
        attachable.variant :thumb, resize_to_limit: [64, 64], process: :later
      end
      has_one_attached :manual
      has_many_attached :covers
      has_many_attached :images

      scope :published, -> { where(published: true) }

      has_taxons :taxon
      positioned on: :organ_id

      before_save :sync_from_taxon, if: -> { taxon_id_changed? }
      after_save :sync_taxon, if: -> { saved_change_to_taxon_id? }
      after_update :set_specialty, if: -> { specialty? && saved_change_to_specialty? }
      after_save_commit :sync_position_later, if: -> { saved_change_to_position? }
    end

    def profit_margin_str
      (profit_margin.to_d * 100).to_fs(:percentage)
    end

    def all_components
      taxon_components + product_components
    end

    def compute_min_max!
      self.min_price = productions.minimum(:price)
      self.max_price = productions.maximum(:price)
      self.save
    end

    def compute_min_max_later
      ProductMinMaxPriceJob.perform_later(self)
    end

    def sync_from_taxon
      self.factory_taxon_id = taxon.factory_taxon_id
      self.organ_id = taxon.organ_id
    end

    def sync_name
      productions.update_all name: name
    end

    def sync_position_later
      ProductSyncPositionJob.perform_later(self)
    end

    def sync_position
      self.class.where(taxon_id: taxon_id).find_each do |p|
        p.productions.update_all position: p.position
      end
    end

    def set_specialty
      self.class.where.not(id: self.id).where(organ_id: self.organ_id).update_all(specialty: false)
    end

    def sync_taxon
      productions.update_all(
        taxon_id: taxon_id,
        factory_taxon_id: factory_taxon_id,
        organ_id: organ_id
      )
    end

  end
end
