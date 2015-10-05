class User < ActiveRecord::Base
  include Ddr::Batch::BatchUser
  include Blacklight::User
  include Ddr::Auth::User

end
