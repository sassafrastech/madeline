# Handles clicks on the tabs on the loan page.
# Initializes Views for each of the tabs where necessary, but only once they are clicked on.
class MS.Views.LoanTabView extends Backbone.View

  initialize: (params) ->
    @loanId = params.loanId
    @calendarEventsUrl = params.calendarEventsUrl

    # This is shared among several tabs so we initialize it here.
    @stepModal = new MS.Views.ProjectStepModalView()

    new MS.Views.TabHistoryManager(el: @el, basePath: "/admin/loans/#{@loanId}")

    @openDetails() if @$('.edit-tab').closest('li').hasClass('active')
    @openCalendar() if @$('.calendar-tab').closest('li').hasClass('active')
    @loadSteps() if @$('.timeline-tab').closest('li').hasClass('active')
    @loadTimelineTable() if @$('.timeline-table-tab').closest('li').hasClass('active')
    @loadQuestionnaires() if @$('.questions-tab').closest('li').hasClass('active')

  events:
    'shown.bs.tab .edit-tab': 'openDetails'
    'shown.bs.tab .calendar-tab': 'openCalendar'
    'shown.bs.tab .timeline-tab': 'loadSteps'
    'shown.bs.tab .timeline-table-tab': 'loadTimelineTable'
    'shown.bs.tab .questions-tab': 'loadQuestionnaires'

  openDetails: ->
    if MS.detailsView
      MS.detailsView.refresh()
    else
      MS.detailsView = new MS.Views.DetailsView(loanId: @loanId)

  openCalendar: ->
    if MS.calendarView
      MS.calendarView.refresh()
    else
      MS.calendarView = new MS.Views.CalendarView(
        calendarEventsUrl: @calendarEventsUrl,
        stepModal: @stepModal
      )

  loadSteps: ->
    if MS.timelineView
      MS.timelineView.refreshSteps()
    else
      MS.timelineView = new MS.Views.TimelineView(loanId: @loanId)

  loadTimelineTable: ->
    if MS.timelineTableView
      MS.timelineTableView.refresh()
    else
      MS.timelineTableView = new MS.Views.TimelineTableView(loanId: @loanId, stepModal: @stepModal)

  loadQuestionnaires: ->
    if MS.loanQuestionnairesView
      MS.loanQuestionnairesView.refreshContent()
    else
      MS.loanQuestionnairesView = new MS.Views.LoanQuestionnairesView(loanId: @loanId)
