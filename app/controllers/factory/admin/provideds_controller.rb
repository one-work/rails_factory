module Factory
  class Admin::ProvidedsController < Admin::BaseController
    before_action :set_production
    before_action :set_part_provider, only: [:show, :edit, :select, :update, :destroy]

    def index
      q_params = {}
      q_params.merge! params.permit(:provider_id)

      @part_providers = @production.part_providers.default_where(q_params).order(id: :asc).page(params[:page])
    end

    def new
      @part_provider = @production.part_providers.build
    end

    def create
      @part_provider = @production.part_providers.build(part_provider_params)

      unless @part_provider.save
        render :new, locals: { model: @part_provider }, status: :unprocessable_entity
      end
    end

    def select
      if part_provider_params[:selected] == 'true'
        @part_provider.set_selected
      else
        @part_provider.update(part_provider_params)
      end
    end

    private
    def set_production
      @production = Production.find params[:production_id]
    end

    def set_part_provider
      @part_provider = @production.part_providers.find(params[:id])
    end

    def part_provider_params
      params.fetch(:part_provider, {}).permit(
        :export_price
      )
    end

  end
end
