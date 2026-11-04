module Factory
  module Ext::Cart
    extend ActiveSupport::Concern

    included do
      has_many :production_carts, ->{ order(customized_at: :desc) }, class_name: 'Factory::ProductionCart', dependent: :destroy_async
      has_many :productions, through: :production_carts
    end

    def init_provide_items(production, **options)
      provide_items = find_items(purchase_id: production.id, **options)
      production.available_provides.map do |production_provide|
        unless provide_items.pluck(:provide_id).include?(production_provide.provide_id)
          provide_items << items.build(
            provide_id: production_provide.provide_id,
            purchase_id: production.id,
            good_type: 'Factory::Production',
            good_id: production_provide.upstream_production_id,
            **options
          )
        end
      end

      provide_items
    end

  end
end
