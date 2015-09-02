module Ddr::Batch
  module ApplicationHelper

    def render_tab(tab)
      content_tag :li do
        link_to(tab.label, "##{tab.css_id}", "data-toggle" => "tab")
      end
    end

    def render_tabs
      return if current_tabs.blank?
      current_tabs.values.inject("") { |output, tab| output << render_tab(tab) }.html_safe
    end

    def render_tab_content(tab)
      content_tag :div, class: "tab-pane", id: tab.css_id do
        render partial: tab.partial, locals: {tab: tab}
      end
    end

    def render_tabs_content
      return if current_tabs.blank?
      current_tabs.values.inject("") { |output, tab| output << render_tab_content(tab) }.html_safe
    end

  end
end
