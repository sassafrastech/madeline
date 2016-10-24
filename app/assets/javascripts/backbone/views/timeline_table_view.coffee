# Controls the timeline modal (no more than one per page).
class MS.Views.TimelineTableView extends Backbone.View

  el: 'section.timeline-table'

  initialize: (options) ->
    new MS.Views.AutoLoadingIndicatorView()
    @loanId = options.loanId
    @groupModal = new MS.Views.ProjectGroupModalView(loanId: @loanId, success: @refresh.bind(@))
    @stepModal = options.stepModal
    new MS.Views.TimelineSelectStepsView(el: '#timeline-table')

  events:
    'click .project-group .fa-cog': 'openGroupMenu'
    'click .step-menu-col .fa-cog': 'openStepMenu'
    'click .timeline-action[data-action="new-group"]': 'newGroup'
    'click .timeline-action[data-action="new-step"]': 'newStep'
    'confirm:complete #project-step-menu [data-action="delete"]': 'deleteStep'
    'click #project-group-menu [data-action="add-child-group"]': 'newChildGroup'
    'click #project-group-menu [data-action="edit"]': 'editGroup'
    'confirm:complete #project-group-menu [data-action="delete"]': 'deleteGroup'
    'click #project-step-menu a[data-action=edit]': 'editStep'
    'click ul.dropdown-menu li.disabled a': 'handleDisabledMenuLinkClick'

  refresh: ->
    MS.loadingIndicator.show()
    $.get "/admin/loans/#{@loanId}/timeline", (html) =>
      MS.loadingIndicator.hide()
      @$el.html(html)

  newGroup: (e) ->
    e.preventDefault()
    @groupModal.new()

  newChildGroup: (e) ->
    e.preventDefault()
    @groupModal.new(@parentId(e))

  editGroup: (e) ->
    e.preventDefault()
    @groupModal.edit(@parentId(e))

  deleteGroup: (e, response) ->
    e.preventDefault()
    $.post("/admin/project_groups/#{@parentId(e)}", {'_method': 'DELETE'})
    .done => @refresh()
    .fail (response) => MS.alert(response.responseText)

  newStep: (e) ->
    e.preventDefault()
    @stepModal.new(@loanId, @refresh.bind(@))

  editStep: (e) ->
    e.preventDefault()
    @stepModal.edit(@$(e.currentTarget).closest('[data-id]').data('id'), @refresh.bind(@))

  parentId: (e) ->
    @$(e.target).closest(".project-group").data("id")

  openGroupMenu: (e) ->
    $deleteLink = @$('#project-group-menu a[data-action="delete"]').closest('li')

    if @$(e.currentTarget).closest('.project-group').hasClass('with-children')
      $deleteLink.addClass('disabled')
    else
      $deleteLink.removeClass('disabled')

    @openMenu(e, 'group')

  openStepMenu: (e) ->
    @openMenu(e, 'step')

  openMenu: (e, which) ->
    link = e.currentTarget
    $menu = $(link).closest('.timeline-table').find("#project-#{which}-menu")
    $(link).after($menu)

  # Don't do anything with clicks on menu links that are set to disabled.
  handleDisabledMenuLinkClick: (e) ->
    e.stopPropagation()

  deleteStep: (e) ->
    item = e.currentTarget
    stepId = $(item).closest('.step-menu-col').data('id')
    $.ajax(type: "DELETE", url: "/admin/project_steps/#{stepId}")
    .done =>
      @refresh()
    .fail (response) ->
      MS.alert(response.responseText)
