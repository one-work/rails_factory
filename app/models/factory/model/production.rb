module Factory
  module Model::Production
    extend ActiveSupport::Concern

    included do
      attribute :name, :string
      attribute :word, :string, comment: '搜索关键词'
      attribute :qr_code, :string
      attribute :price, :decimal
      attribute :cost_price, :decimal, comment: '成本价'
      attribute :profit_price, :decimal, comment: '利润'
      attribute :str_part_ids, :string, index: true
      attribute :default, :boolean, default: false
      attribute :enabled, :boolean, comment: '是否上架，注意空值是有意义的，当随着 SPU 下架则设置为空值，上架设置为True'
      attribute :automatic, :boolean, default: false
      attribute :presell, :boolean, default: false, comment: '预售'
      attribute :link, :string
      attribute :position, :integer
      attribute :stock, :decimal
      attribute :last_stock_log, :json, default: {}

      enum :state, {
        init: 'init',
        checked: 'checked',
        producing: 'producing'
      }, default: 'init'

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      belongs_to :product, counter_cache: true, touch: true, optional: true
      belongs_to :product_host, optional: true
      belongs_to :taxon, optional: true
      belongs_to :factory_taxon, optional: true

      has_many :production_carts, dependent: :destroy_async
      has_many :carts, through: :production_carts
      has_many :production_items, dependent: :destroy_async
      has_many :production_plans, dependent: :destroy_async
      has_many :stock_logs
      has_many :production_spaces

      has_many :production_parts, dependent: :destroy_async
      has_many :parts, through: :production_parts, dependent: :destroy
      has_many :part_taxons, -> { order(id: :asc) }, through: :production_parts
      has_many :part_productions, class_name: 'ProductionPart', foreign_key: :part_id
      has_many :productions, through: :part_productions

      has_many :brothers, class_name: self.name, primary_key: :product_id, foreign_key: :product_id
      has_many :same_production_parts, class_name: 'ProductionPart', primary_key: :product_id, foreign_key: :product_id
      has_many :same_component_parts, ->(o){ where(product_id: [o.product_id, nil]) }, class_name: 'ComponentPart', primary_key: :taxon_id, foreign_key: :taxon_id
      has_many :same_productions, -> { distinct }, through: :same_production_parts, source: :production
      has_many :same_parts, -> { distinct }, through: :same_production_parts, source: :part
      has_many :same_part_taxons, -> { distinct }, through: :same_production_parts, source: :part_taxon

      has_many :production_provides, foreign_key: :production_id
      has_many :all_provides, class_name: 'ProductionProvide', primary_key: []
      has_many :downstream_provides, class_name: 'ProductionProvide', foreign_key: :upstream_production_id

      accepts_nested_attributes_for :production_parts, allow_destroy: true, reject_if: ->(attributes){ attributes.slice('part_id').blank? }

      scope :enabled, -> { where(enabled: true) }
      scope :default, -> { where(default: true) }
      scope :list, -> { where(enabled: true, default: true) }
      scope :automatic, -> { where(automatic: true) }

      has_one_attached :logo
      paginates_per 20

      validates :str_part_ids, uniqueness: { scope: :product_id }, allow_blank: true

      before_validation :sync_word, if: -> { name_changed? || new_record? }
      before_save :sync_from_product, if: -> { product_id_changed? || (new_record? && product) }
      before_save :compute_profit_price, if: -> { (changes.keys & ['cost_price']).present? }
      before_save :compute_price, if: -> { (changes.keys & ['cost_price', 'profit_price']).present? }
      before_create :init_default
      after_update :set_default, if: -> { default? && saved_change_to_default? }
      after_update :set_enabled, if: -> { saved_change_to_enabled? }
      after_save :compute_min_max_price, if: -> { saved_change_to_price? }
      after_save :init_logo, if: -> { saved_change_to_product_id? && product }
      after_save :sync_log, if: -> { saved_change_to_stock? }
    end

    def init_logo
      self.logo.attach product.logo_blob unless logo.attached?
    end

    def sync_word
      self.word = title
    end

    def title
      return unless product
      if name.present?
        "#{product.name}（#{name}）"
      else
        product.name
      end
    end

    def compute_min_max_price
      product.compute_min_max_later if product
    end

    def compute_profit_price
      if product&.profit_margin
        self.profit_price = self.cost_price * product.profit_margin
      end
    end

    def compute_price
      self.price = self.cost_price.to_d + self.profit_price.to_d
    end

    def disabled?(part_id)
      same_production_parts.where.not(production_id: self.id).where(part_id: part_ids - [part_id]).blank?
    end

    def max_indent
      [cost_price.to_money.indent, profit_price.to_money.indent, price.to_money.indent].max
    end

    def card_price_min(cart)
      human_codes = organ.card_templates.load.pluck(:code, :name).to_h
      human = card_price.each_with_object({}) { |(k, v), h| h.merge! k => { name: human_codes[k], price: v.to_d } }

      codes = cart && cart.cards.map(&->(i){ i.card_template.code })
      r = human.slice(*codes)
      if r.present?
        min = r.min_by { |_, v| v[:price] }
        min[1].merge! checked: true
      else
        min = human.min_by { |_, v| v[:price] }
      end

      min[1] if min.present?
    end

    def card_price_all(cart)
      codes = organ.card_templates.pluck(:code, :name).to_h
      check_codes = cart && cart.cards.map(&->(i){ i.card_template.code })
      card_price.each_with_object({}) { |(k, v), a| a[k] = { name: codes[k], price: v.to_d, checked: Array(check_codes).include?(k) } }
    end

    def sync_from_product
      self.taxon_id = product.taxon_id
      self.organ_id = product.organ_id
    end

    def parts_hash
      production_parts.each_with_object({}) do |i, h|
        h.merge! i.part_id => i
      end
    end

    def compute_cost_price
      _cost_price = production_parts.select(&:not_destroyed?).sum { |i| i.part.price ? i.part.price * i.number : 0 }  # price 可由系统提前设定，未设定则通过零件自动计算
      self.cost_price = product.base_price.to_d + _cost_price
    end

    def compute_part_str
      p_ids = production_parts.select(&:not_destroyed?).map { |i| "#{i.part_id}_#{i.number}" }
      p_ids.sort!

      self.str_part_ids = p_ids.join(',')
    end

    def compute_part_str!
      compute_part_str
      compute_cost_price
      self.save!
    end

    def enter_url
      Rails.application.routes.url_for(
        controller: 'factory/productions',
        action: 'show',
        id: self.id
      )
    end

    def to_cpcl(qr = BaseCpcl.new)
      qr.text word
      qr.qrcode_right(enter_url)
      qr
    end

    def init_default
      self.default = true if self.brothers.blank?
    end

    def set_default
      self.class.where.not(id: self.id).where(product_id: self.product_id).update_all(default: false)
    end

    def set_enabled
      if enabled
        organ.update production_enabled: true
      else
        organ.update production_enabled: self.class.where(organ_id: organ_id).exists?(enabled: true)
      end
    end

    def sync_log
      log = self.stock_logs.build
      log.stock = stock
      if last_stock_log&.dig('source_type')
        log.assign_attributes last_stock_log.slice('title', 'amount', 'source_type', 'source_id')
      else
        log.amount = stock - stock_before_last_save.to_d
        log.title = '手动修改库存'
      end
      log.save
    end

  end
end
