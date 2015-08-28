Rails.application.routes.draw do

  mount Ddr::Batch::Engine => "/batch"
end
