module Factory
  class Panel::TaxonsController < Panel::BaseController
    before_action :set_factory_taxon

    def index
      q_params = {}
      q_params.merge! params.permit(:organ_id)

      @taxons = @factory_taxon.taxons.includes(:organ).default_where(q_params).page(params[:page])
    end

    private
    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

  end
end
