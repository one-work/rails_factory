module Factory
  class In::TaxonsController < In::BaseController
    before_action :set_taxon, only: [:show, :edit, :update, :destroy, :actions]

    def index
      @taxons = Taxon.page(params[:page])
    end

    private
    def set_taxon
      @taxon = Taxon.find(params[:id])
    end

    def factory_taxon_params
      params.fetch(:factory_taxon, {}).permit(
        :name,
        :logo
      )
    end

  end
end
