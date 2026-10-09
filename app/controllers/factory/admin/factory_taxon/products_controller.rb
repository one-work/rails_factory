module Factory
  class Admin::FactoryTaxon::ProductsController < Admin::ProductsController
    before_action :set_factory_taxon

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id, 'name-like')

      @taxons = @factory_taxon.taxons
      @products = @factory_taxon.products.with_attached_logo.includes(
        :brand,
        :product_components,
        :productions,
        product_provides: :provide
      ).where.not(organ_id: current_organ.id).default_where(q_params).page(params[:page])

      product_ids = @products.pluck(:id)
      @select_ids = ProductProvide.default_where(default_params).where(upstream_product_id: product_ids).pluck(:upstream_product_id)
    end

    def copy
      @product = Product.find params[:product_id]
      downstream_provide = @product.downstream_provides.find_or_initialize_by(organ_id: current_organ.id)
      downstream_provide.save
    end

    private
    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

  end
end
