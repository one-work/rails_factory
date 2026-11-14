module Factory
  module Ext::Cart
    extend ActiveSupport::Concern

    included do
      has_many :production_carts, ->{ order(customized_at: :desc) }, class_name: 'Factory::ProductionCart', dependent: :destroy_async
      has_many :productions, through: :production_carts
    end

    def init_provide_itemss(production, **options)
      provide_items = find_items(purchase_id: production.id, **options)
      init_provide_items_inner(production, provide_items, **options)
    end

    def init_provide_items_inner(production, provide_items, **options)
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

    def find_purchase_items(collect_id, **options)
      r = purchase_items.where(collect_id: collect_id).select(&:persisted?)
      ActiveRecord::Associations::Preloader.new(records: r, associations: [:item_promotes, :purchase]).call
      r.sort_by! { |i| i.id }

      r.group_by(&:purchase).each do |purchase, items|
        init_provide_items_inner(purchase, items, **options)
      end
      r
    end

  end
end
