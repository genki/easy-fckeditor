# Fckeditor
module Fckeditor
  PLUGIN_NAME = 'easy-fckeditor'
  PLUGIN_PATH = "#{RAILS_ROOT}/vendor/plugins/#{PLUGIN_NAME}"
  PLUGIN_PUBLIC_PATH = "#{PLUGIN_PATH}/public"
  PLUGIN_CONTROLLER_PATH = "#{PLUGIN_PATH}/app/controllers"
  PLUGIN_VIEWS_PATH = "#{PLUGIN_PATH}/app/views"
  PLUGIN_HELPER_PATH = "#{PLUGIN_PATH}/app/helpers"

  module Helper
    def fckeditor_textarea(object, field, options = {})
      var = instance_variable_get("@#{object}")
      if var
        value = var.send(field.to_sym)
        value = value.nil? ? "" : value
      else
        value = ""
        klass = "#{object}".camelcase.constantize
        instance_variable_set("@#{object}", eval("#{klass}.new()"))
      end

      id = fckeditor_element_id(object, field)

      options = {
        'width' => '100%',
        'height' => '100%',
      }.merge(options.stringify_keys)
      # can't allow id to be overridden since we depend on value elsewhere
      options['id'] = id

      toolbarSet = options.delete('toolbarSet') ||
        options.delete('toolbar_set') || 'Default'

      name = "#{object}[#{field}]"
      if options.delete('ajax')
        inputs = hidden_field_tag(name, nil, :id => "#{id}_hidden") +
          text_area_tag(id, value, options)
      else
        inputs = text_area_tag(name, value, options)
      end

      js_path = "#{ActionController::Base.relative_url_root}/javascripts"
      base_path = "#{js_path}/fckeditor/"
      return inputs <<
        javascript_tag(
          "var oFCKeditor = new FCKeditor('#{id}', '#{options['width']}', '#{options['height']}', '#{toolbarSet}');\n" <<
          "oFCKeditor.BasePath = \"#{base_path}\"\n" <<
          "oFCKeditor.Config['CustomConfigurationsPath'] = '#{js_path}/fckcustom.js';\n" <<
          "oFCKeditor.ReplaceTextarea();\n"
        )
    end

    def fckeditor_form_remote_tag(options = {})
      editors = options[:editors]
      before = ""
      editors.keys.each do |e|
        editors[e].each do |f|
          before += fckeditor_before_js(e, f)
        end
      end
      options[:before] =
        options[:before].nil? ? before : before + options[:before]
      form_remote_tag(options)
    end

    def fckeditor_remote_form_for(object_name, *args, &proc)
      options = args.last.is_a?(Hash) ? args.pop : {}
      concat(fckeditor_form_remote_tag(options), proc.binding)
      fields_for(object_name, *(args << options), &proc)
      concat('</form>', proc.binding)
    end
    alias_method :fckeditor_form_remote_for, :fckeditor_remote_form_for

    def fckeditor_element_id(object, field)
      id = eval("@#{object}.object_id")
      "#{object}_#{id}_#{field}_editor"
    end

    def fckeditor_div_id(object, field)
      id = eval("@#{object}.object_id")
      "div-#{object}-#{id}-#{field}-editor"
    end

    def fckeditor_before_js(object, field)
      id = fckeditor_element_id(object, field)
      "var oEditor = FCKeditorAPI.GetInstance('"+id+"'); document.getElementById('"+id+"_hidden').value = oEditor.GetXHTML();"
    end
  end
end

include ActionView
module ActionView::Helpers::AssetTagHelper
  alias_method :rails_javascript_include_tag, :javascript_include_tag

  #  <%= javascript_include_tag :defaults, :fckeditor %>
  def javascript_include_tag(*sources)
    main_sources, application_source = [], []
    if sources.include?(:fckeditor)
      sources.delete(:fckeditor)
      sources.push('fckeditor/fckeditor')
    end
    unless sources.empty?
      main_sources = rails_javascript_include_tag(*sources).split("\n")
      application_source = main_sources.pop if main_sources.last.include?('application.js')
    end
    [main_sources.join("\n"), application_source].join("\n")
  end
end
