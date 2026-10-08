module Factory
  class Admin::FactoryTaxonsController < Admin::BaseController
    before_action :set_factory_taxon, only: [:show]

    def index
      @factory_taxons = FactoryTaxon.page(params[:page])
    end

    def show
      q_params = {}

      @taxons = @factory_taxon.taxons
      @products = @factory_taxon.products.default_where(q_params).page(params[:page])

      product_ids = @products.pluck(:id)
      @select_ids = ProductProvide.default_where(default_params).where(upstream_product_id: product_ids).pluck(:upstream_product_id)
    end

    def copy
      @product = Product.find params[:product_id]
      downstream_provide = @product.downstream_provides.find_or_initialize_by(organ_id: current_organ.id)
      #downstream_provide.taxon = @taxon
      downstream_provide.save
    end

    private
    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:id]
    end

  end
end