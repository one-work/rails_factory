module Factory
  module Model::ComponentPart
    extend ActiveSupport::Concern

    included do
      attribute :default, :boolean, default: false
      attribute :min, :integer, default: 1
      attribute :max, :integer

      belongs_to :component, counter_cache: true
      belongs_to :taxon
      belongs_to :product, optional: true
      belongs_to :part, class_name: 'Production'

      validates :part_id, uniqueness: { scope: :component_id }

      before_validation :sync_from_component, if: -> { component_id_changed? }
      after_update :set_default, if: -> { default? && saved_change_to_default? }
      after_update_commit :change_default!, if: -> { default? && saved_change_to_default? }
    end

    def sync_from_component
      self.taxon_id = component.taxon_id
      self.product_id = component.product_id
    end

    def set_default
      self.class.where.not(id: self.id).where(component_id: self.component_id).update_all(default: false)
    end

    def change_default!
      production_params = {
        production_parts_attributes: [
          {
            component_id: component_id,
            part_id: part_id
          }
        ]
      }

      if product
        prod = self.class.change_default_production(product, production_params)
        prod.update default: true
      else
        taxon.products.each do |product|
          prod = self.class.change_default_production(product, production_params)
          prod.default = true
          prod.enabled = true
          prod.save
        end
      end
    end

    class_methods do
      def change_default_production(product, production_params)
        temp_production = product.productions.build(production_params)
        temp_production.compute_part_str
        production = product.productions.find_by(str_part_ids: temp_production.str_part_ids)

        if production
          production
        else
          temp_production.compute_cost_price
          temp_production
        end
      end
    end

  end
end
