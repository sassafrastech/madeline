# This view is for general functions for the entire app, including admin and frontend
# Should be used sparingly. Prefer separate views (perhaps instantiated from in here)
# for cohesive pieces of functionality.
class MS.Views.ApplicationView extends Backbone.View

  el: 'body'

  initialize: ->
    new MS.Views.ErrorHandler()
    new MS.Views.Expander()
    MS.alert = (html) ->
      $alert = $(html).hide()
      $alert.appendTo($('.alerts')).show('fast')

  events: ->
    'click .more': 'toggleExpanded'
    'click .less': 'toggleExpanded'
    'click .ms-popover': 'showPopover'
    'mouseenter .ms-tooltip.ms-popover': 'showHoverPopover'

  toggleExpanded: (e) ->
    @$(e.currentTarget).closest(".expandable").toggleClass("expanded")

  showPopover: (e) ->
    @curPopover = $(e.currentTarget)
    @curPopover.popover('show')
    self = this
    hide = (e) ->
      unless self.$(e.target).is('.ms-popover')
        self.$('.ms-popover').popover('hide')
        self.$el.off 'click', hide # Unregister for performance reasons
    @$el.on 'click', hide

  showHoverPopover: (e) ->
    console.log("Hovering over popover")
    $curPopover = $(e.currentTarget)
    console.log($curPopover)
    $curPopover.popover('show')
    self = this
    hide = (e) ->
      console.log("Inside hide")
      unless self.$(e.target).is('.ms-popover')
        self.$('.ms-popover').popover('hide')
        self.$el.off 'click', hide # Unregister for performance reasons
    @$el.on 'click', hide
