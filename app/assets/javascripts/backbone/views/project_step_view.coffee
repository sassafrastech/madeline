# Handles showing, hiding, formatting, and submitting of project step form
class MS.Views.ProjectStepView extends Backbone.View

  TYPE_ICONS:
    'checkin': 'calendar-check-o'
    'milestone': 'flag'

  initialize: (params) ->
    @initTypeSelect()
    @persisted = params.persisted
    @duplicate = params.duplicate
    @context = @$el.data('context')
    new MS.Views.ProjectStepTranslationsView({
      el: @$('.languages'),
      permittedLocales: params.permittedLocales
    })

  events:
    'click a.edit-step-action': 'showForm'
    'click a.duplicate-step-action': 'showDuplicateModal'
    'click a.cancel': 'cancel'
    'submit form': 'onSubmit'
    'ajax:success': 'ajaxSuccess'

  showForm: (e) ->
    e.preventDefault()
    @$('.view-step-block').hide()
    @$('.form-step-block').show()

  cancel: (e) ->
    if @context == 'timeline'
      e.preventDefault()
      if @persisted
        @$('.view-step-block').show()
        @$('.form-step-block').hide()
      else
        MS.timelineView.removeStep(@$el)

  showDuplicateModal: (e) ->
    e.preventDefault()
    @$('.duplicate-step').modal('show')

  # Select 2 is used to show the pretty icons.
  initTypeSelect: ->
    @$('.type').select2({
      theme: "bootstrap",
      minimumResultsForSearch: Infinity,
      width: "100%",
      templateResult: (option) => @formatTypeOptions(option),
      templateSelection: (option) => @formatTypeOptions(option)
    });

  formatTypeOptions: (option) ->
    if icon = @TYPE_ICONS[option.id]
      $("<i class=\"fa fa-#{icon}\"></i> <span>#{option.text}</span>")
    else
      $("<span>#{option.text}</span>")

  onSubmit: ->
    MS.loadingIndicator.show()

  ajaxSuccess: (e, data) ->
    if $(e.target).is('form')
      @$el.replaceWith(data)
      MS.loadingIndicator.hide()

      if @context == 'timeline'
        MS.timelineView.addBlankStep() unless @persisted || @duplicate
    else if $(e.target).is('a.action-delete')
      @$el.remove()
    MS.calendarView.refresh()
