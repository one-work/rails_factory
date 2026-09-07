module Factory
  class Admin::ProducePlansController < Admin::BaseController
    before_action :set_produce_plan, only: [:show, :products, :edit, :update, :destroy]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:title)

      @produce_plans = ProducePlan.default_where(q_params).order(produce_on: :desc).page(params[:page])
    end

    def products
      @taxons = Taxon.default_where(default_params)
      @production_plans = @produce_plan.production_plans
      q_params = {
        taxon_id: @taxons.map(&:id)
      }
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id)

      @productions = Production.includes(:taxon, :product, logo_attachment: :blob).default_where(q_params).where.not(id: @production_plans.pluck(:production_id)).order(taxon_id: :desc).page(params[:page])
    end

    private
    def set_produce_plan
      @produce_plan = ProducePlan.default_where(default_params).find params[:id]
    end

    def produce_plan_params
      p = params.fetch(:produce_plan, {}).permit(
        :scene_id,
        :produce_on,
        :book_start_at,
        :book_finish_at,
        :state
      )
      p.merge! default_form_params
    end

  end
end
