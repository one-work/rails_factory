module Factory
  class In::ProductionsController < Admin::ProductionsController
    include Trade::Controller::Me
    include Controller::In
    before_action :set_factory_taxon, if: -> { params[:factory_taxon_id].present? }
    before_action :set_production, only: [:show]
    before_action :set_cart, only: [:index, :show, :create_dialog]

    def index
      q_params = {
        organ_id: current_organ.provider_ids
      }
      q_params.merge! production_plans: { produce_on: params[:produce_on], scene_id: params[:scene_id] } if params[:produce_on] && params[:scene_id]
      q_params.merge! params.permit(:organ_id, :factory_taxon_id, 'name-like')

      @productions = Production.includes(:parts, :product, :production_plans).default_where(q_params).default.order(id: :desc).page(params[:page]).per(params[:per])
    end

    def create_dialog
      from_production = Production.find params[:id]
      @production = ComponentPart.change_default_production(from_production.product, production_params)

      if params[:component_id].present?
        @component = Component.find params[:component_id]
        @component_parts = @production.same_component_parts.where(component_id: @component.id)
      end
    end

    private
    def set_production
      @production = Production.find params[:id]
    end

    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

    def production_params
      params.permit(production_parts_attributes: {})
    end

  end
end
