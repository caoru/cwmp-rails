class ValuesController < ApplicationController
  def get
    @default_model = ACS.default_model
  end

  def set
    @default_model = ACS.default_model
  end

  def form_get
    name = params[:name]
    type = params[:type]

    html = ApplicationController.render partial: "values/form_get.html.erb", locals: {name: name, type: type}, formats: [:html]

    json_response({ :html => html })
  end

  def form_set
    name = params[:name]
    type = params[:type]
    enums = params[:enums]

    if enums.nil?
      enums = []
    end

    html = ApplicationController.render partial: "values/form_set.html.erb", locals: {name: name, type: type, enums: enums}, formats: [:html]

    json_response({ :html => html })
  end
end

