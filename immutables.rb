require 'erb'

class Context
  attr_reader :properties,
    :class_name,
    :headers_str,
    :enums_str

  def initialize
    @properties = []
  end

  def enums(str)
    @enums_str = str
  end

  def headers(str)
    @headers_str = str
  end

  def model(model_class_name, &block)
    @class_name = model_class_name
    instance_eval(&block)
  end

  def property(name, args = {})
    @properties << args.merge(name: name)
  end
end

class ModelDefinition
  def initialize(text)
    @context = Context.new
    @context.instance_eval(text)
  end

  def header
    erb_template = ERB.new(header_template, nil, '-')
    erb_template.result(binding)
  end

  def implementation
    erb_template = ERB.new(implementation_template, nil, '-')
    erb_template.result(binding)
  end

  def class_name
    context.class_name
  end

  private

  attr_reader :context

  def property_definition(readonly, args)
    parts = ["@property"]

    readonly_string = readonly ? ", readonly" : ""

    property_options = ["nonatomic"]

    if args[:type].include?("*")
      property_options << (args[:type] =~ /^NS/ ? "copy" : "strong")
    end

    if readonly
      property_options << "readonly"
    end

    if args[:getter]
      property_options << "getter=#{args[:getter]}"
    end

    parts << "(#{property_options.join(", ")})"

    parts << args[:type]
    parts << args[:name]

    line = parts.join(" ").gsub("* ", "*")

    "#{line};#{args[:comment] ? " // #{args[:comment]}" : nil}"
  end

  def default_value(args)
    if args[:default]
      args[:default]
    else 
      case args[:type]
      when "BOOL"
        "NO"
      when /NSArray/
        "@[]"
      when /NSDictionary/
        "@{}"
      when /\*/
        "nil"
      else
        "0"
      end
    end
  end

  def header_template
    template = <<-EOS
#import <Foundation/Foundation.h>
#import "Mantle.h"
<%- if context.headers_str -%>
<%= context.headers_str %>
<%- end -%>

<%- if context.enums_str -%>
<%= context.enums_str %>
<%- end -%>

@interface <%= context.class_name %>Builder : MTLModel
<% context.properties.each do |prop| -%>
<%= property_definition(false, prop) %>
<% end -%>
@end

@interface <%= context.class_name %> : MTLModel
<% context.properties.each do |prop| -%>
<%= property_definition(true, prop) %>
<% end -%>

- (instancetype)init;
- (instancetype)initWithBuilder:(<%= context.class_name %>Builder *)builder;
+ (instancetype)makeWithBuilder:(void (^)(<%= context.class_name %>Builder *))updateBlock;
- (instancetype)update:(void (^)(<%= context.class_name %>Builder *))updateBlock;
@end
EOS
  end

  def implementation_template
    template = <<-EOS
#import "<%= context.class_name %>.h"

@implementation <%= context.class_name %>Builder
- (instancetype)init {
    if (self = [super init]) {
      <%- context.properties.each do |prop| -%>
        _<%= prop[:name] %> = <%= default_value(prop) %>;
      <%- end -%>
    }
    return self;
}
@end

@implementation <%= context.class_name %>

- (instancetype)initWithBuilder:(<%= context.class_name %>Builder *)builder {
    if (self = [super init]) {
      <%- context.properties.each do |prop| -%>
        _<%= prop[:name] %> = builder.<%= prop[:name] %>;
      <%- end -%>
    }
    return self;
}

- (<%= class_name %>Builder *)makeBuilder {
    <%= context.class_name %>Builder *builder = [<%= context.class_name %>Builder new];
    <%- context.properties.each do |prop| -%>
    builder.<%= prop[:name] %> = _<%= prop[:name] %>;
    <%- end -%>
    return builder;
}

- (instancetype)init {
    <%= context.class_name %>Builder *builder = [<%= context.class_name %>Builder new];
    return [self initWithBuilder:builder];
}

+ (instancetype)makeWithBuilder:(void (^)(<%= context.class_name %>Builder *))updateBlock {
    <%= context.class_name %>Builder *builder = [<%= context.class_name %>Builder new];
    updateBlock(builder);
    return [[<%= context.class_name %> alloc] initWithBuilder:builder];
}

- (instancetype)update:(void (^)(<%= context.class_name %>Builder *))updateBlock {
    <%= context.class_name %>Builder *builder = [self makeBuilder];
    updateBlock(builder);
    return [[<%= context.class_name %> alloc] initWithBuilder:builder];
}
@end
EOS
  end
end


def replace_file(path, content)
  File.open(path, "w") do |file|
    file.write(content)
  end
end

ARGV.each do |filename|
  model_definition = ModelDefinition.new(File.read(filename))

  replace_file("output/#{model_definition.class_name}.h", model_definition.header)
  replace_file("output/#{model_definition.class_name}.m", model_definition.implementation)
  #puts model_definition.context.properties
end
