 if (window.jQuery) {
  function isEmpty(el) {
    return !$.trim(el.html());
  }

  function expandables() {
    var $mainmenu = $('#main-menu');
    var oneliner = true;
    var left = 0;
    $mainmenu.children('ul').children().each(function() {
      var position = $(this).position();
      if (position.left < left) {
        oneliner = false;
        return false;
      } else {
        left = position.left;
      }
    });
    if (oneliner) {
      $mainmenu.find('.opener').hide();
    } else {
      $mainmenu.find('.opener').show();
    }
    $sidebar = $('#sidebar');
    if ($sidebar.css('position') == 'absolute') {
      $sidebar.css('left', '100%');
    } else {
      $sidebar.css('left', 0);
    }
  }
  $(window).load(function(){
    var viewportmeta = document.querySelector('meta[name="viewport"]');
    if (viewportmeta) {
      viewportmeta.content = 'width=device-width, minimum-scale=1.0, maximum-scale=1.0, initial-scale=1.0';
    } else {
      $('head').append('<meta name="viewport" content="initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0">');
    }
    $footer = $('#footer').find('.bgr');
    $footer.html($footer.html()+' - This theme uses <a href="http://getbootstrap.com" target="_blank">Bootstrap</a> and <a href="http://glyphicons.com/" target="_blank">Glyphicons</a>');
    $('#top-menu').before('<button type="button" class="btn navbar-toggle"><span class="sr-only">Toggle navigation</span><span class="icon-bar"></span><span class="icon-bar"></span><span class="icon-bar"></span></button>');
    $(document).on('click', '.navbar-toggle', function() {
      var $menu = $('#top-menu');
      $menu.toggleClass('in');
    });
    var $mainmenu = $('#main-menu');
    if (isEmpty($mainmenu)) {
      $mainmenu.css('visibility','hidden');
    } else {
      var $html = $mainmenu.html();
      $mainmenu.html('<i class="glyphicon glyphicon-plus-sign opener"></i>'+$html);
      $(document).on('click', '#main-menu > .opener', function() {
        $(this).toggleClass('glyphicon-plus-sign  glyphicon-minus-sign');
        $('#main-menu').toggleClass('in');
      });
    }
    var $sidebar = $('#sidebar');
    if (isEmpty($sidebar)) {
      $('#content').addClass('full');
      $sidebar.hide();
    } else {
      var $html = $sidebar.html();
      $sidebar.html('<i class="menu-trigger glyphicon glyphicon-circle-arrow-left"></i>' + $html);
      $(document).on('click', '.menu-trigger', function() {
        $(this).toggleClass('glyphicon-circle-arrow-left').toggleClass('glyphicon-circle-arrow-right');
        if ($sidebar.hasClass('slided')) {
          $sidebar.removeClass('slided');
          $sidebar.animate({
            left: "+="+$sidebar.width()
          }, 1000 );
        } else {
          $sidebar.addClass('slided');
          $sidebar.animate({
            left: "-="+$sidebar.width()
          }, 1000 );
        }
      });
    }
    expandables();
    if ($('#main-menu').length == 0) {
      $('#header').css('margin-bottom', '75px');
    }
    $('img').each(function() {
      var src = $(this).attr('src');
      if (src.length > 15 && src.substring(0,15) == '/images/add.png') {
        $(this).replaceWith('<i class="glyphicon glyphicon-plus-sign icon-success"></i>');
      } else if (src.length > 16 && src.substring(0,16) == '/images/edit.png') {
        $(this).replaceWith('<i class="glyphicon glyphicon-pencil icon-info"></i>');
      } else if (src.length > 20 && src.substring(0,20) == '/images/calendar.png') {
        $(this).replaceWith('<i class="glyphicon glyphicon-calendar icon-neutral"></i>');
      }
    });

    if (window.devicePixelRatio > 1) {
      var images = findImagesByRegexp('contacts_thumbnail', document);

      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        old_size = lowres.match(/\/(\d*)$/)[1]
        var highres = lowres.replace(/\/(\d*)$/, "/" + String(old_size*2));
        images[i].src = highres;
      }

      var images = findImagesByRegexp(/gravatar.com\/avatar.*size=\d+/, document)

      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        old_size = lowres.match(/size=(\d+)/)[1]
        var highres = lowres.replace(/size=(\d+)/, "size=" + String(old_size*2));
        images[i].src = highres;
        images[i].height = old_size;
        images[i].width = old_size;
      }  

      var images = findImagesByRegexp(/\/attachments\/thumbnail\/\d+$/, document)

      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        var height = images[i].height
        var width = images[i].width
        var highres = lowres + "?size=" + Math.max(height, width)*2;
        if (Math.max(height, width) > 0) {
          images[i].src = highres;
          images[i].height = height;
          images[i].width = width;
        }
      }  

// Sized thumbnails
      var images = findImagesByRegexp(/\/attachments\/thumbnail\/\d+\/\d+$/, document)  
      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        var height = images[i].height
        var width = images[i].width
        old_size = lowres.match(/\/(\d*)$/)[1]
        var highres = lowres.replace(/\/(\d*)$/, "/" + String(old_size*2));
        images[i].src = highres;
        if (Math.max(height, width) > 0) {
          images[i].src = highres;
          images[i].height = height;
          images[i].width = width;
        }        
      }             

// People avatars
      var images = findImagesByRegexp(/people\/avatar.*size=\d+$/, document)

      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        old_size = lowres.match(/size=(\d+)$/)[1]
        var highres = lowres.replace(/size=(\d+)$/, "size=" + String(old_size*2));
        images[i].src = highres;
      }    


    }

  });
  $(window).resize(expandables);
} else {
  document.observe("dom:loaded", function() {
    if (window.devicePixelRatio > 1) {
      var images = findImagesByRegexp('thumbnail', document);

      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        old_size = lowres.match(/size=(\d*)$/)[1]
        var highres = lowres.replace(/size=(\d*)$/, "size=" + String(old_size*2));
        images[i].src = highres;
      }

      var images = findImagesByRegexp(/gravatar.com\/avatar.*size=\d+/, document)

      for(var i = 0; i < images.length; i++) {
        var lowres = images[i].src;
        old_size = lowres.match(/size=(\d+)/)[1]
        var highres = lowres.replace(/size=(\d+)/, "size=" + String(old_size*2));
        images[i].src = highres;
        images[i].height = old_size;
        images[i].width = old_size;      
      }    
    }

  });
}

function findImagesByRegexp(regexp, parentNode) {
   var images = Array.prototype.slice.call((parentNode || document).getElementsByTagName('img'));
   var length = images.length;
   var ret = [];
   for(var i = 0; i < length; ++i) {
      if(images[i].src.search(regexp) != -1) {
         ret.push(images[i]);
      }
   }
   return ret;
};
