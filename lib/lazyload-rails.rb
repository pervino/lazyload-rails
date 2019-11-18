require "nokogiri"
require "action_view"
require "lazyload-rails/version"
require "lazyload-rails/config"

module Lazyload
  module Rails

    def self.configuration
      @configuration ||= Lazyload::Rails::Configuration.new
    end

    def self.configuration=(new_configuration)
      @configuration = new_configuration
    end

    # Yields the global configuration to a block.
    #
    # Example:
    #   Lazyload::Rails.configure do |config|
    #     config.placeholder = '/public/images/foo.gif'
    #   end
    def self.configure
      yield configuration if block_given?
    end

    def self.reset
      @configuration = nil
    end
  end
end

ActionView::Helpers::AssetTagHelper.module_eval do
  alias :rails_image_tag :image_tag

  def image_tag(*attrs)
    options, args = extract_options_and_args(*attrs)
    image_html = rails_image_tag(*args)
    classes = image_html["class"]

    is_lazy = options.fetch(:lazy) { Lazyload::Rails.configuration.lazy_by_default }

    puts '------------------'
    puts image_html 
    puts is_lazy
    if is_lazy
      to_lazy(image_html , classes)
    else
      image_html
    end
  end

  private

  def to_lazy(image_html, classes)
    puts '------------------'
    puts classes
    img = Nokogiri::HTML::DocumentFragment.parse(image_html).at_css("img")

    puts img 
    puts img["class"].to_str
    puts img["class"].to_s
    puts img["className"]

    img["data-original"] = img["src"]
    img["src"] = Lazyload::Rails.configuration.placeholder
    if Lazyload::Rails.configuration.lazy_class
      img["class"] = img["class"].present? ? img["class"].to_str + " " + Lazyload::Rails.configuration.lazy_class : Lazyload::Rails.configuration.lazy_class 
    end
    


    img.to_s.html_safe
  end

  def extract_options_and_args(*attrs)
    args = attrs

    if args.size > 1
      options = attrs.last.dup
      args.last.delete(:lazy)
    else
      options = {}
    end

    [options, args]
  end
end
