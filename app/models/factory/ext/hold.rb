module Factory
  module Ext::Hold
    extend ActiveSupport::Concern

    included do
      attribute :status, :string

      has_many :stock_logs, class_name: 'Factory::StockLog', as: :source

      enum :status, {
        init: 'init',
        received: 'received'
      }, prefix: true, default: 'init'

      after_save :increment_stock, if: -> { saved_change_to_status? && status == 'received' && ['init', nil].include?(status_before_last_save) }
      after_save :decrement_stock, if: -> { saved_change_to_status? && status != 'received' && ['received'].include?(status_before_last_save) }
    end

    def increment_stock
      item.purchase.stock = item.purchase.stock.to_d + number
      item.purchase.last_stock_log = {
        amount: number,
        title: '收货',
        source_type: self.base_class_name,
        source_id: id
      }
      item.purchase.save
    end

    def decrement_stock
      item.purchase.stock = item.purchase.stock.to_d - number
      item.purchase.last_stock_log = {
        amount: -number,
        title: '取消收货',
        source_type: self.base_class_name,
        source_id: id
      }
      item.purchase.save
    end

  end
end
