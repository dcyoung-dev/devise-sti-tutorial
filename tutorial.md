# Tutorial

## What
In this tutorial we are going to walk through building a Rails application using Devise for authentication. We will create a `User` model and an area that can only be accessed by a `User`.
We're then going to explore the use of Single Table Inheritance (STI) with Devise, to create a `Student` and a `Teacher` model, both of which will have customised information on the dashboard as well as different views when signing up or editing their accounts.

## Setup
First of all we'll start by creating a new Rails app with no test unit. In the terminal run

```sh
# terminal
$ rails new devise-sti-stripe-connect -T
```
We will not change any of the defaults here, as a result this app will be very simple.

### Add Devise
Once we have our Rails app installed we'll edit the Gemfile to add devise.

```ruby
# Gemfile
gem 'devise'
```

To install devise run

```sh
# terminal
$ bundle install
$ rails generate devise:install
```

The devise installation will recommend a few setting to change. Follow the instructions from the terminal e.g.
Much as the instructions, add the following configuration in your development environment

```ruby
# config/environment/development.rb
config.action_mailer.default_url_options = { host: 'localhost', port: 3000 }
```

and add the alert areas in your application layout.

```html
# app/views/layouts/application.html.erb
<p class="notice"><%= notice %></p>
<p class="alert"><%= alert %></p>
```

Finally, run to generate all the views that devise requires.

```sh
# terminal
$ rails g devise:views
```

### Static Pages
To add a little extra to our application we can generate a simple static page controller with an index method and view that we will access with no authentication.

```sh
# terminal
$ rails g controller Pages index
```

We will also set the root of the site to show the static `pages/index`

```ruby
# config/routes.rb
root to: "pages#index"
```

### Dashboard
We can now create our dashboard that will only be available to our users.

```sh
# terminal
$ rails g controller Dashboard/Dashboard index
```

In addition to the controller and views that have generated, we can add `root to: "dashboard#index"` within the dashboard namespace.

```ruby
# config/routes.rb
namespace :dashboard do
	root to: "dashboard#index"
end
```

As a result of getting our dashboard views and routes set up, we're ready to add our first devise model.

### Devise Models
Start with User (base user model) model. This will be the model that all other user types will inherit from and the only model that will have a database table. As well as the default devise properties we also want to add a `name` property for every user.

```sh
# terminal
$ rails generate devise User name
```

In our application layout we'll add a link for our users to log out - we probably only want to show this when a user is logged in, so we'll add the following to the start of the `<body>` tag.

```html
# app/views/layouts/application.html.erb
<nav>
	Navigation
	<%= link_to Dashboard, dashboard_root_path %>
	<% if user_signed_in? %>
		<%= link_to 'Log out', destroy_user_session_path, method: :delete %>
	<% end %>
</nav>
```

Now we have to go and secure our dashboard by adding authentication to our controller.

```ruby
# app/controllers/dashboard/dashboard_controller.rb
before_action :authenticate_user!
```

Before we run our rails server we'll have to run a `db:migrate` so that our User table is ready for our new models.

```sh
# terminal
$ rails db:migrate
```

Now we can start up our server and view our application.

```sh
# terminal
$ rails server
```

By visit `localhost:3000/dashboard` in our browser you will be redirected to the sign in screen. We have no users yet so you can click the sign up link and register a new user.
As a result we now have an account that can view the dashboard. Now before going any further we must make sure that we have logged out of our application.

## Single Table Inheritance with Devise
Seems like we now have a basic functioning application where users can sign up and sign in, and only registered users can view a dashboard page.
What if we needed to have different kinds of users that had the same/similar attributes but possibly viewed different items or had different actions that could be taken?
Well we could set up two separate devise models but that seems overkill. Instead we will add two new models which will both inherit from the existing User model, this is called Single Table Inheritance. This way we can write all the shared operations of a user in one place and add custom methods to the seperate models where needed.

### Creating New Models
We'll start off by making sure that we have logged out of our application and then we will destroy all Users from the Rails console.

```sh
# terminal
$ rails console
> User.destroy_all
> exit
```

Next we'll create the Teacher and Student models. In this case we'll use the `rails generate` command to make models, however you can add these manually if you prefer.

Since our new models do not require any additional columns we can run.

```sh
# terminal
$ rails g model Student #Make sure to delete the generated migration
$ rails g model Teacher #Make sure to delete the generated migration
```

The only change we have to make to our database is to add a `type` column to our `users` table, therefore we'll generate and run a migration for this.

```sh
# terminal
$ rails g migration AddTypeToUsers type:string
$ rails db:migrate
```

### Modifying Models, Views, Controllers and Routes
We now have to modify a our newly created models, our routes for devise, our application layout and our application controller.
Let's start by changing our models. These have to be changed because they currently inherit from `ApplicationRecord` but as these will be users we need to inherit from - you guessed it - `User`.

```diff
# app/models/student.rb
- class Student < ApplicationRecord
+ class Student < User

# app/models/teacher.rb
- class Teacher < ApplicationRecord
+ class Teacher < User
```

In our routes we're going to remove our devise users and add in our new Student and Teacher users.

```diff
# config/routes.rb

- devise_for :users

+ devise_for :students
+ devise_for :teachers
```

Our `<nav>` section within the applications layout will have to be changed since the `destroy_user_session_path` is no longer available to us. I'm not sure if there is a better way of doing this but this approach will be ok as we only have two different user types.

