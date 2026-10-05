module Factory
  module Model::ProductionProvide
    extend ActiveSupport::Concern

    included do
      attribute :cost_price, :decimal
      attribute :default, :boolean

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      belongs_to :provide
      belongs_to :taxon
      belongs_to :product
      belongs_to :production
      belongs_to :provide_config, polymorphic: true, optional: true
      belongs_to :upstream_product, class_name: 'Product', optional: true  # 对应供应链产品
      belongs_to :upstream_production, class_name: 'Production', optional: true  # 对应供应链产品型号

      has_many :downstream_products, class_name: 'Product', foreign_key: :upstream_product_id
      has_many :downstream_productions, class_name: 'Production', foreign_key: :upstream_production_id

      has_many :brothers, class_name: self.name, primary_key: :upstream_product_id, foreign_key: :upstream_product_id, validate: false

      #before_validation :sync_from_upstream, if: :new_record?
      before_validation :sync_from_production, if: -> { production_id_changed? }
      before_validation :sync_from_product, if: -> { product_id_changed? }
      #after_destroy :prune
      after_save_commit :set_default, if: -> { default? && saved_change_to_default? }
    end

    def sync_from_production
      self.product_id = production.product_id
    end

    def sync_from_product
      self.taxon_id = product.taxon_id
    end

    def sync_from_upstream
      self.upstream_product = upstream_production.product
      self.provider_id = upstream_production.organ_id

      if product.nil? && brothers.present?
        self.product = brothers.find(&:product).product
      else
        build_product
      end
      product.taxon = taxon
      product.name = upstream_product.name
      product.logo.attach upstream_product.logo_blob

      production || build_production
      production.product = product
      production.name = upstream_production.name
      production.cost_price = upstream_production.price
    end

    def prune
      if brothers.blank? # 当删除到只剩自己的时候,after destroy brothers 为空。
        product.destroy
      end
      production.destroy
    end

    def set_default
      self.class.where(production_id: production_id).where.not(id: id).update_all default: false
    end

  end
end
