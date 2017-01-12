module Ddr
  module Batch
    # Base class for custom exceptions
    class Error < StandardError; end

    # Error processing batch object
    class BatchObjectProcessingError < Error; end

  end
end
