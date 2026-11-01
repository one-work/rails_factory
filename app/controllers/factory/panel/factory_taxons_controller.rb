module Factory
  class Panel::FactoryTaxonsController < Panel::BaseController
    before_action :set_factory_taxon, only: [:show, :edit, :update, :destroy]
    before_action :set_scenes, only: [:new, :create, :edit, :update]
    before_action :set_new_factory_taxon, only: [:new, :create]

    def index
      @factory_taxons = FactoryTaxon.order(id: :asc).page(params[:page])
    end

    private
    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find(params[:id])
    end

    def set_new_factory_taxon
      @factory_taxon = FactoryTaxon.new(factory_taxon_params)
    end

    def set_scenes
      @scenes = Scene.all.limit(10)
    end

    def factory_taxon_params
      params.fetch(:factory_taxon, {}).permit(
        :name,
        :logo,
        :scene_id
      )
    end

  end
end
