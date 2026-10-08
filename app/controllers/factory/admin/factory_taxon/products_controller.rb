module Factory
  class Admin::FactoryTaxon::ProductsController < Admin::ProductsController
    before_action :set_factory_taxon

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:published, 'name-like')

      @products = @factory_taxon.products.with_attached_logo.includes(
        :brand,
        :product_components,
        :productions,
        product_provides: :provide
      ).default_where(q_params).order(position: :asc).page(params[:page])
    end

    private
    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

  end
end
