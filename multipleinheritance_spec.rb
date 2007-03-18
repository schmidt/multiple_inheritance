require 'multipleinheritance'

class A
  A_CONSTANT = "a"
  def a; "a"; end; 
  def left_first; a; end
  def own; a; end
  def inst_plus; @a + 1; end
  def inspect; a; end
  def self.inherited( subclass ); @subclasses << subclass end
  self.instance_variable_set( :@subclasses, [] )
end

class B
  B_CONSTANT = "b"
  def b; "b"; end
  def left_first; b; end
  def own; b; end
  def inst_minus; @a - 1; end
  def to_s; b; end
  def method_missing( method_name, *arguments ); method_name.to_s.upcase; end
  def self.inherited( subclass ); @subclasses << subclass end
  self.instance_variable_set( :@subclasses, [] )
end

class AB < Multiple( A, B )
  AB_DEFINED_CONSTANT = "ab"
  def init_access; @a = 3; end
  def ab; a + b; end 
  def own; ab; end 
  def access_constant_from_A; A_CONSTANT; end
  def access_constant_from_B; B_CONSTANT; end
  def access_constant_from_AB; AB_CONSTANT; end
  def self.const_missing( const_name )
    if const_name.to_s =~ /^AB_/; A_CONSTANT; else; super; end
  end
  def method_missing( method_name, *arguments )
    if method_name.to_s =~ /hase/; method_name.to_s; else; super; end
  end
end

context "A subclass of A and B" do
  specify "should answer with [A, B] when sended 'superclasses'" do
    AB.superclasses.should == [A, B]
  end
  
  specify "should not list constants defined in its superclasses, when sent 'constants'" do
    AB.constants.should_not_include A::A_CONSTANT
    AB.constants.should_not_include B::B_CONSTANT
  end

  specify "should not answer true to const_defined? for constants defined in A or B" do
    AB.should_not_const_defined :A_CONSTANT
    AB.should_not_const_defined :B_CONSTANT
  end
  specify "should answer true to const_defined? for constants defined in it" do
    AB.should_const_defined :AB_DEFINED_CONSTANT
  end

  specify "should list methods of its superclasses in instance_methods( true )" do
    AB.instance_methods.should_include "a"
    AB.instance_methods.should_include "b"
  end
end

context "The Ancestors of a subclass of A and B" do
  specify "should contain A, B and Object" do
    AB.ancestors.should_include A
    AB.ancestors.should_include B
    AB.ancestors.should_include Kernel
  end
  specify "should have A as first element" do
    AB.ancestors.first.should == A
  end
  specify "should not include double entries" do
    AB.ancestors.size.should == AB.ancestors.uniq.size
  end
  specify "should contain A before B" do
    AB.ancestors.index( A ).should < AB.ancestors.index( B )
  end
  specify "should contain B before Object" do
    AB.ancestors.index( B ).should < AB.ancestors.index( Object )
  end
end

context "An instance of a subclass of A and B" do
  setup do
    @instance = AB.new
  end
  
  specify "should be kind of its class" do
    @instance.should( be_kind_of( AB ) )
  end
  specify "should be kind of its super classes" do
    @instance.should( be_kind_of( A ) )
    @instance.should( be_kind_of( B ) )
  end
  specify "should be kind of its super super classes" do
    @instance.should( be_kind_of( Object ) )
  end
  
  specify "should prefer its own methods over inherited ones" do
    @instance.own.should == "ab"
  end
  specify "should be able to call inherited methods" do
    @instance.a.should == "a"
    @instance.b.should == "b"
  end
  specify "should be able to combine inherited calls" do
    @instance.ab.should == "ab"
  end
  specify "should prefer methods defined in A over Object's" do
    @instance.inspect.should == "a"
  end
  specify "should prefer methods defined in B over Object's" do
    @instance.to_s.should == "b"
  end
  specify "should prefer methods defined in A over B's (left first)" do
    @instance.left_first.should == "a"
  end
  specify "should be able to use method_missing" do
    @instance.hasenfuss.should == "hasenfuss"
  end
  specify "should be able to use method_missing in one of its parents" do
    @instance.pferdefuss.should == "PFERDEFUSS"
  end

  specify "should answer respond_to?( 'some method in A' ) with true" do
    @instance.should_respond_to :a
  end
  specify "should answer respond_to?( 'some method in B' ) with true" do
    @instance.should_respond_to :b
  end
  specify "should answer respond_to?( 'some method in Object' ) with true" do
    @instance.should_respond_to :object_id
  end

  specify "should be able to access constants defined in superclasses directly" do
    @instance.access_constant_from_A.should == A::A_CONSTANT
    @instance.access_constant_from_B.should == B::B_CONSTANT
  end
  specify "should be able to use const_missing" do
    @instance.access_constant_from_AB.should == A::A_CONSTANT
  end
  
  specify "should list methods of its superclasses in methods" do
    @instance.methods.should_include "a"
    @instance.methods.should_include "b"
  end

  specify "should be able to use methods from A and B using own instance variables" do
    @instance.init_access
    @instance.inst_minus.should == 2
    @instance.inst_plus.should == 2
  end
end

context "When A and B are subclassed by a class, they" do
  specify "should be informed via 'self.inherited( subclass )'" do
    A.instance_variable_get( :@subclasses ).should == [ AB ]
    B.instance_variable_get( :@subclasses ).should == [ AB ]
  end
end