```html
# app/views/layouts/application.html.erb
<nav>
	Navigation
	<% if student_signed_in? %>
		<%= link_to 'Log out', destroy_student_session_path, method: :delete %>
	<% end %>
	<% if teacher_signed_in? %>
		<%= link_to 'Log out', destroy_teacher_session_path, method: :delete %>
	<% end %>
</nav>
```

To allow us to keep using `current_user` and `user_signed_in?` we have to add a `devise_group` to our application controller.

```ruby
# app/controllers/application_controller.rb
devise_group :user, contains: [:student, :teacher]
```

The order of the `contains:` array is important. Devise will use the first model, in the array, when redirecting you to a sign in form when you call `authenticate_user!`. For example if we run `$ rails server` and visit `/dashboard` we will be redirected to `/students/sign_in`. If we swap `[:student, :teacher]` to `[:teacher, :student]` and visit `/dashboard` we'll now be redirected to `/teachers/sign_in`

To test out what we have now visit `/students/sign_up` and sign up using a dummy email address like `student@example.com`. Once signed up and logged in, log back out.
Now if you visit `/teachers/sign_in` and try to use the email and password that you used to sign up as a `Student` you'll find that they won't work. Visit `/teacher/sign_up` and register using `teacher@example.com`

### Different Dashboard Displays
Now that we have two accounts, one `Student` and one `Teacher`. Either of these accounts can be logged in to view the `/dashboard`.

To change what a user can see on their dashboard depending on what model they belong to we can use the following:

```html
# app/views/dashboard/index.html.erb
<% if student_signed_in? %>
	<p>I'm a Student</p>
<% end %>

<% if teacher_signed_in? %>
	<p>I'm a Teacher</p>
<% end %>
```

Now we have custom content for each user type. We can also lock down routes using an `authenticated :student do` block. Within this block we could write something like

```ruby
# config/routes.rb
namespace :dashboard do
	authenticated :student do
		resources :subjects, module: "student", :only => [:show, :index]
	end

	authenticated :teacher do
		resources :subjects, module: "teacher"
	end

	root to: "dashboard#index"
end
```

The easiest way to explain what happens in this set up is to run

```sh
# terminal
$ rails routes | grep dashboard
```

You should see something like this

```sh
# terminal
dashboard_subjects GET    /dashboard/subjects(.:format)          dashboard/student/subjects#index
dashboard_subject GET    /dashboard/subjects/:id(.:format)      dashboard/student/subjects#show
                  GET    /dashboard/subjects(.:format)          dashboard/teacher/subjects#index
                  POST   /dashboard/subjects(.:format)          dashboard/teacher/subjects#create
new_dashboard_subject GET    /dashboard/subjects/new(.:format)      dashboard/teacher/subjects#new
edit_dashboard_subject GET    /dashboard/subjects/:id/edit(.:format) dashboard/teacher/subjects#edit
                  GET    /dashboard/subjects/:id(.:format)      dashboard/teacher/subjects#show
                  PATCH  /dashboard/subjects/:id(.:format)      dashboard/teacher/subjects#update
                  PUT    /dashboard/subjects/:id(.:format)      dashboard/teacher/subjects#update
                  DELETE /dashboard/subjects/:id(.:format)      dashboard/teacher/subjects#destroy
   dashboard_root GET    /dashboard(.:format)                   dashboard/dashboard#index
```

Two further controllers would be needed for this set up `Dashboard::Student::Subjects` containing `before_action :authenticate_student!` and `Dashboard::Student::Subjects` containing `before_action :authenticate_teacher!`.

## Custom Devise Views
Say, for whatever reason, you want to have different views for a Student or and Teacher when they sign up. This can be easily added to the Devise configuration.

```ruby
# config/initializers/devise.rb
config.scoped_views = true
```

This will allow devise to render views from `app/views/students/` or `app/views/teacher`. If the view is not available in the respective folder, devise will fallback to the `/app/views/devise`.
We'll copy over the `app/views/devise/registrations` folder and contents into `app/views/students/registrations`

```sh
# terminal
$ cp -a app/views/devise/registrations/. app/views/students/registrations
```

In both our new and edit registrations views we'll add the text field for the nae attribute.
```html
<!-- # app/views/students/registrations/new.html.erb -->
<!-- # and in app/views/students/registrations/edit.html.erb -->

<div class="field">
	<%= f.label :name %><br />
	<%= f.text_field :name, autofocus: true %>
</div>
```

Now students can add their name to their account when they sign up or edit their account.

For devise to accept the incoming `name` param we'll have to add permitted params to our application controller.

```ruby
# app/controllers/application_controller.rb

before_action :configure_permitted_parameters, if: :devise_controller?

private
	def configure_permitted_parameters
		added_attrs = [:email, :password, :password_confirmation, :remember_me, :name]
		devise_parameter_sanitizer.permit :sign_up, keys: added_attrs
		devise_parameter_sanitizer.permit :account_update, keys: added_attrs
	end
```

## Conclusion
In conclusion, the implementation of Single Table Inheritance with Devise is fairly straightforward in this scenario. This is not, by any means, a tried and tested method of implementing STI with Devise, but is more an introduction as to how it may be used.
You can access this application code on [GitHub](https://github.com/VSM-Dave/devise-sti-tutorial).