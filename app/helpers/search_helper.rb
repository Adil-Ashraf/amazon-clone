module SearchHelper
  # Stimulus wiring for the header search boxes (desktop and mobile). Every box
  # shows suggestions as you type (search_suggest_controller.js); on the
  # catalog it also live-updates the results frame (live_search_controller.js),
  # so both controllers and their actions are combined.
  def search_form_data(live:)
    data = { controller: "search-suggest", search_suggest_url_value: search_suggestions_path,
             action: "submit->search-suggest#submitted click@window->search-suggest#closeOnOutsideClick" }
    return data unless live

    data.merge(controller: "live-search #{data[:controller]}", live_search_frame_value: "products_results",
               action: "submit->live-search#submit turbo:frame-load@document->live-search#frameLoaded #{data[:action]}")
  end

  def search_input_data(live:)
    data = { search_suggest_target: "input",
             action: "input->search-suggest#search keydown->search-suggest#navigate focus->search-suggest#reopen" }
    return data unless live

    data.merge(live_search_target: "input", action: "input->live-search#search blur->live-search#blur #{data[:action]}")
  end

  # The input is a combobox controlling its suggestions panel.
  def search_input_aria(frame_id)
    { role: "combobox", "aria-autocomplete": "list", "aria-expanded": "false", "aria-controls": "#{frame_id}_panel" }
  end
end
