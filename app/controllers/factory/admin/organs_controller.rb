module Factory
  class Admin::OrgansController < Admin::BaseController
    before_action :set_organ

    def ai_generate
      @organ.generate_share_logo
    end

    private
    def set_organ
      @organ = current_organ
    end

    def organ_params
      params.fetch(:organ, {}).permit(
        :name,
        :dispatch,
        :print_note,
        :share_logo,
        dispatches: []
      )
    end

  end
end
