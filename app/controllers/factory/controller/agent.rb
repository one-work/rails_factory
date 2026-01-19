module Factory
  module Controller::Agent
    extend ActiveSupport::Concern
    include Controller::Application
    include Org::Controller::Admin if defined? RailsOrg
    include Roled::Controller::Admin
    include Com::Controller::Admin

    included do
      before_action :require_org_member
      before_action :require_role
    end

    def set_cart
      @cart = Trade::Cart.get_cart(params, agent_id: current_member.id, **default_form_params)
    end

  end
end
