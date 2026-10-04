module Factory
  class Panel::LogosController < Panel::BaseController

    def index
      q_params = {}
      q_params.merge! params.permit(:title)

      @logos = Logo.default_where(q_params).page(params[:page])
    end

  end
end
