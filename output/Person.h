#import <Foundation/Foundation.h>
#import "Mantle.h"
#import "SomeOtherFile.h



@interface PersonBuilder : MTLModel
@property (nonatomic, copy) NSString *name;
@property (nonatomic, copy) NSNumber *age;
@property (nonatomic, copy) NSNumber *height;
@property (nonatomic, copy) NSNumber *weight;
@property (nonatomic, getter=isAlive) BOOL alive;
@end

@interface Person : MTLModel
@property (nonatomic, copy, readonly) NSString *name;
@property (nonatomic, copy, readonly) NSNumber *age;
@property (nonatomic, copy, readonly) NSNumber *height;
@property (nonatomic, copy, readonly) NSNumber *weight;
@property (nonatomic, readonly, getter=isAlive) BOOL alive;

- (instancetype)init;
- (instancetype)initWithBuilder:(PersonBuilder *)builder;
+ (instancetype)makeWithBuilder:(void (^)(PersonBuilder *))updateBlock;
- (instancetype)update:(void (^)(PersonBuilder *))updateBlock;
@end
