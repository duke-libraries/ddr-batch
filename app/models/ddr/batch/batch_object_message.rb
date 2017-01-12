module Ddr::Batch
  class BatchObjectMessage < ActiveRecord::Base
    belongs_to :batch_object, :inverse_of => :batch_object_messages

    validates_presence_of :message

  end
end
