window.addEvent('domready', function($) {

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
      this.addEvent('success', this.handleSuccess.bind(this))
    },

    handleSuccess: function(responseText) {
      if(this.options.update) {
        if(this.options.position) {
          new Element('div', { 
            html: responseText
          }).inject(this.options.update, this.options.position);
        } else {
          this.options.update.set('html', responseText);
        }
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
