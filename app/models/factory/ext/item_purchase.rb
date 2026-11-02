module Factory
  module Ext::ItemPurchase
    extend ActiveSupport::Concern

    included do
      attribute :produce_on, :date, comment: '对接生产管理'

      enum :purchase_status, {
        init: 'init',
        received: 'received'
      }, prefix: true, default: 'init'

      belongs_to :scene, class_name: 'Factory::Scene', optional: true
      belongs_to :produce_plan, ->(o) { where(organ_id: o.organ_id, produce_on: o.produce_on) }, class_name: 'Factory::ProducePlan', foreign_key: :scene_id, primary_key: :scene_id, optional: true  # 产品对应批次号
      belongs_to :production_plan, ->(o) { where(produce_on: o.produce_on, scene_id: o.scene_id) }, class_name: 'Factory::ProductionPlan', foreign_key: :good_id, primary_key: :production_id, counter_cache: :trade_items_count, optional: true
      belongs_to :purchase, polymorphic: true, foreign_type: :good_type, optional: true
      belongs_to :production_provide, class_name: 'Factory::ProductionProvide', foreign_key: [:purchase_id, :provide_id], primary_key: [:production_id, :provide_id], optional: true

      has_many :stock_logs, class_name: 'Factory::StockLog', as: :source

      after_initialize :sync_from_purchase, if: -> { new_record? && order.present? }
      before_validation :sync_from_purchase, if: -> { purchase_id.present? && purchase_id_changed? }
      before_validation :sync_from_produce_plan, if: -> { respond_to?(:produce_plan) && produce_plan }
      after_save :increment_stock, if: -> { saved_change_to_purchase_status? && purchase_status == 'received' && ['init', nil].include?(purchase_status_before_last_save) }
      after_save :decrement_stock, if: -> { saved_change_to_purchase_status? && purchase_status != 'received' && ['received'].include?(purchase_status_before_last_save) }
    end

    def sync_from_produce_plan
      self.produce_on = produce_plan.produce_on
      self.expire_at = produce_plan.book_finish_at
    end

    def sync_from_purchase
      return unless purchase

      self.good_name = purchase.title
      self.extra = Hash(self.extra).merge purchase.item_extra
      if production_provide
        self.single_price ||= production_provide.cost_price
      else
        self.single_price ||= purchase.cost_price
      end
    end

    def increment_stock
      purchase.stock = purchase.stock.to_d + number
      purchase.last_stock_log = {
        amount: number,
        title: '收货',
        source_type: self.base_class_name,
        source_id: id
      }
      purchase.save
    end

    def decrement_stock
      purchase.stock = purchase.stock.to_d - number
      purchase.last_stock_log = {
        amount: -number,
        title: '取消收货',
        source_type: self.base_class_name,
        source_id: id
      }
      purchase.save
    end

  end
end
