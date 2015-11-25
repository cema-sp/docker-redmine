// Copyright (c) 2011-2013 Kirill Bezrukov

var noteFileFieldCount = 1;

function addNoteFileField() {
	if (noteFileFieldCount >= 10) return false
	noteFileFieldCount++;
	var f = document.createElement("input");
	f.type = "file";
	f.name = "note_attachments[" + noteFileFieldCount + "][file]";
	f.size = 30;
	var d = document.createElement("input");
	d.type = "text";
	d.name = "note_attachments[" + noteFileFieldCount + "][description]";
	d.size = 60;

	p = document.getElementById("note_attachments_fields");
	p.appendChild(document.createElement("br"));
	p.appendChild(f);
	p.appendChild(d);
}

function updateCustomForm(url, form) {
  $.ajax({
    url: url,
    type: 'post',
    data: $(form).serialize()
  });
}

function toggleContact(event, element)
{
	if (event.shiftKey==1)
	{
		if (element.checked) {
			checkAllContacts($$('.contacts.index td.checkbox input'));
		}
		else
		{
			uncheckAllContacts($$('.contacts.index td.checkbox input'));
		}
	}
	else
	{
		Element.up(element, 'tr').toggleClassName('context-menu-selection');
	}
}


// Observ field function

(function( $ ){

  jQuery.fn.observe_field = function(frequency, callback) {

    frequency = frequency * 100; // translate to milliseconds

    return this.each(function(){
      var $this = $(this);
      var prev = $this.val();

      var check = function() {
        if(removed()){ // if removed clear the interval and don't fire the callback
          if(ti) clearInterval(ti);
          return;
        }

        var val = $this.val();
        if(prev != val){
          prev = val;
          $this.map(callback); // invokes the callback on $this
        }
      };

      var removed = function() {
        return $this.closest('html').length == 0
      };

      var reset = function() {
        if(ti){
          clearInterval(ti);
          ti = setInterval(check, frequency);
        }
      };

      check();
      var ti = setInterval(check, frequency); // invoke check periodically

      // reset counter after user interaction
      $this.bind('keyup click mousemove', reset); //mousemove is for selects
    });

  };

  $.fn.insertAtCaret = function (myValue) {

    return this.each(function() {

      //IE support
      if (document.selection) {

        this.focus();
        sel = document.selection.createRange();
        sel.text = myValue;
        this.focus();

      } else if (this.selectionStart || this.selectionStart == '0') {

        //MOZILLA / NETSCAPE support
        var startPos = this.selectionStart;
        var endPos = this.selectionEnd;
        var scrollTop = this.scrollTop;
        this.value = this.value.substring(0, startPos)+ myValue+ this.value.substring(endPos,this.value.length);
        this.focus();
        this.selectionStart = startPos + myValue.length;
        this.selectionEnd = startPos + myValue.length;
        this.scrollTop = scrollTop;

      } else {

        this.value += myValue;
        this.focus();
      }
    });
  };


})( jQuery );

function setupDeferredTabs(url) {
    $('body').on('click', '.tab-header', function(e){
        tab = $(e.target);
        $('.tab-placeholder').removeClass('active');
        name = tab.data('name');
        partial = tab.data('partial');
        placeholder = $('#tab-placeholder-' + name);
        placeholder.addClass('active');

        if (!placeholder.is('.loaded')) {
            url = url
            $.ajax(url, {
                data: {tab_name: name, partial: partial},
                complete: function(){
                    placeholder.addClass('loaded')
                    //replaces current URL with the "href" attribute of the current link
                    //(only triggered if supported by browser)
                    if ("replaceState" in window.history) {
                      window.history.replaceState(null, document.title, tab.attr('href'));
                    }
                    return undefined;
                },
                dataType: 'script'
            })
        }
        else {
            if ("replaceState" in window.history) {
                window.history.replaceState(null, document.title, tab.attr('href'));
            }
        }
    })
};
