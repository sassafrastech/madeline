class MS.Views.NoteView extends Backbone.View

  initialize: (params) ->
    new MS.Views.AutoLoadingIndicatorView()
    if @$el.find('.note').data('id') == 'new' then @editView() else @showView()

  events:
    'click a.edit-action': 'editView'
    'click .cancel': 'showView'
    'submit .note-form': 'update'

  editView: (e) ->
    e.preventDefault() if e
    @$('.view-block').hide()
    @$('.form-block').show()

  showView: (e) ->
    e.preventDefault() if e
    @$('.view-block').show()
    @$('.form-block').hide()
    # if @new_record
    #   @$('.form-block').remove()
    # else
    #   @$('.view-block').show()
    #   @$('.form-block').hide()

  update: (e) ->
    $form = @$(e.target).closest('form')
    # We send form data via ajax so we can capture the response from server
    $.post($form.attr('action'), $form.serialize())
      .done (response) =>
        @$('.view-block').html(response)
        @$('.view-block').show()
        @$('.form-block').hide()
      .fail (response) =>
        @$('.form-block').html(response)

    # Prevent form from being submitted again
    return false
