module Factory
  class ProductionsController < BaseController
    before_action :set_taxon, if: -> { params[:taxon_id].present? }
    before_action :set_station, only: [:index, :show]
    before_action :set_produce_plans, only: [:index, :plan]
    before_action :set_taxons, only: [:index, :rent]
    before_action :set_production, only: [:show, :actions]
    before_action :set_scene, only: [:index, :nav], if: -> { params[:produce_on].present? && params[:scene_id].present? }
    before_action :set_cart, only: [:index, :nav, :show, :dialog, :create_dialog]
    before_action :set_rent_cart, only: [:rent]
    before_action :require_user, only: [:index, :show]

    def index
      q_params = {}
      q_params.merge! default_params

      taxon_ids = Taxon.default_where(default_params).where(nav: false).pluck(:id)
      q_params.merge! taxon_id: taxon_ids if taxon_ids.present?

      q_params.merge! params.permit(:taxon_id, :factory_taxon_id, 'word-like')

      if @produce_plan
        if @produce_plan.expired?
          render 'expired'
        else
          @productions = @produce_plan.productions.includes(:organ, :parts, product: [:brand, { logo_attachment: :blob }]).page(params[:page]).per(params[:per])
        end
      else
        @productions = Production.includes(:taxon, :parts, :organ, product: [:brand, { logo_attachment: { blob: { variant_records: { image_attachment: :blob }}}}]).list.default_where(q_params).order(position: :asc).page(params[:page]).per(params[:per])
      end
    end

    def swift
      index
      @order = current_user.orders.build
      @order.items.build
    end

    def nav
      q_params = {}
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id, 'name-like')

      if @produce_plan
        if @produce_plan.expired?
          render 'expired'
        else
          @productions = @produce_plan.productions.includes(:organ, :parts, product: { logo_attachment: :blob }).list.default_where(q_params).order(position: :asc).page(params[:page]).per(params[:per])
        end
      else
        @productions = Production.includes(:organ, :parts, product: { logo_attachment: :blob }).list.default_where(q_params).order(position: :asc).page(params[:page]).per(params[:per])
      end
    end

    def rent
      q_params = {
        'rent_charges_count-gt': 0
      }
      q_params.merge! default_params
      q_params.merge! params.permit(:taxon_id, 'name-like')

      @productions = Production.includes(:organ, :parts, product: { logo_attachment: :blob }).list.default_where(q_params).order(position: :asc).page(params[:page]).per(params[:per])
    end

    def produce_on
      @produce_plan = ProducePlan.find params[:produce_plan_id]
    end

    def scene
      @produce_plan = ProducePlan.find params[:produce_plan_id]
      q_params = { produce_on: @produce_plan.produce_on }
      q_params.merge! default_params

      @produce_plans = ProducePlan.default_where(q_params).order(id: :asc)
    end

    def change_dispatch
    end

    def show
    end

    def dialog
      from_production = Production.find params[:id]
      @production = from_production.brothers.find params[:target_id]
    end

    def create_dialog
      from_production = Production.find params[:id]
      temp_production = from_production.product.productions.build(production_params)
      temp_production.compute_part_str
      @production = from_production.product.productions.find_by(str_part_ids: temp_production.str_part_ids)

      unless @production
        @production = temp_production
        @production.compute_cost_price
        @production.save!
      end
      logger.debug "\e[35m  Production: #{@production.id}  \e[0m"
    end

    def create
      r = params.fetch(:part_ids, []).reject(&:blank?).map!(&:to_i).sort!
      @production_part = ProductionPart.find_by(product_id: params[:product_id], part_id: params[:part_ids])
      @production = @production_part.production
    end

    private
    def set_production
      @production = Production.find params[:id]
    end

    def set_scene
      @scene = Scene.find_by id: params[:scene_id]
      @next_plan = ProducePlan.next_plan(organ_ids: current_organ.id, produce_on: params[:produce_on].to_date, scene_id: params[:scene_id])
      @prev_plan = ProducePlan.prev_plan(organ_ids: current_organ.id, produce_on: params[:produce_on].to_date, scene_id: params[:scene_id])

      ids = Factory::ProducePlan.where(produce_on: params[:produce_on], organ_id: current_organ.id).select(:scene_id).distinct.pluck(:scene_id)
      @scenes = Factory::Scene.where(id: ids)
    end

    def set_taxons
      q_params = {
        'products_count-gt': 0
      }
      q_params.merge! default_params
      @taxons = Taxon.with_attached_logo.enabled.default_where(q_params).order(id: :asc)
    end

    def set_taxon
      @taxon = Taxon.find params[:taxon_id] if params[:taxon_id]
    end

    def set_rent_cart
      options = {}
      options.merge! default_form_params

      if current_user
        options.merge! user_id: current_user.id, member_id: nil, client_id: nil
        @cart = Trade::Cart.where(options).find_or_create_by(good_type: 'Factory::Production', aim: 'rent')
        @cart.compute_amount! unless @cart.fresh
      end
    end

    def set_station
      if params[:desk_id]
        @desk = Space::Desk.find params[:desk_id]
      elsif params[:station_id]
        @station = Space::Station.find params[:station_id]
      end
    end

    def production_params
      params.permit(
        production_parts_attributes: [:part_id, :component_id, :number]
      )
    end

  end
end
