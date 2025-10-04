module Factory
  module Model::Barcode
    extend ActiveSupport::Concern

    included do
      attribute :gtin, :string  # 条码
      attribute :name, :string
      attribute :spec, :string
      attribute :brand_name, :string
      attribute :unit_name, :string
      attribute :supplier, :string
      attribute :made_in, :string
      attribute :price, :decimal

      index :gtin, unique: true

      belongs_to :unit, class_name: 'Trade::Unit', optional: true

      belongs_to :brand, optional: true

      before_validation :init_brand
      before_validation :init_unit
    end

    def init_brand
      self.brand ||= Brand.find_or_create_by(name: brand_name) if brand_name.present?
    end

    def init_unit
      self.unit ||= Trade::Unit.find_or_create_by(name: unit_name) if unit_name.present?
    end

    class_methods do

      def init_from_csv(path = Rails.root.join('storage/barcodes.csv'))
        CSV.foreach(path, headers: true) do |row|
          begin
            self.create!(row.to_hash.slice('gtin', 'name', 'spec', 'brand_name', 'unit_name', 'supplier', 'made_in', 'price'))
          rescue => e
            puts e.message
          end
        end
      end

    end

  end
end
