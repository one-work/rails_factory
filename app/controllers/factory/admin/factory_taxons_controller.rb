module Factory
  class Admin::FactoryTaxonsController < Admin::BaseController
    before_action :set_factory_taxon, only: [:show]

    def index
      @factory_taxons = FactoryTaxon.page(params[:page])
    end

    private
    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:id]
    end

  end
end