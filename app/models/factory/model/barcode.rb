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
      attribute :prince, :decimal

      belongs_to :unit, class_name: 'Trade::Unit'

      belongs_to :brand
    end

  end
end
