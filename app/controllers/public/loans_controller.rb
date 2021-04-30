class Public::LoansController < Public::PublicController
  def index
    division = params[:division] || division_for_site(params[:site])
    redirect_to controller: "divisions", action: "show", short_name: division
  end

  def division_for_site(site)
    case site.downcase
    when "us"
      "seed-commons"
    when "nicaragua"
      "la-base-nicaragua"
    when "argentina"
      "la-base-argentina"
    else
      "seed-commons"
    end
  end

  def show
    @loan = Loan.find(params[:id])
    division_shortname = @loan.division.short_name
    redirect_to controller: "divisions", action: "show", short_name: division_shortname
  end
end
