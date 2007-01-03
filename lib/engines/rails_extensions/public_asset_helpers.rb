# add methods to handle including javascripts and stylesheets
module Engines::RailsExtensions::PublicAssetHelpers
  def self.included(base)
    base.class_eval do
      [:stylesheet_link_tag, :javascript_include_tag, :image_path, :image_tag].each do |m|
        alias_method_chain m, :engine_additions
      end
    end
  end
  
  def stylesheet_link_tag_with_engine_additions(*sources)
    stylesheet_link_tag_without_engine_additions(*Engines::RailsExtensions::PublicAssetHelpers.pluginify_sources("stylesheets", *sources))
  end
  
  def javascript_include_tag_with_engine_additions(*sources)
    javascript_include_tag_without_engine_additions(*Engines::RailsExtensions::PublicAssetHelpers.pluginify_sources("javascripts", *sources))
  end
  
  #--
  # Our modified image_path now takes a 'plugin' option, though it doesn't require it
  #++
  
  def image_path_with_engine_additions(source, options={})
    options.stringify_keys!
    source = Engines::RailsExtensions::PublicAssetHelpers.plugin_source_path(options["plugin"], "images", source) if options["plugin"]
    image_path_without_engine_additions(source)
  end
  
  def image_tag_with_engine_additions(source, options={})
    options.stringify_keys!
    if options["plugin"]
      source = Engines::RailsExtensions::PublicAssetHelpers.plugin_source_path(options["plugin"], "images", source)
      options.delete("plugin")
    end
    image_tag_without_engine_additions(source, options)
  end
  
  #--
  # The following are methods on this module directly because of the weird-freaky way
  # Rails creates the helper instance that views actually get
  #++
  
  # convert sources to absolute paths for the given plugin, if any plugin option is given
  def self.pluginify_sources(type, *sources)
    options = sources.last.is_a?(Hash) ? sources.pop.stringify_keys : { }
    sources.map! { |s| plugin_source_path(options["plugin"], type, s) } if options["plugin"]
    options.delete("plugin") # we don't want it appearing in the HTML
    sources << options # re-add options      
  end  

  def self.plugin_source_path(plugin_name, type, source)
    raise "No plugin called '#{plugin_name}' - please use the full name of a loaded plugin." if Rails.plugins[plugin_name].nil?
    "/#{Rails.plugins[plugin_name].public_asset_directory}/#{type}/#{source}"
  end
end

::ActionView::Helpers::AssetTagHelper.send(:include, Engines::RailsExtensions::PublicAssetHelpers)