class MS.Views.LoanChartsView extends Backbone.View

  el: '.summary-chart'

  initialize: (params) ->
    @breakevenData = params.breakeven_data
    # console.log(@breakevenData)
    @loadCharts()
    @breakevenRevenueChart()

  revenueChart: () ->
    data = {
      "cols": [
        {"id":"","label":"Product","pattern":"","type":"string"},
        {"id":"","label":"Revenue","pattern":"","type":"number"}
      ],
      "rows": [
        {"c":[{"v":"Product 1","f":null},{"v":80000,"f":null}]},
        {"c":[{"v":"Product 2","f":null},{"v":36000,"f":null}]},
        {"c":[{"v":"Product 3","f":null},{"v":15000,"f":null}]}
      ]
    }
    data = new google.visualization.DataTable(data);
    chart = new google.visualization.PieChart(document.getElementById('revenue-chart'));
    chart.draw(data, {width: 400, height: 240, title: "Revenue by Product"});

  breakevenRevenueChart: () ->
    # console.log(@breakevenData)
    @breakevenRevenue = @breakevenData["revenue"]
    # console.log(@breakevenRevenue)

    rows = []

    for key,product of @breakevenRevenue
      name = product.name
      total = product.total
      rows.push({"c":[{"v": name, "f":null},{"v": total, "f":null}]})

    console.log(rows)

  loadCharts: () ->
    console.log(@breakevenData)
    google.charts.load('current', {'packages':['corechart']});
    google.charts.setOnLoadCallback(@revenueChart);
