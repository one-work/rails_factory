module Factory
  class Product < ApplicationRecord
    include Model::Product
    include Auditor::Ext::Discard if defined? RailsAudit
  end
end
