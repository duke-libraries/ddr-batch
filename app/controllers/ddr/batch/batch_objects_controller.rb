module Ddr::Batch

  class BatchObjectsController < ApplicationController

    load_and_authorize_resource class: BatchObject

    def index
    end

    def show
    end

  end

end  