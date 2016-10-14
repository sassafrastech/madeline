# Controls the timeline modal (no more than one per page).
class MS.Views.TimelineTableView extends Backbone.View

  el: 'section.timeline-table'

  initialize: (options) ->
    @loanId = options.loanId
    @modal = new MS.Views.ProjectGroupModalView(loanId: @loanId, success: @refresh.bind(@))

  events:
    'click .timeline-action.new': 'newGroup'
    'click #project-group-menu [data-action="edit"]': 'editGroup'
    'click #project-group-menu [data-action="add-child-group"]': 'newChildGroup'
    'click .project-group .fa-cog': 'openGroupMenu'
    'click .project-group .disabled a': 'disableDeleteLink'
    'click .project-group a[data-action="delete"]': 'disableDeleteLink'
    'confirm:complete': 'deleteConfirm'

  refresh: ->
    MS.loadingIndicator.show()
    @$('.timeline-table').empty()
    $.get "/admin/loans/#{@loanId}/timeline", (html) =>
      MS.loadingIndicator.hide()
      @$el.html(html)

  newGroup: (e) ->
    e.preventDefault()
    @modal.show()

  newChildGroup: (e) ->
    e.preventDefault()

    $project_group = $(e.target).closest(".project-group")
    project_group_id = $project_group.data("action-key")
    @modal.show(project_group_id)

  editGroup: (e) ->
    e.preventDefault()

    $project_group = $(e.target).closest(".project-group")
    project_group_id = $project_group.data("action-key")
    @modal.edit(project_group_id)

  openGroupMenu: (e) ->
    button = e.currentTarget
    menu = $(button).closest('.timeline-table').find('#project-group-menu')
    $(button).after(menu)

  deleteConfirm: (e, response) ->
    e.preventDefault()

    $project_group = $(e.target).closest(".project-group")
    project_group_id = $project_group.data("action-key")
    url = "/admin/project_groups/#{project_group_id}"

    MS.loadingIndicator.show()
    $.post url, {'_method': 'DELETE'}, (html) =>
      MS.loadingIndicator.hide()
      @refresh()

  # Disable the links to prevent clearing of the filter
  disableDeleteLink: (e) ->
    e.preventDefault()
