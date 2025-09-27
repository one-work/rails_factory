module Factory
  class In::ItemsController < Trade::In::ItemsController
    before_action :set_cart, only: [
      :show, :edit, :update, :destroy, :actions,
      :create, :edit_assign, :update_assign
    ]
    before_action :set_cart_item, only: [
      :update, :destroy
    ]
    before_action :set_item, only: [
      :show, :edit, :actions, :edit_assign, :update_assign
    ]
    before_action :set_new_item, only: [:create]

    def edit_assign
      upstream_provide_ids = @item.purchase.production_provides.pluck(:provide_id)
      @provides = current_organ.provides.where.not(id: upstream_provide_ids)
    end

    def update_assign
      @item.assign_attributes organ_item_params
      @item.save
    end

    private
    def item_params
      params.permit(
        :good_type,
        :good_id,
        :number,
        :provide_id,
        :organ_id,
        :note,
        :desk_id,
        :current_cart_id
      )
    end

    def organ_item_params
      params.fetch(:item, {}).permit(
        :provide_id
      )
    end

  end
end
