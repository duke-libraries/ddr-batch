require 'ddr/batch/engine'
require 'ddr/batch/version'
require 'ddr/models'

require 'paperclip'

module Ddr
  module Batch
    extend ActiveSupport::Autoload

    autoload :BatchUser
    autoload :BatchObjectProcessingError, 'ddr/batch/error'

    # Logging level for batch processing - defaults to Logger::INFO
    mattr_accessor :processor_logging_level do
      Logger::INFO
    end

    def self.table_name_prefix
    end

  end
end
