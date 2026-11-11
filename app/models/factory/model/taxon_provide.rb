# frozen_string_literal: true

module Factory
  module Model::TaxonProvide
    extend ActiveSupport::Concern

    included do
      attribute :default, :boolean

      belongs_to :provide
      belongs_to :taxon

      has_many :production_provides, as: :provide_config

      after_create_commit :automatic_production_provide
      after_save_commit :automatic_as_default, if: -> { default? && saved_change_to_default? }
      after_destroy :auto_clear
    end

    def automatic_production_provide
      missing_provides = taxon.productions.where.missing(:production_provides).map do |i|
        { production_id: i.id, product_id: i.product_id, taxon_id: i.taxon_id, provide_id: provide_id, default: true }
      end

      production_provides.insert_all(missing_provides)
    end

    def automatic_as_default
      taxon.taxon_provides.where(taxon_id: taxon_id).where.not(id: id).update_all default: false
      taxon.production_provides.where(provide_config_type: self.class.name).update_all(
        provide_id: provide_id, provide_config_id: self.id
      )
    end

    def auto_clear
      production_provides.destroy_all
    end

  end
end
