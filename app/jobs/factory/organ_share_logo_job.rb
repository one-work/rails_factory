module Factory
  class OrganShareLogoJob < ApplicationJob

    def perform(organ)
      organ.generate_share_logo
    end

  end
end
