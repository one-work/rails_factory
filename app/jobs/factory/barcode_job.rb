module Factory
  class BarcodeJob < ApplicationJob

    def perform
      Barcode.init_from_csv
    end

  end
end
