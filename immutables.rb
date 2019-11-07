require 'erb' # import같은 거 erb(embeded ruby)는 문자열 안에 루비 코드 넣는 것

#클래스
class Context
  #프로퍼티 접근자제어 외부에서 읽을 수 있게
  attr_reader :properties,
    :class_name,
    :headers_str,
    :enums_str
 
 # 초기메소드
  def initialize
    # 배열 프로퍼티 properties 초기화
    @properties = []
  end
  # 메소드(string인자값)
  def enums(str)
    # 인자값 strt을 입력받아서 enums_str String 프로퍼티에 넣음
    @enums_str = str
  end
  
  def headers(str)
    @headers_str = str
  end

  # model메소드(model_class_name 문자열 인자값, block 블록 인자값)
  def model(model_class_name, &block)
    @class_name = model_class_name
    #
    instance_eval(&block)
  end
  # 메소드(string 인자, 해쉬인자)
  def property(name, args = {})
    # properties에 name:name해쉬와 args에 있는 해쉬를 하나씩 머지해서 추가
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
      #배열
    parts = ["@property"]

    readonly_string = readonly ? ", readonly" : ""

    property_options = ["nonatomic"]
    
    # 해쉬 찾는 것 args[type] 같은
    if args[:type].include?("*")
      property_options << (args[:type] =~ /^NS/ ? "copy" : "strong")
    end

    if readonly
        # 배열에 하나 추가
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

  # <%- -%> 루비 코드 자체가 가운데 들어감
  # <%= %> 루비 코드 자체가 가운데 들어가는데 그 결과값
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
