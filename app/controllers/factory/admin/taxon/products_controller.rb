module Factory
  class Admin::Taxon::ProductsController < Admin::ProductsController
    before_action :set_taxon
    before_action :set_brands, only: [:new, :create, :edit, :update]
    before_action :set_product, only: [:show, :edit, :update, :destroy, :reorder, :actions, :part, :edit_image]
    before_action :set_new_product, only: [:new, :create]
    before_action :set_taxons, only: [:index, :edit, :update]
    before_action :set_cart, only: [:buy]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:name)

      @products = @taxon.products.includes(
        :brand,
        :product_components,
        :productions,
        logo_attachment: :blob,
        covers_attachments: :blob
      ).default_where(q_params).order(position: :asc).page(params[:page])
    end

    def buy
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id, :name)

      @products = Product.includes(
        :brand,
        productions: { production_provides: :provide },
        logo_attachment: :blob,
        covers_attachments: :blob
      ).default_where(q_params).order(position: :asc).page(params[:page])
    end

    def new
      @product.productions.build(enabled: true)
    end

    def edit
      @product.taxon ||= Taxon.default_where(default_params).first
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

    def set_new_product
      @product = @taxon.products.build(product_params)
    end

    def set_brands
      @brands = Brand.default_where(default_params)
    end

    def set_cart
      @cart = Trade::Cart.get_cart(params, member_organ_id: current_organ.id, purchasable: true)
    end

    def product_params
      p = params.fetch(:product, {}).permit(
        :name,
        :brand_id,
        :description,
        :qr_prefix,
        :profit_margin,
        :logo,
        :specialty,
        :base_price,
        :taxon_id,
        :published,
        :taxon_ancestors,
        part_ids: [],
        covers: [],
        images: [],
        productions_attributes: {}
      )
      p.merge! default_form_params
    end

  end
end
