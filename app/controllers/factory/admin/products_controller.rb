module Factory
  class Admin::ProductsController < Admin::BaseController
    before_action :set_brands, only: [:new, :create, :edit, :update]
    before_action :set_product, only: [:show, :edit, :update, :destroy, :reorder, :actions, :part, :edit_image]
    before_action :set_new_product, only: [:new, :create, :scan, :manual]
    before_action :set_taxons, only: [:index, :buy, :new, :create, :edit, :update]
    before_action :set_cart, only: [:buy]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id)

      @products = Product.includes(
        :taxon,
        :productions,
        :taxon_components,
        :product_components,
        logo_attachment: :blob,
        covers_attachments: :blob
      ).default_where(q_params).order(taxon_id: :asc).page(params[:page])
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
      @product.taxon = Taxon.default_where(default_params).new
    end

    def scan
      type, code = params[:result].split(',')
      barcode = Barcode.find_by(gtin: code)
      if barcode
        @product.name = barcode.name
        @product.productions.build(cost_price: barcode.price)
      else
        render :scan_blank
      end
    end

    def manual

    end

    def edit
      @product.taxon ||= Taxon.default_where(default_params).first
    end

    private
    def set_taxon
      @taxon = Taxon.default_where(default_params).find params[:taxon_id]
    end

    def set_taxons
      @taxons = Taxon.default_where(default_params).order(id: :asc)
    end

    def set_product
      @product = Product.default_where(default_params).find(params[:id])
    end

    def set_new_product
      @product = Product.new(product_params)
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
        :taxon_id,
        :base_price,
        :manual,
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
