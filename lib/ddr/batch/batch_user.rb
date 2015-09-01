module Ddr::Batch
  module BatchUser
    extend ActiveSupport::Concern

    included do
      has_many :batches, :inverse_of => :user, class_name: Ddr::Batch::Batch
    end

  end
end