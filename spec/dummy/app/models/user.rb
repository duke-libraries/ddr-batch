class User < ActiveRecord::Base
  include Ddr::Auth::User
  include Ddr::Batch::BatchUser
  include Blacklight::User

end
