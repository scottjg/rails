window.addEvent('domready', function($) {

  var handleRemote = function(e) {
    e.preventDefault();
    new Request.Rails(this).send();
  };

  var hooks = {
    'form[data-remote="true"]:submit': handleRemote,
    'a[data-remote="true"]:click': handleRemote
  };

  for(var key in hooks) {
    var split = key.split(':');
    $$(split[0]).addEvent(split[1], hooks[key]);
  }
}.pass(document.id));


Request.Rails = new Class({

  Extends: Request,

  options: {
    update: null,
    position: null
  },

  initialize: function(element) {
    this.el = element;
    if(!this.conditionMet()) return;

    this.parent({
      method: this.el.get('method') || this.el.get('data-method') || 'get',
      url: this.el.get('action') || this.el.get('data-url') || '#',
      async: this.el.get('data-remote-type') !== 'synchronous',
      update: $(this.el.get('data-update-success')),
      position: this.el.get('data-update-position')
    });
    this.headers['Accept'] = '*/*';

    this.setData();
    this.addRailsEvents();
  },

  send: function(options) {
    this.el.fireEvent('rails:before');
    this.parent(options);
  },

  addRailsEvents: function() {
    this.addEvent('request', function() {
      this.el.fireEvent('rails:after', this.xhr);
      this.el.fireEvent('rails:loading', this.xhr);
    });

    this.addEvent('success', function(responseText) {
      this.el.fireEvent('rails:success', this.xhr);

      if(this.options.update) {
        if(this.options.position) {
          new Element('div', {
            html: responseText
          }).inject(this.options.update, this.options.position);
        } else {
          this.options.update.set('html', responseText);
        }
      }
    });

    this.addEvent('complete', function() {
      this.el.fireEvent('rails:complete', this.xhr);
      this.el.fireEvent('rails:loaded', this.xhr);
    });

    this.addEvent('failure', function() {
      this.el.fireEvent('rails:failure', this.xhr);
    });
  },

  setData: function() {
    if (this.el.get('data-submit')) {
      this.options.data = $(this.el.get('data-submit'));
    } else if (this.el.get('data-with')) {
      this.options.data = this.el.get('data-with');
    } else if(this.el.get('tag') == 'form') {
      this.options.data = this.el;
    } else if(this.el.get('tag') == 'input') {
      this.options.data = this.el.getParent('form');
    }
  },

  conditionMet: function() {
    var condition = this.el.get('data-condition');
    if(condition) return eval(condition);
    return true;
  }

});

/**
 * MooTools selector engine does not match data-* attributes.
 * This will be fixed in 1.3, when the engine is swapped for Slick.
 */
Selectors.RegExps.combined = (/\.([\w-]+)|\[([\w-]+)(?:([!*^$~|]?=)(["']?)([^\4]*?)\4)?\]|:([\w-]+)(?:\(["']?(.*?)?["']?\)|$)/g);
