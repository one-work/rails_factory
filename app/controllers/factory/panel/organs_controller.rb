module Factory
  class Panel::OrgansController < Org::Panel::OrgansController

    def index
      @organs = Organ.roots.page(params[:page])
    end

    private
    def organ_params
      params.fetch(:organ, {}).permit(
        :production_enabled
      )
    end
  end
end
