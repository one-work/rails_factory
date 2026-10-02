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
    end

    def sync_from_component
      self.taxon_id = component.taxon_id
      self.product_id = component.product_id
    end

    def set_default
      self.class.where.not(id: self.id).where(component_id: self.component_id).update_all(default: false)
    end

  end
end
