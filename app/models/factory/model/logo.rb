module Factory
  module Model::Logo
    extend ActiveSupport::Concern

    included do
      attribute :title, :string

      belongs_to :organ, class_name: 'Org::Organ', optional: true

      has_one_attached :media
    end

  end
end
