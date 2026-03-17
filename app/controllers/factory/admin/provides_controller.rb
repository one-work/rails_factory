module Factory
  class Admin::ProvidesController < Admin::BaseController
    before_action :set_new_provide, only: [:new, :create]
    before_action :set_provide, only: [:show, :edit, :update, :destroy, :actions, :invite]

    def index
      @provides = Provide.where(default_params).order(product_provides_count: :desc).page(params[:page])
    end

    def search
      ids = @taxon.provides.pluck(:provider_id)
      ids.append current_organ.id
      @organs = Org::Organ.where.not(id: ids).default_where('name-like': params['name-like'])
    end

    private
    def set_new_provide
      @provide = current_organ.provides.build(provide_params)
    end

    def set_provide
      @provide = current_organ.provides.find params[:id]
    end

    def provide_params
      _p = params.fetch(:provide, {}).permit(
        :name,
        :provider_id
      )
      _p.merge! default_form_params
    end

  end
end
