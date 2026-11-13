module Factory
  class In::ProductsController < Admin::ProductsController
    include Controller::In
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

  end
end
