# frozen_string_literal: true

module Factory
  module Model::ProductProvide
    extend ActiveSupport::Concern

    included do
      attribute :default, :boolean
      attribute :ref, :string, comment: '用于数据迁移'

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      belongs_to :upstream_product, class_name: 'Product'
      belongs_to :provide, counter_cache: true, optional: true
      belongs_to :product

      has_many :productions, primary_key: :product_id, foreign_key: :product_id
      has_many :production_provides, as: :provide_config

      before_validation :init_product, if: -> { upstream_product.present? && product.blank? }
      after_create_commit :automatic_production_provide
      after_save_commit :automatic_as_default, if: -> { default? && saved_change_to_default? }
    end

    def init_product
      build_product
      if upstream_product.taxon
        taxon = Taxon.where(organ_id: organ_id).find_or_create_by(name: upstream_product.taxon.name)
      end
      product.taxon = taxon
      product.name = upstream_product.name
      product.logo.attach upstream_product.logo_blob
    end

    def automatic_production_provide
      missing_provides = product.productions.where.missing(:production_provides).map do |i|
        { production_id: i.id, product_id: i.product_id, taxon_id: i.taxon_id, provide_id: provide_id, default: true }
      end

      production_provides.insert_all(missing_provides)
      product.taxon.production_provides.where(provide_config_type: 'Factory::TaxonProvide').update_all(
        provide_id: provide_id, provide_config_type: 'Factory::ProductProvide', provide_config_id: self.id
      )
    end

    def automatic_as_default
      product.product_provides.where(product_id: product_id).where.not(id: id).update_all default: false
      product.production_provides.where(provide_config_type: self.class.name).update_all(
        provide_id: provide_id, provide_config_id: self.id
      )
    end

  end
end
