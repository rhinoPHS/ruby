headers <<-EOS
#import "SomeOtherFile.h
EOS
# headers에 string을 집어 넣는다. EOS -> end of string

#함수이름 인자, 인자(블록)
model "Person" do
  #함수이름  인자, 인자(해쉬) *해쉬 map & dictionary 같은 거
  property "name", type: "NSString *"
  property "age", type: "NSNumber *"
  property "height", type: "NSNumber *"
  property "weight", type: "NSNumber *"
  property "alive", type: "BOOL", default: "YES", getter: "isAlive"
end 
