module AdminHelper
  def authorized_form_field(simple_form: nil, model: nil, field_name: nil, choices: nil,
    include_blank_choice: true, classes: '', form_identifier: nil, popover_options: {})

    model_field = model.send(field_name)
    if model_field
      policy = "#{model_field.class.name}Policy".constantize.new(current_user, model_field)
      link_path = url_for([:admin, model_field])
    end

    render partial: 'admin/common/authorized_form_field', locals: {
      f: simple_form,
      model_field: model_field,
      field_name: field_name,
      id_field_name: "#{field_name}_id",
      link_path: link_path,
      choices: choices,
      include_blank_choice: include_blank_choice,
      may_show_link: model_field && policy.show?,
      # Beware, if the 'may_edit' logic changes and might be false even with a non-nil model_field,
      # then the paratial code will also need updating to make nil safe.
      may_edit: !model_field || policy.show?,
      classes: classes,
      form_identifier: form_identifier,
      popover_options: popover_options
    }
  end

  # This should be updated whenever columns are added/removed to the timeline table
  def timeline_table_step_column_count
    8
  end

  # For displaying tree structure in dropdowns
  def indented_option_label(node, label_method)
    # Subtract 1 from depth since root node either doesn't display or displays as "[None]"
    ("&nbsp; &nbsp; " * [node.depth - 1, 0].max).html_safe << node.send(label_method)
  end

  # Displays Font Awesome icons
  def icon_tag(class_name, options: {})
    content_tag(:i, "", id: options[:id], data: options[:data], class: "fa fa-#{class_name} #{options[:extra_classes]}")
  end

  def documentation_popover(documentations, html_identifier: "", options: {})
    documentation = documentations[html_identifier]
    placement = options[:placement] || 'right'
    if documentation.present?
      data_content = documentation&.summary_content.to_s
      if documentation.page_content.present? && policy(documentation).show?
        learn_more_link = link_to t("documentation.learn_more"), admin_documentation_path(documentation), target: :_blank
        data_content << "<br /><br />" << learn_more_link
      end
      action_link = link_to icon_tag("pencil"), edit_admin_documentation_path(documentation), id: "#{html_identifier}-edit-link" if policy(documentation).edit?
    else
      new_documentation = Documentation.new(division: current_division)
      return "" unless policy(new_documentation).new?
      caller_string = "#{controller_name}##{action_name}"
      data_content = t("documentation.no_documentations")
      action_link = link_to icon_tag("plus"),
        new_admin_documentation_path(caller: caller_string, html_identifier: html_identifier), id: "#{html_identifier}-new-link" if policy(new_documentation).new?
      extra_classes = "text-muted"
    end
    title_content = content_tag(:span, action_link, class: "text-right")
    data_hash = { toggle: "popover", content: data_content, html: true, title: title_content, placement: placement }
    content_tag(:a, tabindex: 0, data: data_hash, class: 'ms-popover ms-documentation', id: "#{html_identifier}-link") do
      icon_tag("question-circle", options: {id: html_identifier, extra_classes: extra_classes})
    end
  end
end
