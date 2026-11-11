module Factory
  class Admin::Taxon::ProductionProvidesController < Admin::BaseController
    before_action :set_taxon

    def index
      @products = @taxon.products.includes(
        productions: [:production_provides, production_parts: :part],
        logo_attachment: :blob
      ).order(id: :asc).page(params[:page])
    end

    private
    def set_taxon
      @taxon = Taxon.find params[:taxon_id]
    end

    def production_provide_params
      params.expect(production_provide: [:cost_price])
    end

  end
end
