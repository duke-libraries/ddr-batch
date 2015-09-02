Rails.application.routes.draw do

  mount Ddr::Batch::Engine, at: "/batch"
end
