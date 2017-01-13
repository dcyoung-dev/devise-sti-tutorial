Rails.application.routes.draw do
  
  namespace :dashboard do
    namespace :teacher do
      get 'subjects/index'
    end
  end

  namespace :dashboard do
    namespace :teacher do
      get 'subjects/show'
    end
  end

  namespace :dashboard do
    namespace :teacher do
      get 'subjects/new'
    end
  end

  devise_for :students
  devise_for :teachers
	

  namespace :dashboard do
  	authenticated :student do
      resources :subjects, module: "student", :only => [:show, :index]
  	end

  	authenticated :teacher do
      resources :subjects, module: "teacher"
  	end

    root to: "dashboard#index"
  end

  get 'pages/index'

  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root to: "pages#index"
end
