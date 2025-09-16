module Factory
  module Ext::Organ
    extend ActiveSupport::Concern

    included do
      attribute :production_enabled, :boolean

      has_many :factory_providers, class_name: 'Factory::FactoryProvider', foreign_key: :provider_id, dependent: :destroy_async

      has_many :provides, class_name: 'Factory::Provide', dependent: :destroy_async
      has_many :providers, through: :provides
    end

    def dispatch_i18n
      Trade::Item.enum_i18n(:dispatch, dispatch)
    end

    def name_detail
      "#{name} (#{id})"
    end

    def nearest_produce_plans
      Factory::ProducePlan.includes(:scene).default_where(organ_id: self.id).effective.order(produce_on: :asc)
    end

    def init_provider
      ft = Factory::FactoryTaxon.first
      pt = ft.taxons.build(organ_id: id)
      pt.scene_id = ft.scene_id
      pt.name = ft.name
      pt.provides.build(provider_id: 1)
      pt.save
      pt
    end

  end
end
