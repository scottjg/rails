/**
 * TODO: Observer
 *
 * TODO: Tests
 */

window.addEvent('domready', function() {

  var handleRemote = function(e) {
    e.preventDefault();
    new Request.Rails(this).send();
  };

  var hooks = {
    'form[data-remote="true"]:submit': handleRemote,
    'a[data-remote="true"], input[data-remote="true"], input[data-remote-submit="true"]:click': handleRemote,
    'a[data-popup], input[type="button"][data-popup]:click': function(e) {
      e.preventDefault();
      var url = this.get('data-url') || this.get('href'),
          options = this.get('data-popup');

      if(options === 'true') {
        window.open(url);
      } else {
        window.open(url, options);
      }
    },
    'script[data-periodical="true"]:domready': function() {
      var frequency = this.get('data-frequency') ? this.get('data-frequency').toFloat() : 10;

      var request = new Request.Rails(this);
      request.send.periodical(frequency * 1000, request);
    }
  };

  for(var key in hooks) {
    var split = key.split(':');
    $$(split[0]).addEvent(split[1], hooks[key]);
  }

  /**
   * Rails 2.x compatibility.
   */
  var compatEval = function(el, action) {
    var js = el.get('data-on' + action);
    if(js) eval(js);
  };

  $$('form[data-remote="true"], a[data-remote="true"], input[data-remote="true"], script[data-observe="true"]').each(function(el) {
    ['before', 'after', 'loading', 'loaded', 'complete', 'success', 'failure', 'observe'].each(function(action) {
      el.addEvent('rails:' + action, function() {
        compatEval(el, action);
      });
    });

    el.addEvent('rails:complete', function(xhr) {
      compatEval(el, xhr.status);
      if(el.get('data-periodical') === 'true') {
        compatEval(el, 'observe');
      }
    });
  });
});

(function($) {
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
      if(!this.checkConfirm()) return;
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

      this.setDisableWith();
    },

    checkConfirm: function() {
      var confirmMessage = this.el.get('data-confirm');
      if(confirmMessage && !confirm(confirmMessage)) return false;
      return true;
    },

    setDisableWith: function() {
      var button = this.el.get('data-disable-with') ? this.el : this.el.getElement('[data-disable-with]');
      if(!button) return;

      var disableWith = button.get('data-disable-with');
      if(disableWith) {
        var enableWith = button.get('value');

        this.el.addEvent('rails:before', function() {
          button.set({
            value: disableWith,
            disabled: true
          });
        }).addEvent('rails:complete', function() {
          button.set({
            value: enableWith,
            disabled: false
          });
        });
      }
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

})(document.id);

/**
 * MooTools selector engine does not match data-* attributes.
 * This will be fixed in 1.3, when the engine is swapped for Slick.
 */
Selectors.RegExps.combined = (/\.([\w-]+)|\[([\w-]+)(?:([!*^$~|]?=)(["']?)([^\4]*?)\4)?\]|:([\w-]+)(?:\(["']?(.*?)?["']?\)|$)/g);
