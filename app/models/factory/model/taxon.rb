module Factory
  module Model::Taxon
    extend ActiveSupport::Concern

    included do
      attribute :name, :string
      attribute :position, :integer
      attribute :enabled, :boolean, default: true
      attribute :countable, :boolean, comment: '可盘点'
      attribute :customizable, :boolean, comment: '可定制'
      attribute :nav, :boolean, default: false, comment: '单独分类'
      attribute :products_count, :integer, default: 0
      attribute :provides_count, :integer, default: 0
      attribute :taxon_components_count, :integer, default: 0

      belongs_to :organ, optional: true
      belongs_to :factory_taxon, optional: true
      belongs_to :scene, optional: true

      has_many :products
      has_many :productions
      has_many :production_provides
      has_many :provides, through: :production_provides
      has_many :providers, through: :provides
      has_many :taxon_components
      has_many :taxon_provides
      has_many :brothers, class_name: self.name, primary_key: :organ_id, foreign_key: :organ_id

      has_one_attached :logo
      has_one_attached :logo_color

      default_scope -> { order(position: :asc) }
      scope :enabled, -> { where(enabled: true, nav: false)}
      scope :nav, -> { where(enabled: true, nav: true) }

      validates :name, presence: true

      positioned on: :organ_id

      after_save :sync_factory_taxon_to_products, if: -> { saved_change_to_factory_taxon_id? }
    end

    def sync_factory_taxon_to_products
      products.update_all(factory_taxon_id: factory_taxon_id)
      productions.update_all(factory_taxon_id: factory_taxon_id)
    end

  end
end
