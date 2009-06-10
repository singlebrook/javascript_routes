module JavascriptRoutes

  JS = File.join(File.dirname(__FILE__), 'javascripts', 'routes.js')
  JS_PACKED = File.join(File.dirname(__FILE__), 'javascripts', 'routes-min.js')
  JS_AJAX = File.join(File.dirname(__FILE__), 'javascripts', 'routes-ajax.js')

  FILENAME = File.join(RAILS_ROOT, 'public', 'javascripts', 'routes.js')
  FILENAME_AJAX = File.join(RAILS_ROOT, 'public', 'javascripts', 'routes-ajax.js')


  # Generate...
  #
  # Options are:
  #  :filename      => name of routes javascript file (default routes.js)
  #  :filename_ajax => name of routes ajax-extras (default routes-ajax.js)
  #
  #  :lite => only generate functions, not the unnamed generational routes (i.e. from controller/action)
  #  
  #  :pack => use the packed version
  #
  #  :routes       - which routes (leave out for all)
  #  :named_routes - which named routes (leave out for all)
  #
  #
  def self.generate(options = {})
    options.symbolize_keys!.reverse_merge!(:pack => true)

    routes       = options[:routes] || processable_routes
    named_routes = options[:named_routes] || processable_named_routes

    filename = options[:filename] || FILENAME
    filename_ajax = options[:filename_ajax] || FILENAME_AJAX
  
    # Create one function per route (simple lite version...)
    if options[:lite]
      generate_lite(named_routes, filename)    
      
    # Simulate Rails route generation logic -- not plain functions
    # (includes lib/routes.js)
    else
      generate_full(named_routes, routes, filename, options)
      
      # Add ajax extras
      File.open filename_ajax, 'w' do |f|
        f.write(File.read(JS_AJAX))
      end      
    end

  rescue => e  
    warn("\n\nCould not write routes.js: \"#{e.class}:#{e.message}\"\n\n")
    File.truncate(filename, 0) rescue nil
  end


  def generate_lite(named_routes, filename)
    route_functions = named_routes.map do |name, route|
      processable_segments = route.segments.select{|s| processable_segment(s)}

      # Generate the tokens that make up the single statement in this fn
      tokens = processable_segments.inject([]) {|tokens, segment|
        is_var = segment.respond_to?(:key)
        prev_is_var = tokens.last.is_a?(Symbol)

        value = (is_var ? segment.key : segment.to_s)

        # Is the previous token ammendable?
        require_new_token = (tokens.empty? || is_var || prev_is_var)
        (require_new_token ?  tokens : tokens.last) << value

        tokens
      }

      # Convert strings to have quotes, and concatenate...
      statement = tokens.map{|t| t.is_a?(Symbol) ? t : "\"#{t}\""}.join("+")

      fn_params = processable_segments.select{|s|s.respond_to?(:key)}.map(&:key)

      "#{name}_path: function(#{fn_params.join(', ')}) {return #{statement};}"
    end

    File.open(filename, 'w') do |file|
      file << "var Routes = (function(){\n"
      file << "  return {\n"
      file << "    " + route_functions.join(",\n    ") + "\n"
      file << "  }\n"
      file << "})();"
    end
  end


  # Generates all routes (named or unnamed) as an array of JSON objects
  #
  # The routes are encoded to reduce size:
  #  - each is an object with keys: 'n' for name, 's' for segments & 'r' for requirements
  #
  # Segments are further encode:
  #  - path segments indicated by first char being set to '*'
  #  - otherwise, the segment is just to_s
  #  - 't' or 'f' is appended to indicate is_optional
  def self.generate_full(named_routes, routes, filename, options)

    # Builds a JS array with a hash for each route
    routes_array = routes.map{|r|

      # Encode segments
      encoded_segments = r.segments.select{|s|processable_segment(s)}.map{|s|
        if s.is_a?(ActionController::Routing::PathSegment)
          '*' + s.to_s[1..-1]  + (s.is_optional ? 't' : 'f')
        else
          s.to_s  + (s.is_optional ? 't' : 'f')
        end
      }

      # Generate route as a hash
      route_hash = {
        's' => encoded_segments.join('@'), # 's' -- for segments
        'r' => r.requirements              # 'r' -- for requirements (params for a valid generation)
      }
      
      named_route = named_routes.find{|name,route| route.equal?(r) }
      if named_route
        route_hash['n'] = named_route.first # 'n' -- for name of named route
      end

      route_hash
    }

    File.open(filename, 'w') do |file|
      # Add core JS (external file)
      file << File.read(options[:pack] ? JS_PACKED : JS)

      js = <<-JS
        var url_root = #{ActionController::Base.relative_url_root.to_json};
        var routes_array = #{routes_array.to_json};
        for (var i = 0; i < routes_array.length; i++) {
          var route = routes_array[i]; var segments = [];
          var segment_strings = route.s.split('@');
          for (var j = 0; j < segment_strings.length; j++) {
            var segment_string = segment_strings[j];
            segments.push(Route.S(segment_string.slice(0, -1), segment_string.slice(-1) == 't'));
          }
          Routes.push(new Route(segments, route.r, route.n));
        }
        Routes.extractNamed();
      JS

      # Wrap in a function (called straight away) to not pollute namespace
      file << "\n(function(){\n#{js}\n})();"
    end
  end


  def self.processable_segment(segment)
    !segment.is_a?(ActionController::Routing::OptionalFormatSegment)
  end


  def self.processable_routes
    ActionController::Routing::Routes.routes.select{|r|
      r.conditions[:method].nil? || r.conditions[:method] == :get
    }
  end


  def self.processable_named_routes
    ActionController::Routing::Routes.named_routes.routes.select{|n,r|
      r.conditions[:method].nil? || r.conditions[:method] == :get
    }
  end
end
