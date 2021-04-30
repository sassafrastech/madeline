require 'rails_helper'

describe RouteTranslator do
  it "should route US loans page correctly" do
    expect(get "/us/loans").to route_to(
      controller: "public/loans",
      action: "index",
      locale: "en",
      site: "us",
    )
  end

  it "should route Nicaragua loans page correctly" do
    expect(get "/nicaragua/prestamos").to route_to(
      controller: "public/loans",
      action: "index",
      locale: "es",
      site: "nicaragua",
    )
  end
end
