module Factory
  class Panel::OrgansController < Org::Panel::OrgansController

    def index
      q_params = {}
      q_params.merge! params.permit(:production_enabled)

      @organs = Organ.includes(:provider).with_attached_logo.roots.default_where(q_params).order(id: :desc).page(params[:page])
    end

    private
    def filter_columns
      {
        'production_enabled' => { type: 'dropdown', default: true },
        'name' => { type: 'search', default: true }
      }
    end

    def organ_params
      params.fetch(:organ, {}).permit(
        :production_enabled
      )
    end
  end
end
