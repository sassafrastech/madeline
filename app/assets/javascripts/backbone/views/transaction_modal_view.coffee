class MS.Views.TransactionModalView extends Backbone.View
  el: '#transaction-modal'

  events:
    'click .btn-primary': 'submitForm'
    'ajax:complete form': 'submitComplete'
    'change #accounting_transaction_loan_transaction_type_value': 'setDescription'

  initialize: (params) ->
    @loanId = params.loanId

  new: (projectId) ->
    url = "/admin/accounting/transactions/new"
    @loadContent(url, projectId)

  show: (id, projectId) ->
    url = "/admin/loans/#{projectId}/transactions/#{id}"
    @loadContent(url, projectId)

  loadContent: (url, projectId) ->
    $.get url, project_id: projectId, (html) =>
      @replaceContent(html)
      @$el.modal('show')

  replaceContent: (html) ->
    @$el.find('.modal-content').html(html)

  submitForm: ->
    MS.loadingIndicator.show()
    @$('form').submit()

  submitComplete: (e, data) ->
    if parseInt(data.status) == 200
      @$el.modal('hide')
      window.location.reload(true)
    else
      MS.loadingIndicator.hide()
      @$('.modal-content').html(data.responseText)

  setDescription: (e) ->
    if e.target.value != ''
      description = I18n.t('transactions.default_description',
        loan_transaction_type: e.target.selectedOptions[0].innerText, loan_id: @loanId)
    else
      description = ''
    $('#accounting_transaction_description').val(description)
