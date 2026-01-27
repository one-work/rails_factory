module Factory
  class Admin::TaxonsController < Admin::BaseController
    before_action :set_taxon, only: [
      :show, :productions, :edit, :update, :reorder, :destroy,
      :import, :copy, :prune
    ]
    before_action :set_factory_taxons, only: [:index, :new, :edit, :edit, :update]
    before_action :set_scenes, only: [:index, :new, :edit]
    before_action :set_products, only: [:import]
    before_action :set_new_taxon, only: [:new, :create]
    before_action :set_taxons, only: [:new, :create]
    before_action :set_own_taxons, only: [:edit, :update]
    before_action :set_production, only: [:copy, :prune]
    before_action :set_providers, only: [:import, :productions]
    before_action :set_count_hash, only: [:update]

    def index
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:name)

      @taxons = Taxon.default_where(q_params).roots.order(position: :asc).page(params[:page])
      @count_hash = Factory::Production.default_where(default_params).where(enabled: true).group(:taxon_id).count
    end

    def all
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:name)

      @taxons = Taxon.includes(:factory_taxon).default_where(q_params).order(position: :asc)
      @factory_taxons = FactoryTaxon.where.not(id: @taxons.pluck(:factory_taxon_id)).order(position: :asc)
    end

    def import
      q_params = {
        #organ_id: @taxon.provider_ids
      }
      #q_params.merge! params.permit(:organ_id) if @taxon.provider_ids.map(&:to_s).include? params[:organ_id]
      if @taxon.factory_taxon
        @products = @taxon.factory_taxon.products.default_where(q_params).page(params[:page])
      else
        @products = Product.default_where(q_params).page(params[:page])
      end

      product_ids = @products.pluck(:id)
      @select_ids = ProductionProvide.default_where(default_params).where(upstream_product_id: product_ids).pluck(:upstream_product_id)
      @imported_production_ids = ProductionProvide.default_where(default_params).distinct(:upstream_production_id).pluck(:upstream_production_id)
    end

    def copy
      downstream_provide = @production.downstream_provides.find_or_initialize_by(organ_id: current_organ.id)
      downstream_provide.taxon = @taxon
      downstream_provide.save
    end

    def prune
      production = @production.downstream_provides.find_by(organ_id: current_organ.id)
      production.destroy
    end

    private
    def set_taxon
      @taxon = Taxon.find(params[:id])
    end

    def set_factory_taxons
      @factory_taxons = FactoryTaxon.all.limit(10)
    end

    def set_factory_taxon
      @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
    end

    def set_new_taxon
      if params[:factory_taxon_id].present?
        @factory_taxon = FactoryTaxon.find params[:factory_taxon_id]
        @taxon = @factory_taxon.taxons.build(taxon_params)
        @taxon.scene_id = @factory_taxon.scene_id
      else
        @taxon = Taxon.new(taxon_params)
      end
    end

    def set_taxons
      if params[:factory_taxon_id].present?
        @taxons = @factory_taxon.taxons.default_where(default_params)
      end
    end

    def set_count_hash
      @count_hash = { @taxon.id => @taxon.productions.where(enabled: true).count }
    end

    def set_own_taxons
      if @taxon.factory_taxon
        @taxons = @taxon.factory_taxon.taxons.default_where(default_params)
      else
        @taxons = Taxon.none
      end
    end

    def set_scenes
      @scenes = Scene.default_where(default_params)
    end

    def set_products
      q_params = {}
      q_params.merge! params.permit(:organ_id)

      if @taxon.factory_taxon
        @products = @taxon.factory_taxon.products.default_where(q_params).page(params[:page])
      else
        @products = Product.default_where(q_params).page(params[:page])
      end

      product_ids = @products.pluck(:id)
      @select_ids = ProductionProvide.default_where(default_params).where(product_id: product_ids).pluck(:product_id)
    end

    def set_production
      @production = Production.where(organ_id: @taxon.provider_ids).find params[:production_id]
    end

    def set_providers
      if @taxon.factory_taxon
        @providers = @taxon.factory_taxon.providers
      else
        @providers = current_organ.providers
      end
    end

    def taxon_params
      _p = params.fetch(:taxon, {}).permit(
        :name,
        :position,
        :logo,
        :logo_color,
        :parent_id,
        :parent_ancestors,
        :enabled,
        :customizable,
        :nav,
        :factory_taxon_id,
        :scene_id
      )
      _p.merge! default_form_params
    end

  end
end
