// Only include this file if jquery is loaded
if (jQuery) {
  
  Route.Object = function (url) {
    this.url = url;
  };

  Route.Object.prototype = {
    toString: function() {
      return this.url;
    }
  };

  //Replace Route.prototype.generate
  (function(oldGenerate){
    Route.prototype.generate = function(){
      var path = oldGenerate.apply(this, arguments);
      return path && new Route.Object(path);
    };
  })(Route.prototype.generate);

  // Replicate jquery functions
  jQuery.extend(Route.Object.prototype, {
    ajax: function(options) {
      jQuery.extend(options,{url: this.url});
      return jQuery.ajax(options);
    },
    get: function( data, callback, type ) {
      return jQuery.get(this.url, data, callback, type);
    },
    post: function( data, callback, type ) {
      return jQuery.post( this.url, data, callback, type );
    },
    // This code modeled after jquery source
    put: function( data, callback, type ) {
      // shift arguments if data argument was ommited
      if ( jQuery.isFunction( data ) ) {
        callback = data;
        data = null;
      }
      return jQuery.ajax({
        type: "PUT",
        url: url,
        data: data,
        success: callback,
        dataType: type
      });
    },
    // This code modeled after jquery source
    // Delete is a keyword in JS therefore use do_delete
    do_delete: function( data, callback, type ) {
      // shift arguments if data argument was ommited
      if ( jQuery.isFunction( data ) ) {
        callback = data;
        data = null;
      }
      return jQuery.ajax({
        type: "DELETE",
        url: url,
        data: data,
        success: callback,
        dataType: type
      });
    },
    getScript: function( callback ) {
      return jQuery.get(this.url, callback);
    },
    getJSON: function( data, callback ) {
      return jQuery.getJSON(this.url, data, callback);
    }
  });
}
