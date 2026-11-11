module Factory
  class Admin::Taxon::ProductionProvidesController < Admin::ProductionProvidesController

    def index
      @products = @taxon.products.includes(
        productions: [:production_provides, production_parts: :part],
        logo_attachment: :blob
      ).order(id: :asc).page(params[:page])
    end

  end
end
