module Factory
  module Controller::Application
    extend ActiveSupport::Concern

    def set_produce_plans
      if params[:produce_on] && params[:scene_id]
        @produce_plan = ProducePlan.find_by(produce_on: params[:produce_on], scene_id: params[:scene_id])
      end
      if @produce_plan
        q_params = { produce_on: @produce_plan.produce_on }
        q_params.merge! default_params
        q_params.merge! params.permit(:produce_on)

        @produce_plans = ProducePlan.default_where(q_params).order(id: :asc)
      else
        @produce_plans = ProducePlan.none
      end
    end

    def set_cart
      if current_user
        @cart = Trade::Cart.get_cart(params, user_id: current_user.id, **default_form_params)
      end
    end

  end
end
