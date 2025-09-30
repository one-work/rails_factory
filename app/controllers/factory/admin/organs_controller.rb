module Factory
  class Admin::OrgansController < Admin::BaseController
    before_action :set_organ

    private
    def set_organ
      @organ = current_organ
    end

    def organ_params
      params.fetch(:organ, {}).permit(
        :dispatch,
        :share_logo
      )
    end

  end
end
