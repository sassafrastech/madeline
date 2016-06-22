class MS.Views.FilterSwitchView extends Backbone.View

  el: 'body'

  initialize: (params) ->
    @listenTo(Backbone, 'popstate', @popstate)
    @defaultFilter = params['defaultFilter']
    @filterInit()

  popstate: (e) ->
    @filterInit()

  events: (params) ->
    'click .filter-switch .btn': 'filterSwitch'

  filterSwitch: (e) ->
    selected = $(e.currentTarget).find('input')[0].value
    @doFilter(selected)
    url = URI(window.location.href).setQuery('filter', selected).href()
    history.pushState(null, "", url)

  filterInit: ->
    selected = URI(window.location.href).query(true)['filter'] || @defaultFilter
    $('.filter-switch .btn').removeClass('active')
    $(".filter-switch input[value='#{selected}']").closest('.btn').addClass('active')
    @doFilter(selected)

  doFilter: (selected) ->
    if selected == 'all'
      $('.filterable').show()
    else
      $('.filterable').hide()
      $(".filterable.#{selected}").show()
