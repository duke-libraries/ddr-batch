module Ddr::Batch
  class ApplicationController < ActionController::Base

    include Ddr::Auth::RoleBasedAccessControlsEnforcement

    helper_method :acting_as_superuser?

    def acting_as_superuser?
      signed_in?(:superuser)
    end

  end
end
