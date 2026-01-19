module Factory
  class Admin::RentChargesController < Trade::Admin::RentChargesController
    before_action :set_production
    before_action :set_item, only: [:show, :edit, :update, :destroy, :print]

    def index
      q_params = {}
      q_params.merge! params.permit(:address_id, :produce_on, :status)

      @rent_charges = @production.rent_charges.default_where(q_params).page(params[:page])
    end

    def print
      @item.print
    end

    private
    def set_production
      @production = Production.find params[:production_id]
    end

    def set_item
      @item = @production.items.find(params[:id])
    end

    def model_klass
      Trade::RentCharge
    end

    def model_name
      'rentable'
    end

    def item_params
      params.fetch(:item, {}).permit(
        :number,
        :amount,
        :note,
        :extra,
        :status
      )
    end

  end
end
