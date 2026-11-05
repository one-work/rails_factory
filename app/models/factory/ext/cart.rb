module Factory
  module Ext::Cart
    extend ActiveSupport::Concern

    included do
      has_many :production_carts, ->{ order(customized_at: :desc) }, class_name: 'Factory::ProductionCart', dependent: :destroy_async
      has_many :productions, through: :production_carts
    end

    def init_provide_items(production, **options)
      provide_items = find_items(purchase_id: production.id, **options)
      _items = provide_items.each_with_object({}) do |item, h|
        h.merge! item.provide_id => item
      end

      production.available_provides.map do |production_provide|
        provide_item = _items[production_provide.provide_id]
        if provide_item
          provide_item.available_provide = true
        else
          item = items.build(
            provide_id: production_provide.provide_id,
            purchase_id: production.id,
            good_type: 'Factory::Production',
            good_id: production_provide.upstream_production_id,
            **options
          )
          item.available_provide = true

          provide_items << item
        end
      end

      if _items[nil]
      else
        provide_items << items.build(
          provide_id: nil,
          purchase_id: production.id,
          good_type: 'Factory::Production',
          good_id: nil
        )
      end

      provide_items
    end

  end
end
