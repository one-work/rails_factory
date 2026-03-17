module Factory
  class Admin::Provide::ProductProvidesController < Admin::BaseController
    before_action :set_provide
    before_action :set_product_provide, only: [:show, :edit, :update, :destroy]

    def index
      q_params = {}

      @product_provides = @provide.product_provides.includes(product: :taxon).default_where(q_params).order(id: :asc).page(params[:page])
    end

    private
    def set_provide
      @provide = Provide.find params[:provide_id]
    end

    def set_product_provide
      @product_provide = @provide.product_provides.find(params[:id])
    end

  end
end
