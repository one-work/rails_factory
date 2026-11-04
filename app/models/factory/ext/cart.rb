module Factory
  module Ext::Cart
    extend ActiveSupport::Concern

    included do
      has_many :production_carts, ->{ order(customized_at: :desc) }, class_name: 'Factory::ProductionCart', dependent: :destroy_async
      has_many :productions, through: :production_carts
    end

    def init_provide_items(production, params, **options)
      provide_ids = model.available_provides.pluck(:provide_id) - items.pluck(:provide_id)
      items = find_items(purchase_id: production.id, **params, **options)

      provide_ids.map do |production_provide|
        items.build(
          params,
          provide_id: production_provide.provide_id,
          good_type: 'Factory::Production',
          good_id: production_provide.upstream_production_id,
          **options
        )
      end
    end

  end
end
