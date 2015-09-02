Ddr::Batch::Engine.routes.draw do

  resources :batches, :only => [:index, :show, :destroy] do
    member do
      get 'procezz'
      get 'validate'
    end
    resources :batch_objects, :only => :index
  end

  resources :batch_objects, :only => :show do
    resources :batch_object_datastreams, :only => :index
    resources :batch_object_relationships, :only => :index
  end

end
