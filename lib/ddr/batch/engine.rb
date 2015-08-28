module Ddr
  module Batch
    class Engine < ::Rails::Engine

      isolate_namespace Ddr::Batch

      config.generators do |g|
        g.test_framework :rspec
        g.fixture_replacement :factory_girl
      end

    end
  end
end
