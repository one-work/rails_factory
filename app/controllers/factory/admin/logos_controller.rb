module Factory
  class Admin::LogosController < Admin::BaseController

    def search
      @logos = Logo.page(params[:page])
    end

  end
end
