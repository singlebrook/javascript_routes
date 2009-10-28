JavascriptRoutes
================
Rails routes get generated in JavaScript...


How it works
============
JavascriptRoutes::generate iterates over all your routes, using Rails inbuilt reflection,
then generates equivalent URI generators in JavaScript.

It can either do just named routes or both named and dynamic ones (from controller/action).
This is controlled by setting :lite to true or false.

The idea is you hook a call to JavascriptRoutes::generate() within your bootstrap code, 
and that dumps out a fresh public/javascripts/routes.js for you.

Setup
=====
# Add this to bootup (say in bottom of environment.rb or a config/initializer):
#
# Generate routes now...
JavascriptRoutes.generate(:lite => true)


# Add this to your application/template, and go ahead and access 'Routes' javascript object
<%= javascript_include_tag :routes %>

Example:

config/routes.rb
  map.resources :bookings

  # Namespaced works... 
  map.namespace(:ship) do |ship|
    ship.resources :reservations
  end


In your js (after including routes.js)

  // Urls for a new booking
  Routes.new_bookings_path();

  // Url to edit booking with id 23
  Routes.edit_booking_path(23);
  
  // Namespaced under 'ship' 
  // Editing url for reservation 1 
  Routes.edit_ship_reservation_path(1);

CREDITS
=======
Forked from 'toretore' / javascript_routes on github.

