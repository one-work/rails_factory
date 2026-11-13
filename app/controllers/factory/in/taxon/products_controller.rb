module Factory
  class In::Taxon::ProductsController < In::ProductsController
    before_action :set_taxon
    before_action :set_product, only: [:show, :edit, :update, :destroy, :reorder, :actions, :part, :edit_image]
    before_action :set_taxons, only: [:index, :edit, :update]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:published, 'name-like')

      @products = @taxon.products.includes(
        :brand,
        productions: { available_provides: :provide, production_parts: :part },
        logo_attachment: :blob,
        covers_attachments: :blob
      ).default_where(q_params).order(position: :asc).page(params[:page])
    end

    private
    def set_taxon
      @taxon = Taxon.default_where(default_params).find params[:taxon_id]
    end

    def set_taxons
      @taxons = Taxon.default_where(default_params)
    end

    def set_product
      @product = Product.find(params[:id])
    end

  end
end
