module Factory
  module Controller::In
    extend ActiveSupport::Concern

    def set_scenes
      @next_plan = ProducePlan.next_plan(organ_ids: current_organ.provider_ids, produce_on: params[:produce_on].to_date, scene_id: params[:scene_id])
      @prev_plan = ProducePlan.prev_plan(organ_ids: current_organ.provider_ids, produce_on: params[:produce_on].to_date, scene_id: params[:scene_id])

      ids = Factory::ProducePlan.where(produce_on: params[:produce_on], organ_id: current_organ.provider_ids).select(:scene_id).distinct.pluck(:scene_id)
      @scenes = Factory::Scene.where(id: ids)
    end

    def set_cart
      options = {
        member_organ_id: current_organ.id,
        purchasable: false,
        user_id: nil,
        member_id: nil
      }
      options.merge! client_id: nil, contact_id: nil if defined? RailsCrm

      @cart = Trade::Cart.where(options).find_or_create_by(good_type: 'Factory::Production', aim: 'use')
      @cart.compute_amount! unless @cart.fresh
    end

  end
end
