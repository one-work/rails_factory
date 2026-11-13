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
      @cart = Trade::Cart.get_cart(params, member_organ_id: current_organ.id, purchasable: true)
    end

  end
end
