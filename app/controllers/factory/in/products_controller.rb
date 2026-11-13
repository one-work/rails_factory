module Factory
  class In::ProductsController < Admin::ProductsController
    before_action :set_cart, only: [:index, :custom]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id, :name)

      @products = Product.includes(
        :brand,
        productions: { available_provides: :provide },
        logo_attachment: :blob,
        covers_attachments: :blob
      ).default_where(q_params).order(position: :asc).page(params[:page])
    end

    def custom
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id, :name)

      @products = Product.includes(
        :brand,
        productions: { available_provides: :provide },
        logo_attachment: :blob,
        covers_attachments: :blob
      ).default_where(q_params).order(position: :asc).page(params[:page])
    end

    private
    def set_cart
      @cart = Trade::Cart.get_cart(params, member_organ_id: current_organ.id, purchasable: true)
    end

  end
end
