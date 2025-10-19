module Factory
  class Our::ProductionsController < ProductionsController
    include Controller::Our
    before_action :set_produce_plans, only: [:index, :plan]
    before_action :set_production, only: [:show, :list]
    before_action :set_card_templates, only: [:index]
    before_action :set_scene, only: [:index, :members], if: -> { params[:scene_id].present? }
    before_action :set_cart, only: [:index, :members]
    before_action :set_members_production, only: [:members]
    before_action :set_items, only: [:members]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! production_plans: { produce_on: params[:produce_on], scene_id: params[:scene_id] } if params[:produce_on] && params[:scene_id]
      q_params.merge! params.permit('name-like', :taxon_id)

      @productions = Production.includes(:parts, :production_plans, product: { logo_attachment: :blob }).default_where(q_params).default.order(id: :desc).page(params[:page]).per(params[:per])
    end

    def members
      @members = current_client.organ.members.includes(avatar_attachment: :blob).order(id: :asc).page(params[:page])
    end

    def list
      q_params = {
        produce_on: params[:produce_on],
        scene_id: params[:scene_id]
      }
      q_params.merge! default_params

      @production_plans = ProductionPlan.includes(production: [:parts, product: { logo_attachment: :blob }]).default_where(q_params).page(params[:page]).per(10)
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

    def set_members_production
      q_params = {
        production_plans: {
          produce_on: params[:produce_on],
          scene_id: params[:scene_id]
        }
      }
      q_params.merge! default_params

      if params[:production_id]
        @production = Production.find params[:production_id]
      else
        @production = Production.includes(:parts, :product).joins(:production_plans).where(q_params).take
      end
    end

    def set_card_templates
      @card_templates = Trade::CardTemplate.default_where(default_params)
    end

    def set_factory_taxon
      #@factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

    def set_cart
      @cart = Trade::Cart.get_cart(params, member_organ_id: current_client.organ_id, **default_form_params)
    end

    def set_items
      @items = @cart.items.includes(:member).where(produce_on: params[:produce_on], scene_id: params[:scene_id])
    end

    def _prefixes
      super do |pres|
        pres + ['factory/in/productions', "factory/in/productions/_#{params[:action]}"]
      end
    end

  end
end
