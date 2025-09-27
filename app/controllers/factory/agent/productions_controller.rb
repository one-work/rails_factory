module Factory
  class Agent::ProductionsController < ProductionsController
    include Controller::Agent
    before_action :set_produce_plans, only: [:index, :plan]
    before_action :set_production, only: [:show, :list]
    before_action :set_card_templates, only: [:index]
    before_action :set_scene, only: [:index], if: -> { params[:scene_id].present? }
    before_action :set_desk, only: [:index], if: -> { params[:desk_id].present? }
    before_action :set_cart, only: [:index, :nav, :show, :create_dialog]

    def index
      params.with_defaults! per: 20
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id)
      q_params.merge! production_plans: { produce_on: params[:produce_on], scene_id: params[:scene_id] } if params[:produce_on] && params[:scene_id]

      @productions = Production.includes(:parts, :production_plans, :taxon, product: [:productions, { logo_attachment: :blob }]).list.default_where(q_params).order(position: :asc).page(params[:page]).per(params[:per])
    end

    def list
      q_params = {
        production_plans: {
          produce_on: params[:produce_on],
          scene_id: params[:scene_id]
        },
      }
      q_params.merge! default_params

      @productions = Production.includes(:parts, :production_plans, product: { logo_attachment: :blob }).default_where(q_params).default.page(params[:page]).per(10)
    end

    def produce_on
      @produce_plan = ProducePlan.find params[:produce_plan_id]
    end

    def scene
      @produce_plan = ProducePlan.find params[:produce_plan_id]
      q_params = { produce_on: @produce_plan.produce_on }
      q_params.merge! default_params

      @produce_plans = ProducePlan.default_where(q_params).order(id: :asc)
    end

    private
    def set_production
      @production = Production.find params[:id]
    end

    def set_scene
      @scene = Scene.find params[:scene_id]
    end

    def set_desk
      @desk = Space::Desk.find params[:desk_id]
    end

    def set_card_templates
      @card_templates = Trade::CardTemplate.default_where(default_params)
    end

    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

    def set_cart
      @cart = Trade::Cart.get_cart(params, agent_id: current_member.id, **default_params)
    end

  end
end
