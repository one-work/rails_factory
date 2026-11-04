module Factory
  module Ext::Cart
    extend ActiveSupport::Concern

    included do
      has_many :production_carts, ->{ order(customized_at: :desc) }, class_name: 'Factory::ProductionCart', dependent: :destroy_async
      has_many :productions, through: :production_carts
    end

    def init_provide_items(production, params, **options)
      items = find_items(purchase_id: production.id, **params, **options)
      new_items = model.available_provides.each do |production_provide|
        unless items.pluck(:provide_id).include?(production_provide.provide_id)
          items.build(
            params,
            provide_id: production_provide.provide_id,
            good_type: 'Factory::Production',
            good_id: production_provide.upstream_production_id,
            **options
          )
        end
      end

      items.chain new_items
    end

  end
end
