module Factory
  module Controller::Our
    extend ActiveSupport::Concern
    include Org::Controller::Our

    included do
      before_action :require_client
    end

    def require_client
      return if current_client

      redirect_to url_for(controller: 'trade/our/carts', action: 'list', **params.permit(:auth_token, :role_id))
    end

  end
end
