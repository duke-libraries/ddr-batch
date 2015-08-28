require 'ddr/batch/engine'
require 'ddr/batch/version'
require 'ddr/models'

require 'paperclip'

module Ddr
  module Batch
    extend ActiveSupport::Autoload

    autoload :BatchUser

    def self.table_name_prefix
    end

  end
end
