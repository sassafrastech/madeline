class MS.Views.CalendarStepModalView extends Backbone.View

  el: '#calendar-step-modal'

  initialize: (params) ->
    # params.id ? @showStep : @showNewStep
    @id = params.id
    @context = params.context

  events:
    'click a.action-delete': 'deleteStep'

  showStep: ->
    $.get '/admin/project_steps/' + @id, context: @context, (html) =>
      @replaceContent(html)

  showNewStep: ->
    $.get '/admin/project_steps/new', context: @context, (html) =>
      @replaceContent(html)

  replaceContent: (html) ->
    @$el.find('.modal-content').html(html)
    @$el.modal({show: true})
    MS.loadingIndicator.hide()

  deleteStep: ->
    @$el.modal('hide')
