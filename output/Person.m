#import "Person.h"

@implementation PersonBuilder
- (instancetype)init {
    if (self = [super init]) {
        _name = nil;
        _age = nil;
        _height = nil;
        _weight = nil;
        _alive = YES;
    }
    return self;
}
@end

@implementation Person

- (instancetype)initWithBuilder:(PersonBuilder *)builder {
    if (self = [super init]) {
        _name = builder.name;
        _age = builder.age;
        _height = builder.height;
        _weight = builder.weight;
        _alive = builder.alive;
    }
    return self;
}

- (PersonBuilder *)makeBuilder {
    PersonBuilder *builder = [PersonBuilder new];
    builder.name = _name;
    builder.age = _age;
    builder.height = _height;
    builder.weight = _weight;
    builder.alive = _alive;
    return builder;
}

- (instancetype)init {
    PersonBuilder *builder = [PersonBuilder new];
    return [self initWithBuilder:builder];
}

+ (instancetype)makeWithBuilder:(void (^)(PersonBuilder *))updateBlock {
    PersonBuilder *builder = [PersonBuilder new];
    updateBlock(builder);
    return [[Person alloc] initWithBuilder:builder];
}

- (instancetype)update:(void (^)(PersonBuilder *))updateBlock {
    PersonBuilder *builder = [self makeBuilder];
    updateBlock(builder);
    return [[Person alloc] initWithBuilder:builder];
}
@end
