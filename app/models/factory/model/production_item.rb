module Factory
  module Model::ProductionItem
    extend ActiveSupport::Concern

    included do
      attribute :code, :string
      attribute :amount, :decimal, default: 1
      attribute :came_at, :datetime, default: -> { Time.current }

      belongs_to :production
      belongs_to :product_item, optional: true

      has_many :part_items
      has_many :stock_logs, primary_key: :production_id, foreign_key: :production_id

      enum :state, {
        purchased: 'purchased',
        produced: 'produced',
        received: 'received',
        warehouse_in: 'warehouse_in',
        grid_in: 'grid_in',
        grid_out: 'grid_out',
        warehouse_out: 'warehouse_out',
        used: 'used'
      }, default: 'purchased'

      after_initialize :init_code, if: :new_record?
      after_save :sync_stock, if: -> { saved_change_to_amount? }
    end

    def init_code
      self.code ||= UidUtil.nsec_uuid(production&.qr_code)
    end

    def qrcode_url
      QrcodeUtil.data_url(code)
    end

    def enter_url
      Rails.application.routes.url_for(
        controller: 'factory/me/production_items',
        action: 'qrcode',
        id: self.id
      )
    end

    def qrcode_enter_url
      QrcodeUtil.data_url(enter_url)
    end

    def qrcode_enter_png
      QrcodeUtil.code_png(enter_url, border_modules: 0, fill: 'pink')
    end

    def to_cpcl(qr = BaseCpcl.new)
      qr.text production.word
      qr.text code
      qr.qrcode_right(enter_url)
      qr.render
      qr
    end

    def to_pdf
      pdf = BasePdf.new(width: 80.mm, height: 50.mm)
      pdf.text production.name
      pdf.text code
      pdf.text 'dddd'
      pdf.text 'rrrr'
      pdf.bounding_box([pdf.bounds.right - 60, pdf.bounds.top], width: 60, height: 60) do
        pdf.image StringIO.new(qrcode_enter_png.to_blob), fit: [60, 60], position: :right, vposition: :top
      end
      pdf
    end

    def print
      qr = BaseTspl.new
      production.organ.device.print(
        data: to_cpcl(qr)
      )
    end

    def sync_stock
      change = amount - amount_before_last_save.to_d

      production.stock = production.stock.to_d + change

      log = self.stock_logs.build
      log.amount = change
      log.title = '录入商品'

      #log.save
      production.save
    end

  end
end
