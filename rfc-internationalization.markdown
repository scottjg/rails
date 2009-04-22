RFC: Enterprise-ready internationalization (i18n) for Rails
===========================================================

We have been working on a Rails application for a big company, that will be
rolled out in many countries. We have carefully followed Rails development over
the last 8 months and tried out different tool sets for internationalization:
Rails 2.1 together with the gettext 1.93 gem, ActiveSupport.I18n as part of
Rails 2.3 with and without fast_gettext.

All our approaches still required extensive monkey patching resulting in high,
unexpected efforts. The solutions work in 95% of all cases, which is probably
sufficient for most Rails applications, but in our case it is not.

We think it is possible to implement a reliable 100% correct localization with
reasonable effort, but some important principles have to be considered in the
Rails core though.


Internationalization principles
-------------------------------

### Separation of roles

Often software developers are not able to or are not allowed to create
translations of their applications' texts for several reasons:

* There are only a few developers who perfectly speak several languages.
* For commercial-grade applications the exact wording usually is controlled by
  the marketing department.
* In open source projects it should be possible for enthusiastic non-technical
  users to contribute improvements or complete translations. Consequentially,
  some open source projects have defined even [more roles][gnome-roles].

Important note: non-developers need [tools][poedit] for editing language files!


### Streamlining the development and translation process

Identifying messages by a symbol in a YAML file (like in Rails 2.3) is
problematic, because it breaks the developer's flow: you have to stop coding,
come up with a good identifier (symbol) name for your message, go to a YAML
file, and type in the message.

Later on the translator does not know a message's context and needs to open
two YAML files side by side - one contains the context and the other one gets
filled with the translations. In contrast to that, the [gettext
approach][gettext-approach] works smoothly - for C and for Python; for open
source and for commercial projects.

    _('Archive is invalid')
    _('%{attribute} must not be empty') % attr

are both easier to write and easier to translate.

With command line tools such as [msgfmt -cv][msgfmt] you can also check the
well-formnedess and completeness of your transaltions as part of the
**continuous build process**.

A reliable, high-quality, feature rich parsing tool for Ruby and for Rails
still needs to be implemented, but [ruby-gettext][] is a good starting point.


### Linguistically correct translations

ActiveRecord validations support the concept of error messages and full error
messages. From a linguistical point of view this does not work: there is no
way to infer a correct full message from its short message counterpart and
vice versa. The string concatenation approach used by Rails (almost) works for
English but rarely for other languages. 

If you can not infer one message from another, the distinction does not make
sense. You only need one kind of message, preferably with a placeholder for
the attribute name. (see the example above.)

The current implementation is both overengineered and not sufficient:

    # lib/active_record/validations.rb:196
    full_messages << attr_name + I18n.t('activerecord.errors.format.separator',
      :default => ' ') + message

The main problem with this solution is: if a language needs a different
separator for different parts of the sentence, then it will probably also
differ in more vital aspects. For example, it might insist on a different
order of words in a sentence.

A message can only be translated as a whole. Hence, it should be possible to
provide custom ActiveRecord validation messages at any time. For us it was
only possible with [a dirty hack][custom-validation-messages].

Usage of string concatenation for building error messages in the framework
makes it [extremely complicated][remove-prefix] to avoid the corruption of
error messages with a prefix derived from attribute/relation names.

**String concatenation should never be used to create human-readable messages.
Use string interpolation instead (as it has been used in other frameworks and
platforms for decades).**

In addition, ActiveRecord should allow for proc-based validation messages:

    validates_format_of account, :message => proc {...}

Of course, a robust pluralization implementation, as provided by gettext, is
important, too.


### Locale selection

All the different localization libraries try to select an appropriate locale
corresponding to their own rules and in a transparent way. The corresponding
logic is often buried deep in the library's implementation and cannot be fixed
using monkey patching.

Even if our application only offers English and Italian, for example, the
gettext library with its ActiveRecord extensions sometimes shows validation
messages in Greek (depending on the user's browser settings). Of course,
libraries and Rails should be able to provide translations in a plenty of
languages, but the application should have the last word in the decision,
which subset of possible languages is offered to the user.

A callback in the application controller which can be overridden by an
application developer would be an advantage. A before_filter would also do,
but it has to be executed before all other before_filters.

    # initializer/internationalization.rb
    offer_locales :en_UK, :en_ZA, :nl
    default_text_domain 'myapp'

    # application_controller.rb
    class ApplicationController
      def compute_effective_locale
        # application specific implementation, that uses
        #
        # params[:lang]
        # cookies[:lang]
        # request.headers['Accept-language']
        # default_locale
        #
        # to compute the effective locale
      end
    end

A default implementation with priority order [query parameter, cookie, browser
setting] can be provided, but almost any non-trivial application needs its own
rules.


### Syntax

If the handling of text messages needs to be refactored anyway, it would be
advantageous to switch to the less invasive, proven, and familiar gettext
syntax:

    _("The billing system is not available. Please, try again later.")

instead of 

    I18n.t(:billing_not_available)

Providing context for translation:

   "Gadget|Title" => (German) "Bezeichnung"

The word "Title" is translated differently depending on its context.
Hierarchical contexts are not needed, that is YAML files with deeper nesting
as in Rails 2.3 do not make sense.


### Implementation backends

The current interface for plugging in different localization storage backends
is a nice intention, but in this case flexibility is not needed. A perfectly
designed and working backend would be sufficient. Other - less successful -
frameworks and platforms such as django, pylons, and Microsoft.NET have much
more powerful internationalization/localization features and they all support
only one backend. Localization in Python frameworks is based on gettext, .NET
uses resource files. Both technologies are mature and they are supported by a
large set of tools for maintaining translations. The obvious choice for Rails
would be gettext, then.


Conclusion
----------

**It is not possible to implement a sustainable internationalization solution as
a gem, as a plugin, or as a collection of monkey patches. Important principles
must be considered in the Rails core, especially in ActiveRecord/ActiveModel,
to make applications fully internationalizable. This would be an important 
step to make Rails enterprise-ready.**

We offer an industrial-strength internationalization implementation for Rails3
and all the needed refactoring of validation code. But we wanted to check
upfront, if the community is interested in such an implementation and if
there's a chance that these changes would be integrated into the Rails trunk.

Vladimir Dobriakov (vladimir.dobriakov@innoq.com)
<http://blog.geekq.net>

Maik Schmidt (maik.schmidt@vodafone.com)
<http://maik-schmidt.de>
 

[gnome-roles]: http://live.gnome.org/TranslationProject/LocalisationGuide#head-99ad8844377d7c12dcff787e4701d6109bdce69b 
[poedit]: http://www.poedit.net/
[gettext-approach]: http://www.gnu.org/software/gettext/manual/gettext.html#Mark-Keywords
[msgfmt]: http://www.gnu.org/software/gettext/manual/gettext.html#msgfmt-Invocation
[remove-prefix]: http://blog.geekq.net/2009/04/09/i18n-remove-validation-message-prefix/
[custom-validation-messages]: http://blog.geekq.net/2009/04/08/activerecord-i18n-validation-message/
[ruby-gettext]: http://rubyforge.org/projects/gettext/

